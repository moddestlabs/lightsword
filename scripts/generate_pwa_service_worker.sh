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

precache_allowlist=(
  '.last_build_id'
  'index.html'
  'main.dart.js'
  'flutter.js'
  'flutter_bootstrap.js'
  'manifest.json'
  'pwa.js'
  'version.json'
  'assets/AssetManifest.bin'
  'assets/AssetManifest.bin.json'
  'assets/FontManifest.json'
  'assets/NOTICES'
  'assets/fonts/MaterialIcons-Regular.otf'
  'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf'
  'assets/shaders/ink_sparkle.frag'
  'assets/shaders/stretch_effect.frag'
  'icons/Icon-192.png'
  'icons/Icon-512.png'
  'icons/apple-touch-icon.png'
  'favicon.ico'
)

collect_paths() {
  local target_dir="$1"
  local pattern="$2"

  if [[ ! -d "$build_dir/$target_dir" ]]; then
    return
  fi

  (
    cd "$build_dir"
    find "$target_dir" -type f -name "$pattern" | LC_ALL=C sort
  )
}

mapfile -t default_original_language_pack < <(
  {
    collect_paths 'assets/packages/bible_core/assets/data/greek' '*.json'
    collect_paths 'assets/packages/bible_core/assets/data/lexicon' '*.json'
  } | awk 'NF'
)

mapfile -t renderer_runtime_assets < <(
  {
    collect_paths 'canvaskit' '*.js'
    collect_paths 'canvaskit' '*.wasm'
  } | awk 'NF'
)

mapfile -t bundled_font_assets < <(
  {
    collect_paths 'assets/assets/fonts' '*.ttf'
    collect_paths 'assets/assets/fonts' '*.otf'
  } | awk 'NF'
)

mapfile -t optional_original_language_ot_pack < <(
  collect_paths 'assets/packages/bible_core/assets/data/tahot' '*.json' | awk 'NF'
)

mapfile -t optional_translation_bsb_pack < <(
  collect_paths 'assets/assets/data/usfm/bsb' '*.usfm' | awk 'NF'
)

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

for relative_path in "${precache_allowlist[@]}"; do
  if [[ -f "$build_dir/$relative_path" ]]; then
    precache_urls+=("$relative_path")
  fi
done

for relative_path in "${renderer_runtime_assets[@]}"; do
  precache_urls+=("$relative_path")
done

for relative_path in "${bundled_font_assets[@]}"; do
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

