importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

// Matches AppConfig.currentEnvironment (prod = to2mor-76e32).
// When switching AppConfig to dev, update this block to to2mor-test web options.
firebase.initializeApp({
  apiKey: 'AIzaSyAglUuwyo_027Kvt20KtXVWANYoUveCXuw',
  appId: '1:951912549415:web:381920becb6b8921e25202',
  messagingSenderId: '951912549415',
  projectId: 'to2mor-76e32',
  authDomain: 'to2mor-76e32.firebaseapp.com',
  storageBucket: 'to2mor-76e32.firebasestorage.app',
});

const messaging = firebase.messaging();

self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('message', (event) => {
  const payload = event.data;
  if (!payload || payload.type !== 'SHOW_NOTIFICATION') return;

  event.waitUntil(
    showBrowserNotification(
      payload.title || 'إشعار جديد',
      payload.body || '',
      payload.data || {},
      { icon: payload.icon, tag: payload.tag },
    ),
  );
});

function showBrowserNotification(title, body, data, options) {
  const payload = data || {};
  const extra = options || {};
  const icon =
    extra.icon || new URL('favicon.png', self.location.href).href;

  return self.registration.showNotification(title, {
    body: body || '',
    icon,
    badge: icon,
    data: payload,
    tag:
      extra.tag ||
      (payload.type || 'restaurant') + '_' +
        (payload.orderId || Date.now()),
    renotify: true,
    requireInteraction: true,
  });
}

messaging.onBackgroundMessage((payload) => {
  const title =
    payload.notification?.title || payload.data?.title || 'إشعار جديد';
  const body = payload.notification?.body || payload.data?.body || '';
  return showBrowserNotification(title, body, payload.data || {});
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  const data = event.notification.data || {};
  const clientsPromise = self.clients.matchAll({
    type: 'window',
    includeUncontrolled: true,
  });

  event.waitUntil(
    clientsPromise.then((windowClients) => {
      for (const client of windowClients) {
        if (client.url.includes(self.location.origin)) {
          client.postMessage({ type: 'NOTIFICATION_CLICK', data });
          return client.focus();
        }
      }

      let url = self.location.origin + self.location.pathname;
      if (data.orderId) {
        const separator = url.includes('?') ? '&' : '?';
        url += separator + 'orderId=' + encodeURIComponent(data.orderId);
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow(url);
      }
    }),
  );
});
