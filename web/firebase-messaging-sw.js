importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

// إعدادات فايربيس الخاصة بموقع ديتيلز
firebase.initializeApp({
  apiKey: "AIzaSyAUMaUSPPNfVTKudn58zM0WMs5dG4umx0c",
  authDomain: "details-store-3be7c.firebaseapp.com",
  projectId: "details-store-3be7c",
  storageBucket: "details-store-3be7c.firebasestorage.app",
  messagingSenderId: "131777577750",
  appId: "1:131777577750:web:c9ce46e86de97152cfc637",
  measurementId: "G-V5XQCFK678"
});

const messaging = firebase.messaging();

// استقبال الإشعارات عندما يكون الموقع مغلقاً أو في الخلفية
messaging.onBackgroundMessage(function(payload) {
  const notificationTitle = payload.notification.title;
  const notificationOptions = {
    body: payload.notification.body,
  };
  self.registration.showNotification(notificationTitle, notificationOptions);
});