{{flutter_js}}
{{flutter_build_config}}

const serviceWorkerVersion = {{flutter_service_worker_version}};

function markBoot(step, detail) {
  try {
    window.__lightswordBoot?.mark(step, detail);
  } catch (_) {}
}

(async function startLightsword() {
  markBoot('bootstrap-script-loaded', 'Flutter bootstrap script loaded.');

  try {
    await _flutter.loader.load({
      serviceWorkerSettings: {
        serviceWorkerVersion,
        serviceWorkerUrl: `lightsword_service_worker.js?v=${serviceWorkerVersion}`
      },
      onEntrypointLoaded: async (engineInitializer) => {
        markBoot('entrypoint-loaded', 'Flutter entrypoint loaded. Initializing engine.');

        try {
          const appRunner = await engineInitializer.initializeEngine();
          markBoot('engine-initialized', 'Flutter engine initialized. Starting app.');
          await appRunner.runApp();
          window.__lightswordBoot?.complete();
        } catch (error) {
          const message = error == null ? 'Unknown engine startup error' : String(error);
          markBoot('boot-failed', message);
          window.__lightswordBoot?.fail(message);
          throw error;
        }
      }
    });
  } catch (error) {
    const message = error == null ? 'Unknown Flutter loader error' : String(error);
    markBoot('boot-failed', message);
    window.__lightswordBoot?.fail(message);
  }
})();