/* Firebase Cloud Messaging service worker (optional — for web push later) */
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.14.1/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyCaW-HxHtgiTFIptimX4_aDnjuXlcmq7nE',
  appId: '1:348288099305:web:85d1f72909225944afa178',
  messagingSenderId: '348288099305',
  projectId: 'medreminder-ee920',
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  const title = payload.notification?.title || 'MedReminder';
  const options = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
  };
  self.registration.showNotification(title, options);
});
