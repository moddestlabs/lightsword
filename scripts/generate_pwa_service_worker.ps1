param (
    [Parameter(Mandatory=$true)]
    [string]$BuildDir
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BuildDir)) {
    Write-Error "Build directory not found: $BuildDir"
    exit 1
}

$BuildDir = (Resolve-Path $BuildDir).Path
$serviceWorkerPath = Join-Path $BuildDir "lightsword_service_worker.js"

function Get-RelativePaths {
    param (
        [string]$TargetSubdir,
        [string]$Pattern
    )
    $fullPath = Join-Path $BuildDir $TargetSubdir
    if (-not (Test-Path $fullPath)) {
        return @()
    }
    $files = Get-ChildItem -Path $fullPath -Recurse -File -Filter $Pattern | Sort-Object FullName
    $results = @()
    foreach ($file in $files) {
        $rel = $file.FullName.Substring($BuildDir.Length).TrimStart("\", "/").Replace("\", "/")
        $results += $rel
    }
    return $results
}

function Format-JsArray {
    param ([string]$Name, [string[]]$Items)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("const $Name = [")
    foreach ($item in $Items) {
        $escaped = $item.Replace("'", "\'")
        [void]$sb.AppendLine("  '$escaped',")
    }
    [void]$sb.AppendLine("];`n")
    return $sb.ToString()
}

function Write-JsPropArray {
    param ([string]$PropName, [string[]]$Items)
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.AppendLine("  '$PropName': [")
    foreach ($item in $Items) {
        $escaped = $item.Replace("'", "\'")
        [void]$sb.AppendLine("    '$escaped',")
    }
    [void]$sb.AppendLine("  ],")
    return $sb.ToString()
}

$allFiles = Get-ChildItem -Path $BuildDir -Recurse -File | Where-Object {
    $_.Name -ne 'flutter_service_worker.js' -and
    $_.Name -ne 'lightsword_service_worker.js' -and
    $_.Extension -ne '.map'
} | Sort-Object FullName

$sha256 = [System.Security.Cryptography.SHA256]::Create()
$combinedHashes = New-Object System.Text.StringBuilder

foreach ($file in $allFiles) {
    if (-not (Test-Path $file.FullName)) {
        continue
    }
    try {
        $stream = [System.IO.File]::OpenRead($file.FullName)
        $hashBytes = $sha256.ComputeHash($stream)
        $stream.Close()
        $hashStr = [BitConverter]::ToString($hashBytes).Replace("-", "").ToLower()
        [void]$combinedHashes.AppendLine($hashStr)
    } catch {
        # Safely skip temporary files that disappear or are locked
    }
}

$combinedBytes = [System.Text.Encoding]::UTF8.GetBytes($combinedHashes.ToString())
$versionBytes = $sha256.ComputeHash($combinedBytes)
$version = [BitConverter]::ToString($versionBytes).Replace("-", "").ToLower()

$precacheAllowlist = @(
  '.last_build_id',
  'index.html',
  'main.dart.js',
  'flutter.js',
  'flutter_bootstrap.js',
  'manifest.json',
  'pwa.js',
  'version.json',
  'assets/AssetManifest.bin',
  'assets/AssetManifest.bin.json',
  'assets/FontManifest.json',
  'assets/NOTICES',
  'assets/fonts/MaterialIcons-Regular.otf',
  'assets/packages/cupertino_icons/assets/CupertinoIcons.ttf',
  'assets/shaders/ink_sparkle.frag',
  'assets/shaders/stretch_effect.frag',
  'icons/Icon-192.png',
  'icons/Icon-512.png',
  'icons/apple-touch-icon.png',
  'favicon.ico'
)

$precacheUrls = New-Object System.Collections.Generic.List[string]
$precacheUrls.Add("./")

foreach ($relPath in $precacheAllowlist) {
    $full = Join-Path $BuildDir ($relPath.Replace("/", "\"))
    if (Test-Path $full) {
        $precacheUrls.Add($relPath)
    }
}

$rendererAssets = Get-RelativePaths -TargetSubdir "canvaskit" -Pattern "*.js"
$rendererAssets += Get-RelativePaths -TargetSubdir "canvaskit" -Pattern "*.wasm"
foreach ($item in $rendererAssets) { $precacheUrls.Add($item) }

$fontAssets = Get-RelativePaths -TargetSubdir "assets/assets/fonts" -Pattern "*.ttf"
$fontAssets += Get-RelativePaths -TargetSubdir "assets/assets/fonts" -Pattern "*.otf"
foreach ($item in $fontAssets) { $precacheUrls.Add($item) }

$defaultOriginalLanguagePack = Get-RelativePaths -TargetSubdir "assets/packages/bible_core/assets/data/greek" -Pattern "*.json"
$defaultOriginalLanguagePack += Get-RelativePaths -TargetSubdir "assets/packages/bible_core/assets/data/lexicon" -Pattern "*.json"
$defaultOriginalLanguagePack = $defaultOriginalLanguagePack | Sort-Object

$optionalMaculaSyntax = Get-RelativePaths -TargetSubdir "assets/packages/bible_core/assets/data/syntax" -Pattern "*.json" | Sort-Object
$optionalOriginalLanguageOt = Get-RelativePaths -TargetSubdir "assets/packages/bible_core/assets/data/tahot" -Pattern "*.json" | Sort-Object
$optionalTranslationBsb = Get-RelativePaths -TargetSubdir "assets/assets/data/usfm/bsb" -Pattern "*.usfm" | Sort-Object

$jsContent = New-Object System.Text.StringBuilder
[void]$jsContent.AppendLine("'use strict';`n")
[void]$jsContent.AppendLine("const CACHE_VERSION = '$version';")
[void]$jsContent.AppendLine("const APP_SHELL_CACHE = 'lightsword-app-shell-' + CACHE_VERSION;")
[void]$jsContent.AppendLine("const DEFAULT_PACK_CACHE = 'lightsword-default-pack-' + CACHE_VERSION;")
[void]$jsContent.AppendLine("const RUNTIME_CACHE = 'lightsword-runtime-' + CACHE_VERSION;")
[void]$jsContent.AppendLine("const DIAGNOSTICS_CACHE = 'lightsword-diagnostics-' + CACHE_VERSION;")
[void]$jsContent.AppendLine("const DIAGNOSTICS_REQUEST_URL = '__lightsword_sw_diagnostics__';`n")

[void]$jsContent.Append((Format-JsArray -Name "PRECACHE_URLS" -Items $precacheUrls))
[void]$jsContent.Append((Format-JsArray -Name "DEFAULT_PACK_URLS" -Items $defaultOriginalLanguagePack))

[void]$jsContent.AppendLine("const OPTIONAL_PACKS = {")
[void]$jsContent.Append((Write-JsPropArray -PropName "macula-syntax" -Items $optionalMaculaSyntax))
[void]$jsContent.Append((Write-JsPropArray -PropName "original-language-ot" -Items $optionalOriginalLanguageOt))
[void]$jsContent.Append((Write-JsPropArray -PropName "translation-bsb" -Items $optionalTranslationBsb))
[void]$jsContent.AppendLine("};`n")

$workerBody = @'
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
    if (shouldPreferCachedResponse(request, networkResponse)) {
      throw createRedirectMigrationError(request, networkResponse);
    }

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
    if (shouldPreferCachedResponse(request, networkResponse)) {
      throw createRedirectMigrationError(request, networkResponse);
    }

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

function shouldPreferCachedResponse(request, response) {
  if (!response) {
    return false;
  }

  if (response.type === 'opaqueredirect') {
    return true;
  }

  if (!response.redirected || !response.url) {
    return false;
  }

  try {
    const requestUrl = new URL(request.url);
    const responseUrl = new URL(response.url, self.location.origin);
    return requestUrl.origin !== responseUrl.origin;
  } catch (_) {
    return false;
  }
}

function createRedirectMigrationError(request, response) {
  const requestOrigin = safeOriginFromUrl(request.url);
  const responseOrigin = safeOriginFromUrl(response?.url);

  return new Error(
    'redirected_off_origin:' +
      (requestOrigin || 'unknown') +
      '->' +
      (responseOrigin || 'unknown')
  );
}

function safeOriginFromUrl(url) {
  if (!url) {
    return null;
  }

  try {
    return new URL(url, self.location.origin).origin;
  } catch (_) {
    return null;
  }
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
  for (const url of urls) {
    const existingResponse = await cache.match(url, { ignoreSearch: true });
    if (existingResponse) {
      continue;
    }

    const cachedResponse = await caches.match(url, { ignoreSearch: true });
    if (cachedResponse) {
      await cache.put(url, cachedResponse.clone());
      continue;
    }

    const networkResponse = await fetch(url);
    if (!networkResponse || !networkResponse.ok) {
      throw new Error('cache_pack_fetch_failed:' + url);
    }
    await cache.put(url, networkResponse.clone());
  }
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
'@

[void]$jsContent.AppendLine($workerBody)

[System.IO.File]::WriteAllText($serviceWorkerPath, $jsContent.ToString(), [System.Text.Encoding]::UTF8)

Write-Host "Generated $serviceWorkerPath"
