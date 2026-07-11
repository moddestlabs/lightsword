#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <build-web-directory>" >&2
  exit 1
fi

build_dir="$1"

if [[ ! -d "$build_dir" ]]; then
  echo "Build directory not found: $build_dir" >&2
  exit 1
fi

build_dir="$(cd "$build_dir" && pwd)"
service_worker_path="$build_dir/lightsword_service_worker.js"

mapfile -d '' all_files < <(
  cd "$build_dir"
  find . -type f \
    ! -name 'flutter_service_worker.js' \
    ! -name 'lightsword_service_worker.js' \
    ! -name '*.map' \
    -print0 | sort -z
)

version="$({
  cd "$build_dir"
  printf '%s\0' "${all_files[@]}"
  if ((${#all_files[@]} > 0)); then
    printf '%s\0' "${all_files[@]}" | xargs -0 sha256sum
  fi
} | sha256sum | awk '{print $1}')"

precache_urls=("./")

for relative_path in "${all_files[@]}"; do
  relative_path="${relative_path#./}"

  case "$relative_path" in
    assets/assets/data/*)
      continue
      ;;
    assets/packages/bible_core/assets/data/*)
      continue
      ;;
  esac

  precache_urls+=("$relative_path")
done

write_js_array() {
  local array_name="$1"
  shift
  local values=("$@")

  printf 'const %s = [\n' "$array_name"
  local value
  for value in "${values[@]}"; do
    printf "  '%s',\n" "${value//\'/\\\'}"
  done
  printf '];\n\n'
}

{
  cat <<EOF
'use strict';

const CACHE_VERSION = '$version';
const APP_SHELL_CACHE = 'lightsword-app-shell-' + CACHE_VERSION;
const RUNTIME_CACHE = 'lightsword-runtime-' + CACHE_VERSION;
const NAVIGATION_FALLBACKS = ['./', 'index.html'];

EOF
  write_js_array "PRECACHE_URLS" "${precache_urls[@]}"
  cat <<'EOF'
self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(APP_SHELL_CACHE);
      await cache.addAll(PRECACHE_URLS);
      await self.skipWaiting();
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const cacheNames = await caches.keys();
      await Promise.all(
        cacheNames
          .filter((cacheName) => cacheName.startsWith('lightsword-') &&
            cacheName !== APP_SHELL_CACHE &&
            cacheName !== RUNTIME_CACHE)
          .map((cacheName) => caches.delete(cacheName))
      );
      await self.clients.claim();
    })()
  );
});

self.addEventListener('fetch', (event) => {
  if (event.request.method !== 'GET') {
    return;
  }

  const requestUrl = new URL(event.request.url);
  if (requestUrl.origin !== self.location.origin) {
    return;
  }

  if (event.request.mode === 'navigate') {
    event.respondWith(handleNavigationRequest(event.request));
    return;
  }

  event.respondWith(handleStaticRequest(event.request));
});

async function handleNavigationRequest(request) {
  try {
    const networkResponse = await fetch(request);
    const runtimeCache = await caches.open(RUNTIME_CACHE);
    runtimeCache.put(request, networkResponse.clone());
    return networkResponse;
  } catch (error) {
    const runtimeCache = await caches.open(RUNTIME_CACHE);
    const cachedResponse = await runtimeCache.match(request, { ignoreSearch: true });
    if (cachedResponse) {
      return cachedResponse;
    }

    const appShellCache = await caches.open(APP_SHELL_CACHE);
    for (const fallbackUrl of NAVIGATION_FALLBACKS) {
      const fallbackResponse = await appShellCache.match(fallbackUrl);
      if (fallbackResponse) {
        return fallbackResponse;
      }
    }

    throw error;
  }
}

async function handleStaticRequest(request) {
  const appShellCache = await caches.open(APP_SHELL_CACHE);
  const precachedResponse = await appShellCache.match(request, { ignoreSearch: true });
  if (precachedResponse) {
    return precachedResponse;
  }

  const runtimeCache = await caches.open(RUNTIME_CACHE);
  const cachedResponse = await runtimeCache.match(request, { ignoreSearch: true });
  if (cachedResponse) {
    return cachedResponse;
  }

  const networkResponse = await fetch(request);
  if (networkResponse && networkResponse.ok) {
    runtimeCache.put(request, networkResponse.clone());
  }
  return networkResponse;
}
EOF
} > "$service_worker_path"

echo "Generated $service_worker_path"