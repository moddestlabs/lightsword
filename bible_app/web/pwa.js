// PWA functionality helpers for LIGHTSWORD Bible Study App

(function() {
  'use strict';

  let deferredInstallPrompt = null;
  let isStandalone = false;

  function getBootStateSnapshot() {
    try {
      if (window.__lightswordBoot && typeof window.__lightswordBoot.snapshot === 'function') {
        return window.__lightswordBoot.snapshot();
      }
    } catch (_) {}

    try {
      const raw = window.localStorage.getItem('lightsword_boot_state_v1');
      return raw ? JSON.parse(raw) : null;
    } catch (_) {
      return null;
    }
  }

  // Check if running as installed PWA
  function checkStandalone() {
    isStandalone = window.matchMedia('(display-mode: standalone)').matches ||
                   window.navigator.standalone === true ||
                   document.referrer.includes('android-app://');
    return isStandalone;
  }

  // Request persistent storage
  async function requestPersistentStorage() {
    if (navigator.storage && navigator.storage.persist) {
      const isPersisted = await navigator.storage.persisted();
      console.log('🗄️ Storage already persisted:', isPersisted);
      
      if (!isPersisted) {
        const result = await navigator.storage.persist();
        console.log('🗄️ Storage persistence request result:', result);
        return result;
      }
      return true;
    }
    console.log('🗄️ Storage persistence not supported');
    return false;
  }

  // Get storage estimate
  async function getStorageEstimate() {
    if (navigator.storage && navigator.storage.estimate) {
      const estimate = await navigator.storage.estimate();
      const percentUsed = (estimate.usage / estimate.quota * 100).toFixed(2);
      console.log('🗄️ Storage used:', estimate.usage, 'of', estimate.quota, `(${percentUsed}%)`);
      return {
        usage: estimate.usage,
        quota: estimate.quota,
        percentUsed: parseFloat(percentUsed)
      };
    }
    return null;
  }

  // Check if app is installable
  function isInstallable() {
    return deferredInstallPrompt !== null;
  }

  // Show install prompt
  async function showInstallPrompt() {
    if (!deferredInstallPrompt) {
      console.log('📱 Install prompt not available');
      return { accepted: false, reason: 'not_available' };
    }

    deferredInstallPrompt.prompt();
    const { outcome } = await deferredInstallPrompt.userChoice;
    console.log('📱 Install prompt outcome:', outcome);
    
    if (outcome === 'accepted') {
      deferredInstallPrompt = null;
    }
    
    return { accepted: outcome === 'accepted', reason: outcome };
  }

  // Check network status
  function isOnline() {
    return navigator.onLine;
  }

  function getServiceWorkerController() {
    return navigator.serviceWorker && navigator.serviceWorker.controller
      ? navigator.serviceWorker.controller
      : null;
  }

  function waitForServiceWorkerMessage(expectedType) {
    return new Promise((resolve, reject) => {
      const timeoutId = setTimeout(() => {
        navigator.serviceWorker.removeEventListener('message', onMessage);
        reject(new Error(`Timed out waiting for ${expectedType}`));
      }, 15000);

      function onMessage(event) {
        if (!event.data || event.data.type !== expectedType) {
          return;
        }
        clearTimeout(timeoutId);
        navigator.serviceWorker.removeEventListener('message', onMessage);
        resolve(event.data);
      }

      navigator.serviceWorker.addEventListener('message', onMessage);
    });
  }

  async function cacheOfflinePack(packName) {
    const controller = getServiceWorkerController();
    if (!controller) {
      return { ok: false, error: 'service_worker_unavailable', cachedCount: 0 };
    }

    const responsePromise = waitForServiceWorkerMessage('CACHE_PACK_RESULT');
    controller.postMessage({ type: 'CACHE_PACK', pack: packName });
    return responsePromise;
  }

  async function getOfflinePackStatus() {
    const controller = getServiceWorkerController();
    if (!controller) {
      return null;
    }

    const responsePromise = waitForServiceWorkerMessage('PACK_STATUS_RESULT');
    controller.postMessage({ type: 'GET_PACK_STATUS' });
    const response = await responsePromise;
    return response.status;
  }

  async function getPwaDiagnostics() {
    const diagnostics = {
      timestamp: new Date().toISOString(),
      online: navigator.onLine,
      locationHref: window.location.href,
      locationPathname: window.location.pathname,
      referrer: document.referrer,
      userAgent: navigator.userAgent,
      standalone: checkStandalone(),
      displayModeStandalone: window.matchMedia('(display-mode: standalone)').matches,
      iosStandalone: window.navigator.standalone === true,
      baseHref: document.querySelector('base')?.href || null,
      serviceWorkerSupported: 'serviceWorker' in navigator,
      serviceWorkerController: false,
      serviceWorkerControllerScriptUrl: null,
      serviceWorkerRegistrationScope: null,
      serviceWorkerRegistrationActiveScriptUrl: null,
      serviceWorkerRegistrationInstallingScriptUrl: null,
      serviceWorkerRegistrationWaitingScriptUrl: null,
      serviceWorkerRegistrationActiveState: null,
      cacheKeys: [],
      shell: null,
      defaultPack: null,
      optionalPacks: {},
      launchProbes: [],
      bootStatus: null,
      bootLastDetail: null,
      bootLastUpdated: null,
      bootLastFailure: null,
      bootEvents: [],
      errors: []
    };

    const bootState = getBootStateSnapshot();
    if (bootState) {
      diagnostics.bootStatus = bootState.status || null;
      diagnostics.bootLastDetail = bootState.lastDetail || null;
      diagnostics.bootLastUpdated = bootState.lastUpdated || null;
      diagnostics.bootLastFailure = bootState.lastFailure || null;
      diagnostics.bootEvents = Array.isArray(bootState.events)
        ? bootState.events.map((event) => {
            const step = event?.step || 'unknown';
            const detail = event?.detail ? ` (${event.detail})` : '';
            const at = event?.at ? ` @ ${event.at}` : '';
            return `${step}${detail}${at}`;
          })
        : [];
    }

    let registrationScope = null;

    try {
      const controller = getServiceWorkerController();
      diagnostics.serviceWorkerController = !!controller;
      diagnostics.serviceWorkerControllerScriptUrl = controller?.scriptURL || null;
    } catch (error) {
      diagnostics.errors.push(`controller:${String(error)}`);
    }

    try {
      if (navigator.serviceWorker) {
        const registration = await navigator.serviceWorker.getRegistration();
        if (registration) {
          registrationScope = registration.scope || null;
          diagnostics.serviceWorkerRegistrationScope = registration.scope || null;
          diagnostics.serviceWorkerRegistrationActiveScriptUrl = registration.active?.scriptURL || null;
          diagnostics.serviceWorkerRegistrationInstallingScriptUrl = registration.installing?.scriptURL || null;
          diagnostics.serviceWorkerRegistrationWaitingScriptUrl = registration.waiting?.scriptURL || null;
          diagnostics.serviceWorkerRegistrationActiveState = registration.active?.state || null;
        }
      }
    } catch (error) {
      diagnostics.errors.push(`registration:${String(error)}`);
    }

    try {
      diagnostics.cacheKeys = await caches.keys();
    } catch (error) {
      diagnostics.errors.push(`caches:${String(error)}`);
    }

    try {
      const packStatus = await getOfflinePackStatus();
      if (packStatus) {
        diagnostics.shell = packStatus.shell || null;
        diagnostics.defaultPack = packStatus.defaultPack || null;
        for (const [name, status] of Object.entries(packStatus)) {
          if (name === 'shell' || name === 'defaultPack') {
            continue;
          }
          diagnostics.optionalPacks[name] = status;
        }
      }
    } catch (error) {
      diagnostics.errors.push(`packStatus:${String(error)}`);
    }

    try {
      const shellCacheName = diagnostics.cacheKeys.find((key) => key.startsWith('lightsword-app-shell-')) || null;
      diagnostics.launchProbes = await probeLaunchUrls({
        registrationScope,
        shellCacheName,
      });
    } catch (error) {
      diagnostics.errors.push(`launchProbes:${String(error)}`);
    }

    return diagnostics;
  }

  async function probeLaunchUrls({ registrationScope, shellCacheName }) {
    const scopeUrl = new URL(registrationScope || './', window.location.href);
    const scopePath = scopeUrl.pathname;
    const indexUrl = new URL('index.html', scopeUrl);
    const locationUrl = new URL(window.location.href);
    const candidates = [
      locationUrl.href,
      locationUrl.origin + locationUrl.pathname,
      scopeUrl.href,
      scopePath,
      indexUrl.href,
      indexUrl.pathname,
      './',
      'index.html'
    ];

    const uniqueCandidates = [...new Set(candidates)];
    const shellCache = shellCacheName ? await caches.open(shellCacheName) : null;
    const probes = [];

    for (const candidate of uniqueCandidates) {
      const anyCacheMatch = await caches.match(candidate, { ignoreSearch: true });
      const shellCacheMatch = shellCache
        ? await shellCache.match(candidate, { ignoreSearch: true })
        : null;
      probes.push({
        url: candidate,
        anyCache: !!anyCacheMatch,
        shellCache: !!shellCacheMatch,
      });
    }

    return probes;
  }

  // Check TTS support and available languages
  async function checkTtsSupport() {
    if (!('speechSynthesis' in window)) {
      return { supported: false, languages: [] };
    }

    return new Promise((resolve) => {
      const synth = window.speechSynthesis;
      
      // Wait for voices to load
      const getVoices = () => {
        const voices = synth.getVoices();
        const languages = [...new Set(voices.map(v => v.lang))];
        
        // Check for Hebrew and Greek
        const hasHebrew = languages.some(l => l.startsWith('he'));
        const hasGreek = languages.some(l => l.startsWith('el'));
        
        console.log('🔊 TTS Web API - Supported:', true);
        console.log('🔊 TTS Web API - Languages:', languages.length);
        console.log('🔊 TTS Web API - Hebrew:', hasHebrew);
        console.log('🔊 TTS Web API - Greek:', hasGreek);
        
        resolve({
          supported: true,
          languages: languages,
          hasHebrew: hasHebrew,
          hasGreek: hasGreek,
          voiceCount: voices.length
        });
      };

      if (synth.getVoices().length > 0) {
        getVoices();
      } else {
        synth.onvoiceschanged = getVoices;
        // Timeout fallback
        setTimeout(() => {
          if (synth.getVoices().length === 0) {
            resolve({ supported: true, languages: [], hasHebrew: false, hasGreek: false });
          }
        }, 1000);
      }
    });
  }

  // Check if iOS (for special handling)
  function isIOS() {
    return /iPad|iPhone|iPod/.test(navigator.userAgent) && !window.MSStream;
  }

  // Get platform info
  function getPlatformInfo() {
    const isIos = isIOS();
    const isAndroid = /Android/.test(navigator.userAgent);
    const isMobile = /Mobi|Android/i.test(navigator.userAgent);
    
    return {
      ios: isIos,
      android: isAndroid,
      mobile: isMobile,
      standalone: isStandalone,
      installable: isInstallable()
    };
  }

  // Initialize PWA features
  async function initializePwa() {
    console.log('🚀 Initializing PWA features...');
    
    checkStandalone();
    const platform = getPlatformInfo();
    console.log('📱 Platform:', platform);

    // Request persistent storage
    const persisted = await requestPersistentStorage();
    
    // Get storage info
    const storage = await getStorageEstimate();
    
    // Check TTS support
    const tts = await checkTtsSupport();

    // Expose to Dart via window
    window.lightswordPwa = {
      platform: platform,
      storage: {
        persisted: persisted,
        estimate: storage
      },
      tts: tts,
      // Methods callable from Dart
      showInstallPrompt: showInstallPrompt,
      getStorageEstimate: getStorageEstimate,
      isOnline: isOnline,
      checkTtsSupport: checkTtsSupport,
      cacheOfflinePack: cacheOfflinePack,
      getOfflinePackStatus: getOfflinePackStatus,
      getPwaDiagnostics: getPwaDiagnostics
    };

    console.log('✅ PWA initialized:', window.lightswordPwa);
    
    // Dispatch custom event for Dart to listen to
    window.dispatchEvent(new CustomEvent('lightsword-pwa-ready', { 
      detail: window.lightswordPwa 
    }));
  }

  // Listen for install prompt
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredInstallPrompt = e;
    console.log('📱 Install prompt available');
    
    // Notify Dart
    window.dispatchEvent(new CustomEvent('lightsword-install-available'));
  });

  // Listen for app installed
  window.addEventListener('appinstalled', () => {
    console.log('✅ App installed');
    deferredInstallPrompt = null;
    
    // Notify Dart
    window.dispatchEvent(new CustomEvent('lightsword-app-installed'));
  });

  // Listen for online/offline changes
  window.addEventListener('online', () => {
    console.log('🌐 Online');
    window.dispatchEvent(new CustomEvent('lightsword-online'));
  });

  window.addEventListener('offline', () => {
    console.log('📡 Offline');
    window.dispatchEvent(new CustomEvent('lightsword-offline'));
  });

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializePwa);
  } else {
    initializePwa();
  }

})();