write_js_object_of_arrays() {
  local object_name="$1"
  shift

  printf 'const %s = {\n' "$object_name"
  while (($# > 0)); do
    local property_name="$1"
    shift
    local value_count="$1"
    shift
    printf "  '%s': [\n" "$property_name"
    local index=0
    while ((index < value_count)); do
      local value="$1"
      shift
      printf "    '%s',\n" "${value//\'/\\\'}"
      index=$((index + 1))
    done
    printf '  ],\n'
  done
  printf '};\n\n'
}

append_array_args() {
  local array_name="$1"
  local property_name="$2"
  local -n values_ref="$array_name"

  object_args+=("$property_name" "${#values_ref[@]}")
  local value
  for value in "${values_ref[@]}"; do
    object_args+=("$value")
  done
}

{
  cat <<EOF
'use strict';

const CACHE_VERSION = '$version';
const APP_SHELL_CACHE = 'lightsword-app-shell-' + CACHE_VERSION;
const DEFAULT_PACK_CACHE = 'lightsword-default-pack-' + CACHE_VERSION;
const RUNTIME_CACHE = 'lightsword-runtime-' + CACHE_VERSION;
const DIAGNOSTICS_CACHE = 'lightsword-diagnostics-' + CACHE_VERSION;
const DIAGNOSTICS_REQUEST_URL = '__lightsword_sw_diagnostics__';

EOF
  write_js_array "PRECACHE_URLS" "${precache_urls[@]}"
  write_js_array "DEFAULT_PACK_URLS" "${default_original_language_pack[@]}"
  object_args=()
  append_array_args optional_original_language_ot_pack 'original-language-ot'
  append_array_args optional_translation_bsb_pack 'translation-bsb'
  write_js_object_of_arrays "OPTIONAL_PACKS" "${object_args[@]}"
  cat <<'EOF'
self.addEventListener('install', (event) => {
  event.waitUntil(
    (async () => {
      const shellCache = await caches.open(APP_SHELL_CACHE);
      await shellCache.addAll(PRECACHE_URLS);

      const defaultPackCache = await caches.open(DEFAULT_PACK_CACHE);
      await defaultPackCache.addAll(DEFAULT_PACK_URLS);
      await self.skipWaiting();
    })()
  );
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    (async () => {
      const activeCaches = new Set([
        APP_SHELL_CACHE,
        DEFAULT_PACK_CACHE,
        RUNTIME_CACHE,
        DIAGNOSTICS_CACHE,
        ...Object.keys(OPTIONAL_PACKS).map(getOptionalPackCacheName),
      ]);
      const cacheNames = await caches.keys();
      await Promise.all(
        cacheNames
          .filter((cacheName) => cacheName.startsWith('lightsword-') && !activeCaches.has(cacheName))
          .map((cacheName) => caches.delete(cacheName))
      );
      await self.clients.claim();
    })()
  );
});

self.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.type === 'CACHE_PACK') {
    event.waitUntil(cacheOptionalPack(data.pack).then((result) => {
      event.source?.postMessage({
        type: 'CACHE_PACK_RESULT',
        pack: data.pack,
        ok: result.ok,
        cachedCount: result.cachedCount,
        error: result.error,
      });
    }));
    return;
  }

  if (data.type === 'GET_PACK_STATUS') {
    event.waitUntil(getPackStatus().then((status) => {
      event.source?.postMessage({
        type: 'PACK_STATUS_RESULT',
        status,
      });
    }));
    return;
  }

  if (data.type === 'GET_SW_DIAGNOSTICS') {
    event.waitUntil(getServiceWorkerDiagnostics().then((diagnostics) => {
      event.source?.postMessage({
        type: 'SW_DIAGNOSTICS_RESULT',
        diagnostics,
      });
    }));
  }
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
    await runtimeCache.put(request, networkResponse.clone());
    return networkResponse;
  } catch (error) {
    const runtimeCache = await caches.open(RUNTIME_CACHE);
    const cachedResponse = await runtimeCache.match(request, { ignoreSearch: true });
    if (cachedResponse) {
      return cachedResponse;
    }

    const appShellCache = await caches.open(APP_SHELL_CACHE);
    for (const fallbackUrl of getNavigationFallbackUrls(request)) {
      const fallbackResponse = await appShellCache.match(fallbackUrl);
      if (fallbackResponse) {
        await recordDiagnosticEvent({
          kind: 'navigation-fallback',
          url: request.url,
          fallbackUrl,
        });
        return fallbackResponse;
      }
    }

    await recordDiagnosticEvent({
      kind: 'navigation-failure',
      url: request.url,
      error: stringifyError(error),
    });
    throw error;
  }
}

async function handleStaticRequest(request) {
  const precachedResponse = await matchPrecachedRequest(request);
  if (precachedResponse) {
    await maybeRecordStaticCacheHit(request, 'precache');
    return precachedResponse;
  }

  const runtimeCache = await caches.open(RUNTIME_CACHE);
  const cachedResponse = await runtimeCache.match(request, { ignoreSearch: true });
  if (cachedResponse) {
    await maybeRecordStaticCacheHit(request, 'runtime');
    return cachedResponse;
  }

  try {
    const networkResponse = await fetch(request);
    if (networkResponse && networkResponse.ok) {
      await runtimeCache.put(request, networkResponse.clone());
    }
    return networkResponse;
  } catch (error) {
    await recordDiagnosticEvent({
      kind: 'static-failure',
      url: request.url,
      destination: request.destination || 'unknown',
      mode: request.mode || 'unknown',
      error: stringifyError(error),
    });
    throw error;
  }
}

function getNavigationFallbackUrls(request) {
  const scopeUrl = new URL('./', self.registration.scope);
  const indexUrl = new URL('index.html', scopeUrl);
  const requestUrl = new URL(request.url);

  const fallbackUrls = [
    scopeUrl.href,
    indexUrl.href,
    scopeUrl.pathname,
    indexUrl.pathname,
    './',
    'index.html',
  ];

  if (!requestUrl.pathname.endsWith('/')) {
    fallbackUrls.push(requestUrl.pathname + '/');
  }

  return [...new Set(fallbackUrls)];
}

