// SAKANA Admin PWA Service Worker
const CACHE_NAME = 'sakana-admin-v1';
const RUNTIME_CACHE = 'sakana-runtime-v1';

// 基本的なキャッシュ対象
const STATIC_CACHE_URLS = [
  '/admin/',
  '/admin/index.html',
  '/admin/main.dart.js',
  '/admin/flutter.js',
  '/admin/flutter_bootstrap.js',
  '/admin/manifest.json',
  '/admin/offline.html',
  '/admin/favicon.png',
  '/admin/icons/Icon-192.png',
  '/admin/icons/Icon-512.png',
];

// インストールイベント
self.addEventListener('install', (event) => {
  console.log('[Service Worker] Installing...');
  
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => {
        console.log('[Service Worker] Caching static assets');
        return cache.addAll(STATIC_CACHE_URLS);
      })
      .then(() => {
        console.log('[Service Worker] Skip waiting');
        return self.skipWaiting();
      })
  );
});

// アクティベートイベント
self.addEventListener('activate', (event) => {
  console.log('[Service Worker] Activating...');
  
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((cacheName) => {
            return cacheName !== CACHE_NAME && cacheName !== RUNTIME_CACHE;
          })
          .map((cacheName) => {
            console.log('[Service Worker] Deleting old cache:', cacheName);
            return caches.delete(cacheName);
          })
      );
    }).then(() => {
      console.log('[Service Worker] Claiming clients');
      return self.clients.claim();
    })
  );
});

// フェッチイベント
self.addEventListener('fetch', (event) => {
  const { request } = event;
  const url = new URL(request.url);
  
  // 外部リソースはネットワーク優先
  if (!url.origin.includes(self.location.origin)) {
    event.respondWith(
      fetch(request)
        .catch(() => {
          // 外部リソースが取得できない場合はキャッシュから
          return caches.match(request);
        })
    );
    return;
  }
  
  // APIコールはネットワークのみ（キャッシュしない）
  if (url.pathname.includes('/api/') || url.pathname.includes('firestore')) {
    event.respondWith(fetch(request));
    return;
  }
  
  // 画像・フォントは長期キャッシュ
  if (request.destination === 'image' || request.destination === 'font') {
    event.respondWith(
      caches.open(RUNTIME_CACHE).then((cache) => {
        return cache.match(request).then((response) => {
          if (response) {
            return response;
          }
          
          return fetch(request).then((response) => {
            if (response.status === 200) {
              cache.put(request, response.clone());
            }
            return response;
          });
        });
      })
    );
    return;
  }
  
  // その他のリソースはキャッシュファースト
  event.respondWith(
    caches.match(request)
      .then((response) => {
        if (response) {
          // キャッシュがある場合は返す
          return response;
        }
        
        // キャッシュがない場合はネットワークから取得
        return fetch(request)
          .then((response) => {
            // 成功したレスポンスをキャッシュに追加
            if (response.status === 200) {
              const responseToCache = response.clone();
              caches.open(RUNTIME_CACHE)
                .then((cache) => {
                  cache.put(request, responseToCache);
                });
            }
            return response;
          })
          .catch(() => {
            // オフラインページを返す
            if (request.destination === 'document') {
              return caches.match('/admin/offline.html');
            }
          });
      })
  );
});

// バックグラウンド同期
self.addEventListener('sync', (event) => {
  console.log('[Service Worker] Background sync', event.tag);
  
  if (event.tag === 'sync-data') {
    event.waitUntil(
      // バックグラウンドでデータを同期
      syncData()
    );
  }
});

// プッシュ通知
self.addEventListener('push', (event) => {
  console.log('[Service Worker] Push received');
  
  const options = {
    body: event.data ? event.data.text() : '新しい通知があります',
    icon: '/admin/icons/Icon-192.png',
    badge: '/admin/icons/Icon-72.png',
    vibrate: [100, 50, 100],
    data: {
      dateOfArrival: Date.now(),
      primaryKey: 1
    },
    actions: [
      {
        action: 'explore',
        title: '開く',
      },
      {
        action: 'close',
        title: '閉じる',
      }
    ]
  };
  
  event.waitUntil(
    self.registration.showNotification('SAKANA Admin', options)
  );
});

// 通知クリック
self.addEventListener('notificationclick', (event) => {
  console.log('[Service Worker] Notification click');
  
  event.notification.close();
  
  event.waitUntil(
    clients.openWindow('/admin/')
  );
});

// メッセージ受信
self.addEventListener('message', (event) => {
  console.log('[Service Worker] Message received:', event.data);
  
  if (event.data.type === 'SKIP_WAITING') {
    self.skipWaiting();
  }
  
  if (event.data.type === 'CLEAR_CACHE') {
    event.waitUntil(
      caches.keys().then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            return caches.delete(cacheName);
          })
        );
      })
    );
  }
});

// データ同期関数
async function syncData() {
  try {
    // LocalStorageのデータをFirebaseと同期
    const response = await fetch('/admin/api/sync', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        timestamp: Date.now()
      })
    });
    
    if (response.ok) {
      console.log('[Service Worker] Data synced successfully');
    }
  } catch (error) {
    console.error('[Service Worker] Sync failed:', error);
  }
}