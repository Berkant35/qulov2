# Token Refresh & Startup Auth Validation

## Problem
- AuthInterceptor 1 kez refresh deniyor, başarısız olunca token siliniyor ama AuthState güncellenmiyor
- App açılışında token geçerliliği kontrol edilmiyor (sadece var/yok)
- Concurrent 401'lerde race condition riski

## Tasarım

### 1. AuthInterceptor (3 Retry + Backoff + Completer)

**Retry mantığı:**
- 401 alınca refresh token ile yeni access token al
- Refresh isteği network/500 hatası → backoff ile retry (1sn, 2sn, 3sn)
- Refresh isteği INVALID_TOKEN dönerse → token revoke edilmiş, retry anlamsız → direkt logout
- 3 deneme sonunda başarısız → sessiz logout

**Concurrent request handling:**
- İlk 401 alan istek refresh başlatır, Completer oluşturur
- Aynı anda 401 alan diğer istekler Completer'ı bekler
- Refresh bitince hepsi yeni token ile retry eder

**Force logout:**
- `onForceLogout` callback ile AuthNotifier.forceLogout() çağrılır
- Token'lar silinir, state unauthenticated olur, GoRouter login'e yönlendirir

### 2. Startup Token Validation (Hibrit)

**Splash ekranında sıralı kontrol:**
1. Secure storage'dan token oku (yoksa → unauthenticated)
2. JWT exp decode et (dart:convert ile base64 decode, exp alanını kontrol et)
3. Süresi geçmişse → refresh dene (aynı 3 retry mantığı)
4. Süresi geçmemişse → /users/me çağır
5. /me başarılıysa → authenticated
6. /me 401 dönerse → refresh cycle başlat
7. Her şey başarısızsa → sessiz logout

### 3. Logout Event Propagation

**NetworkManager üzerinden callback injection:**
- NetworkManager.init(onForceLogout: callback)
- AuthInterceptor constructor'ına onForceLogout geçirilir
- main.dart'ta ProviderContainer üzerinden authProvider.notifier.forceLogout bağlanır

### 4. Backend Durumu
- Değişiklik gerekmez
- Refresh token rotation mevcut (her refresh'te eski silinip yeni oluşturuluyor)
- Access token: 15dk, Refresh token: 30 gün
- INVALID_TOKEN vs TOKEN_EXPIRED ayrımı 401 ile dönüyor

### 5. Dokunulacak Dosyalar

| Dosya | Değişiklik |
|---|---|
| `lib/core/network/interceptors/auth_interceptor.dart` | 3 retry + backoff + Completer + onForceLogout |
| `lib/core/network/network_manager.dart` | onForceLogout callback injection |
| `lib/providers/auth_provider.dart` | forceLogout() + hibrit _checkAuth |
| `lib/features/splash/splash_screen.dart` | Validation tamamlanana kadar bekleme |
| `lib/main.dart` | NetworkManager init'e forceLogout callback bağlama |