async function matchPrecachedRequest(request) {
  const appShellCache = await caches.open(APP_SHELL_CACHE);
  const shellResponse = await appShellCache.match(request, { ignoreSearch: true });
  if (shellResponse) {
    return shellResponse;
  }

  const defaultPackCache = await caches.open(DEFAULT_PACK_CACHE);
  const defaultPackResponse = await defaultPackCache.match(request, { ignoreSearch: true });
  if (defaultPackResponse) {
    return defaultPackResponse;
  }

  for (const packName of Object.keys(OPTIONAL_PACKS)) {
    const packCache = await caches.open(getOptionalPackCacheName(packName));
    const packResponse = await packCache.match(request, { ignoreSearch: true });
    if (packResponse) {
      return packResponse;
    }
  }

  return null;
}

function getOptionalPackCacheName(packName) {
  return 'lightsword-pack-' + packName + '-' + CACHE_VERSION;
}

async function cacheOptionalPack(packName) {
  if (!Object.prototype.hasOwnProperty.call(OPTIONAL_PACKS, packName)) {
    return { ok: false, cachedCount: 0, error: 'unknown_pack' };
  }

  const urls = OPTIONAL_PACKS[packName];
  const cache = await caches.open(getOptionalPackCacheName(packName));
  await cache.addAll(urls);
  return { ok: true, cachedCount: urls.length, error: null };
}

async function getPackStatus() {
  const results = {};

  results.shell = {
    cacheName: APP_SHELL_CACHE,
    total: PRECACHE_URLS.length,
    cached: await countCachedEntries(APP_SHELL_CACHE, PRECACHE_URLS),
  };
  results.defaultPack = {
    cacheName: DEFAULT_PACK_CACHE,
    total: DEFAULT_PACK_URLS.length,
    cached: await countCachedEntries(DEFAULT_PACK_CACHE, DEFAULT_PACK_URLS),
  };

  for (const [packName, urls] of Object.entries(OPTIONAL_PACKS)) {
    const cacheName = getOptionalPackCacheName(packName);
    results[packName] = {
      cacheName,
      total: urls.length,
      cached: await countCachedEntries(cacheName, urls),
    };
  }

  return results;
}

async function countCachedEntries(cacheName, urls) {
  const cache = await caches.open(cacheName);
  let cached = 0;
  for (const url of urls) {
    if (await cache.match(url, { ignoreSearch: true })) {
      cached += 1;
    }
  }
  return cached;
}

async function getServiceWorkerDiagnostics() {
  const diagnostics = await readDiagnosticsState();
  return {
    currentSessionId: diagnostics.currentSessionId,
    lastUpdated: diagnostics.lastUpdated,
    events: diagnostics.events,
  };
}

async function recordDiagnosticEvent(event) {
  const diagnostics = await readDiagnosticsState();
  diagnostics.currentSessionId = CACHE_VERSION;
  diagnostics.lastUpdated = new Date().toISOString();
  diagnostics.events.push({
    at: diagnostics.lastUpdated,
    ...event,
  });
  if (diagnostics.events.length > 20) {
    diagnostics.events = diagnostics.events.slice(-20);
  }
  await writeDiagnosticsState(diagnostics);
}

async function readDiagnosticsState() {
  const cache = await caches.open(DIAGNOSTICS_CACHE);
  const response = await cache.match(DIAGNOSTICS_REQUEST_URL, { ignoreSearch: true });
  if (!response) {
    return {
      currentSessionId: CACHE_VERSION,
      lastUpdated: null,
      events: [],
    };
  }

  try {
    return await response.json();
  } catch (_) {
    return {
      currentSessionId: CACHE_VERSION,
      lastUpdated: null,
      events: [],
    };
  }
}

async function writeDiagnosticsState(diagnostics) {
  const cache = await caches.open(DIAGNOSTICS_CACHE);
  await cache.put(
    DIAGNOSTICS_REQUEST_URL,
    new Response(JSON.stringify(diagnostics), {
      headers: {
        'content-type': 'application/json',
      },
    }),
  );
}

function stringifyError(error) {
  if (error == null) {
    return 'unknown_error';
  }
  if (typeof error === 'string') {
    return error;
  }
  if (typeof error.message === 'string') {
    return error.message;
  }
  return String(error);
}

async function maybeRecordStaticCacheHit(request, source) {
  if (!shouldTraceAssetRequest(request)) {
    return;
  }

  await recordDiagnosticEvent({
    kind: 'static-cache-hit',
    url: request.url,
    destination: request.destination || 'unknown',
    mode: request.mode || 'unknown',
    source,
  });
}

function shouldTraceAssetRequest(request) {
  const url = request.url || '';
  return (
    url.includes('/canvaskit/') ||
    url.endsWith('.js') ||
    url.endsWith('.wasm')
  );
}
EOF
} > "$service_worker_path"

echo "Generated $service_worker_path"