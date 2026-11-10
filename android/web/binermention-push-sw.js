const CACHE_NAME = 'binerm-shell-v1';
const APP_ROOT = '/mention/';

self.addEventListener('install', (event) => {
  event.waitUntil((async () => {
    const cache = await caches.open(CACHE_NAME);
    try { await cache.add(new Request(APP_ROOT, { cache: 'reload' })); } catch (_) {}
    await self.skipWaiting();
  })());
});

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter((key) => key.startsWith('binerm-shell-') && key !== CACHE_NAME).map((key) => caches.delete(key)));
    await self.clients.claim();
  })());
});

self.addEventListener('fetch', (event) => {
  const request = event.request;
  if (request.method !== 'GET') return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin || !url.pathname.startsWith(APP_ROOT)) return;
  event.respondWith((async () => {
    const cache = await caches.open(CACHE_NAME);
    if (request.mode === 'navigate') {
      try {
        const response = await fetch(request);
        if (response && response.ok) await cache.put(APP_ROOT, response.clone());
        return response;
      } catch (_) {
        return (await cache.match(request)) || (await cache.match(APP_ROOT)) || Response.error();
      }
    }
    const cached = await cache.match(request);
    if (cached) return cached;
    try {
      const response = await fetch(request);
      if (response && response.ok && response.type === 'basic') await cache.put(request, response.clone());
      return response;
    } catch (_) {
      return cached || Response.error();
    }
  })());
});

/* Push delivery is intentionally dormant until a non-Firebase push sender is configured. */
self.addEventListener('push', (event) => {
  let payload = {};
  try { payload = event.data ? event.data.json() : {}; }
  catch (_) { payload = { title: 'BinerMention', body: event.data ? event.data.text() : '' }; }
  const title = payload.title || 'BinerMention';
  const options = {
    body: payload.body || 'You have a new notification.',
    icon: '/mention/icons/icon-192.png',
    badge: '/mention/icons/icon-192.png',
    tag: payload.tag || 'binerm-notification',
    renotify: Boolean(payload.renotify),
    data: { url: payload.url || '/mention/' }
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const target = new URL(event.notification.data?.url || '/mention/', self.location.origin).href;
  event.waitUntil((async () => {
    const clientsList = await self.clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const client of clientsList) {
      if (client.url.startsWith(self.location.origin) && 'focus' in client) {
        await client.focus();
        client.postMessage({ type: 'BINER_NOTIFICATION_CLICK', url: target });
        return;
      }
    }
    if (self.clients.openWindow) await self.clients.openWindow(target);
  })());
});
