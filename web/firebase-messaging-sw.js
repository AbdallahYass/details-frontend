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
  console.log('📬 [Background Message Received]: ', payload);

  const notificationTitle = payload.notification?.title || 'إشعار جديد من ديتيلز';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png', // أيقونة التطبيق (مهمة جداً لبعض المتصفحات)
    badge: '/icons/Icon-192.png',
    dir: 'rtl'
  };
  
  // إضافة return هنا ضرورية جداً لإبقاء الملف يعمل حتى يظهر الإشعار!
  return self.registration.showNotification(notificationTitle, notificationOptions);
});

// حدث ذكي: ماذا يحدث عندما يضغط المستخدم على الإشعار في هاتفه؟
self.addEventListener('notificationclick', function(event) {
  event.notification.close(); // إخفاء الإشعار بعد الضغط عليه
  
  event.waitUntil(
    clients.matchAll({ type: 'window', includeUncontrolled: true }).then(function(clientList) {
      // إذا كان الموقع مفتوحاً في الخلفية، قم بالانتقال إليه
      if (clientList.length > 0) {
        return clientList[0].focus();
      }
      // إذا كان الموقع مغلقاً بالكامل، قم بفتحه
      return clients.openWindow('/');
    })
  );
});