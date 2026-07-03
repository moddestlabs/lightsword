// PWA functionality helpers for Dabar Bible Study App

(function() {
  'use strict';

  let deferredInstallPrompt = null;
  let isStandalone = false;

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
    window.dabarPwa = {
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
      checkTtsSupport: checkTtsSupport
    };

    console.log('✅ PWA initialized:', window.dabarPwa);
    
    // Dispatch custom event for Dart to listen to
    window.dispatchEvent(new CustomEvent('dabar-pwa-ready', { 
      detail: window.dabarPwa 
    }));
  }

  // Listen for install prompt
  window.addEventListener('beforeinstallprompt', (e) => {
    e.preventDefault();
    deferredInstallPrompt = e;
    console.log('📱 Install prompt available');
    
    // Notify Dart
    window.dispatchEvent(new CustomEvent('dabar-install-available'));
  });

  // Listen for app installed
  window.addEventListener('appinstalled', () => {
    console.log('✅ App installed');
    deferredInstallPrompt = null;
    
    // Notify Dart
    window.dispatchEvent(new CustomEvent('dabar-app-installed'));
  });

  // Listen for online/offline changes
  window.addEventListener('online', () => {
    console.log('🌐 Online');
    window.dispatchEvent(new CustomEvent('dabar-online'));
  });

  window.addEventListener('offline', () => {
    console.log('📡 Offline');
    window.dispatchEvent(new CustomEvent('dabar-offline'));
  });

  // Initialize when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializePwa);
  } else {
    initializePwa();
  }

})();
