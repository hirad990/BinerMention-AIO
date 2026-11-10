/* BinerMention Web Push worker. Push delivery is activated after VAPID/server setup. */
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
