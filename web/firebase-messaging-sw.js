// Firebase Cloud Messaging service worker (web push).
//
// Browsers deliver background pushes only through a service worker served
// from the site root under exactly this name. The SDK version must match the
// one bundled by firebase_core_web (supportedFirebaseJsSdkVersion); the config
// is the public web config of the project, the same as
// DefaultFirebaseOptions.web — none of it is secret.
importScripts('https://www.gstatic.com/firebasejs/12.18.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/12.18.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyAHXChbD1xYXawt3EG8QNWZjVoM65xyW-4',
  appId: '1:930281380072:web:25189f1d00440ad479115d',
  messagingSenderId: '930281380072',
  projectId: 'eventhub-d411f',
  authDomain: 'eventhub-d411f.firebaseapp.com',
  storageBucket: 'eventhub-d411f.firebasestorage.app',
});

const messaging = firebase.messaging();

// Messages sent by the Cloud Functions carry a `notification` block, which
// the SDK displays by itself in background. This handler only covers
// data-only messages, so they are not silently dropped.
messaging.onBackgroundMessage((payload) => {
  if (payload.notification) return;
  const data = payload.data || {};
  self.registration.showNotification(data.title || 'EventHub', {
    body: data.body || '',
    icon: '/icons/Icon-192.png',
    data,
  });
});

// A click focuses an open EventHub tab (or opens one). Deep links are handled
// by the app itself once it is in the foreground.
self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then((tabs) => {
      for (const tab of tabs) {
        if ('focus' in tab) return tab.focus();
      }
      return clients.openWindow('/');
    }),
  );
});
