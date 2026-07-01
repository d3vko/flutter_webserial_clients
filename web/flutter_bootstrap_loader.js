// Loaded as an external script so nginx CSP (script-src without 'unsafe-inline')
// does not block Flutter bootstrap. See docker/nginx.conf and web/index.html.
(function () {
  var bootstrapSrc = 'flutter_bootstrap.js';
  var cleanupFlag = 'rfvillage-sw-cleanup-v1';

  function loadFlutterBootstrap() {
    var script = document.createElement('script');
    script.src = bootstrapSrc;
    script.async = true;
    document.body.appendChild(script);
  }

  if (!('serviceWorker' in navigator)) {
    loadFlutterBootstrap();
    return;
  }

  navigator.serviceWorker
    .getRegistrations()
    .then(function (regs) {
      if (!regs.length) {
        loadFlutterBootstrap();
        return;
      }

      var unregisterAll = Promise.all(
        regs.map(function (reg) {
          return reg.unregister();
        }),
      );

      var clearCaches =
        'caches' in window
          ? caches.keys().then(function (keys) {
              return Promise.all(
                keys.map(function (key) {
                  return caches.delete(key);
                }),
              );
            })
          : Promise.resolve();

      return Promise.all([unregisterAll, clearCaches]).then(function () {
        if (!sessionStorage.getItem(cleanupFlag)) {
          sessionStorage.setItem(cleanupFlag, '1');
          window.location.reload();
          return;
        }
        loadFlutterBootstrap();
      });
    })
    .catch(function () {
      loadFlutterBootstrap();
    });
})();
