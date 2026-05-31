// Firebase Cloud Messaging service worker for SOS Arena web.
// Keep the Firebase JS version pinned for reproducibility.
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.13.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCHhr-TaJkiDUAh0LZ2g_7Y4XlBn093CyM',
  appId: '1:151581458337:web:a17050730b7c820f25d5e0',
  messagingSenderId: '151581458337',
  projectId: 'soso-2c8df',
  authDomain: 'soso-2c8df.firebaseapp.com',
  storageBucket: 'soso-2c8df.firebasestorage.app',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const notif = payload.notification || {};
  self.registration.showNotification(notif.title || 'SOS Arena', {
    body: notif.body || '',
    icon: '/icons/Icon-192.png',
    data: payload.data || {},
  });
});
