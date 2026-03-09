# Diamonds & IAP System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** RevenueCat entegrasyonu ile consumable mor elmas paketleri (6 tier) ve 2 katmanlı subscription (Plus/Premium) sistemi kurulması — backend webhook, Flutter IAP, yeniden tasarlanmış diamonds ekranı ve upsell tetikleyicileri dahil.

**Architecture:** RevenueCat SDK client-side IAP yönetimi sağlar, webhook ile backend'e bildirim gönderir. Backend receipt doğrulama yapmaz (RevenueCat halleder), sadece webhook event'lerini işler ve DB'yi günceller. Flutter tarafında purchases_flutter paketi, yeni subscription provider ve güncellenmiş UI.

**Tech Stack:** Flutter + Riverpod + purchases_flutter (mobile), Node.js + Express + TypeScript (server), Supabase PostgreSQL (DB), RevenueCat (IAP management)

---

## Task 1: DB Migration — Yeni Tablolar ve Güncellenmiş Seed Data

**Files:**
- Create: `supabase/migrations/006_subscriptions_and_iap_update.sql`

**Step 1: Migration SQL dosyasını yaz**

```sql
-- 006_subscriptions_and_iap_update.sql
-- Subscription takibi
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan TEXT NOT NULL CHECK (plan IN ('plus', 'premium')),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled')),
  rc_customer_id TEXT,
  store_transaction_id TEXT,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_user_subscriptions_user ON user_subscriptions(user_id, status);
CREATE INDEX idx_user_subscriptions_expires ON user_subscriptions(expires_at) WHERE status = 'active';

-- IAP transaction logları
CREATE TABLE iap_transactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL,
  store TEXT NOT NULL CHECK (store IN ('apple', 'google')),
  transaction_id TEXT UNIQUE,
  rc_event_type TEXT,
  amount_usd DECIMAL(10,2),
  purple_credited INT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_iap_transactions_user ON iap_transactions(user_id, created_at DESC);

-- Users tablosuna subscription alanları ekle
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_plan TEXT DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS subscription_expires_at TIMESTAMPTZ DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS rc_customer_id TEXT DEFAULT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_swipes_used INT NOT NULL DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_swipes_reset_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE users ADD COLUMN IF NOT EXISTS daily_undos_used INT NOT NULL DEFAULT 0;

-- RLS disable (service_role kullanıyoruz)
ALTER TABLE user_subscriptions DISABLE ROW LEVEL SECURITY;
ALTER TABLE iap_transactions DISABLE ROW LEVEL SECURITY;

-- iap_products tablosunu güncelle (yeni tier'lar)
DELETE FROM iap_products;
INSERT INTO iap_products (store_id_ios, store_id_android, purple_amount, tier, is_active) VALUES
  ('qulo_purple_50', 'qulo_purple_50', 50, 1, true),
  ('qulo_purple_150', 'qulo_purple_150', 150, 2, true),
  ('qulo_purple_400', 'qulo_purple_400', 400, 3, true),
  ('qulo_purple_1000', 'qulo_purple_1000', 1000, 4, true),
  ('qulo_purple_2500', 'qulo_purple_2500', 2500, 5, true),
  ('qulo_purple_6000', 'qulo_purple_6000', 6000, 6, true);
```

**Step 2: Kullanıcıya migration'ı Supabase SQL Editor'da çalıştırmasını söyle**

Run: Kullanıcı Supabase Dashboard → SQL Editor'da çalıştıracak

**Step 3: Commit**

```bash
git add supabase/migrations/006_subscriptions_and_iap_update.sql
git commit -m "feat: add subscription and IAP update migration (006)"
```

---

## Task 2: Backend — Subscription Tipleri ve Sabitler

**Files:**
- Modify: `server/src/types/index.ts`

**Step 1: Subscription tiplerini ve sabitlerini ekle**

`server/src/types/index.ts` dosyasının sonuna ekle:

```typescript
// Subscription Plans
export type SubscriptionPlan = 'plus' | 'premium';
export type SubscriptionStatus = 'active' | 'expired' | 'cancelled';

export interface SubscriptionInfo {
  plan: SubscriptionPlan | null;
  status: SubscriptionStatus | null;
  expiresAt: string | null;
  isActive: boolean;
}

// Subscription limits
export const SUBSCRIPTION_LIMITS = {
  free: {
    dailySwipes: 20,
    dailyUndos: 0,
    monthlyPurpleBonus: 0,
    weeklyBoosts: 0,
    canSeeWhoViewed: false,
    hasAds: true,
  },
  plus: {
    dailySwipes: 50,
    dailyUndos: 3,
    monthlyPurpleBonus: 100,
    weeklyBoosts: 1,
    canSeeWhoViewed: false,
    hasAds: false,
  },
  premium: {
    dailySwipes: Infinity,
    dailyUndos: Infinity,
    monthlyPurpleBonus: 300,
    weeklyBoosts: 7, // daily = 7/week
    canSeeWhoViewed: true,
    hasAds: false,
  },
} as const;

// RevenueCat webhook event types
export type RCEventType =
  | 'INITIAL_PURCHASE'
  | 'RENEWAL'
  | 'CANCELLATION'
  | 'UNCANCELLATION'
  | 'EXPIRATION'
  | 'BILLING_ISSUE'
  | 'PRODUCT_CHANGE'
  | 'NON_RENEWING_PURCHASE'; // consumable

// IAP Product mapping (store_id → purple amount)
export const IAP_PRODUCT_MAP: Record<string, number> = {
  qulo_purple_50: 50,
  qulo_purple_150: 150,
  qulo_purple_400: 400,
  qulo_purple_1000: 1000,
  qulo_purple_2500: 2500,
  qulo_purple_6000: 6000,
};

// Subscription product IDs
export const SUBSCRIPTION_PRODUCT_MAP: Record<string, SubscriptionPlan> = {
  qulo_plus_monthly: 'plus',
  qulo_premium_monthly: 'premium',
};
```

**Step 2: Error kodlarını güncelle**

`server/src/utils/errors.ts` dosyasına yeni error'lar ekle:

```typescript
INVALID_WEBHOOK_AUTH: () => new AppError('INVALID_WEBHOOK_AUTH', 401),
SUBSCRIPTION_NOT_FOUND: () => new AppError('SUBSCRIPTION_NOT_FOUND', 404),
DUPLICATE_TRANSACTION: () => new AppError('DUPLICATE_TRANSACTION', 409),
```

**Step 3: Commit**

```bash
git add server/src/types/index.ts server/src/utils/errors.ts
git commit -m "feat: add subscription types, limits, and IAP constants"
```

---

## Task 3: Backend — Subscription Service

**Files:**
- Create: `server/src/services/subscription.service.ts`

**Step 1: Subscription service'i yaz**

```typescript
import { supabase } from '../config/supabase.js';
import { diamondService } from './diamond.service.js';
import {
  SubscriptionPlan,
  SubscriptionStatus,
  SubscriptionInfo,
  SUBSCRIPTION_LIMITS,
} from '../types/index.js';
import { Errors } from '../utils/errors.js';

class SubscriptionService {
  async getStatus(userId: string): Promise<SubscriptionInfo> {
    // Check user's subscription_plan and expiry from users table
    const { data: user, error } = await supabase
      .from('users')
      .select('subscription_plan, subscription_expires_at')
      .eq('id', userId)
      .single();

    if (error || !user) {
      return { plan: null, status: null, expiresAt: null, isActive: false };
    }

    const plan = user.subscription_plan as SubscriptionPlan | null;
    const expiresAt = user.subscription_expires_at;

    if (!plan || !expiresAt) {
      return { plan: null, status: null, expiresAt: null, isActive: false };
    }

    const isActive = new Date(expiresAt) > new Date();
    return {
      plan,
      status: isActive ? 'active' : 'expired',
      expiresAt,
      isActive,
    };
  }

  async activateSubscription(
    userId: string,
    plan: SubscriptionPlan,
    rcCustomerId: string,
    storeTransactionId: string,
    expiresAt: string
  ): Promise<void> {
    // Insert subscription record
    await supabase.from('user_subscriptions').insert({
      user_id: userId,
      plan,
      status: 'active',
      rc_customer_id: rcCustomerId,
      store_transaction_id: storeTransactionId,
      started_at: new Date().toISOString(),
      expires_at: expiresAt,
    });

    // Update user record
    await supabase
      .from('users')
      .update({
        subscription_plan: plan,
        subscription_expires_at: expiresAt,
        rc_customer_id: rcCustomerId,
      })
      .eq('id', userId);

    // Credit monthly purple diamond bonus
    const bonus = SUBSCRIPTION_LIMITS[plan].monthlyPurpleBonus;
    if (bonus > 0) {
      await diamondService.addPurple(
        userId,
        bonus,
        'SUBSCRIPTION_BONUS',
        storeTransactionId
      );
    }
  }

  async renewSubscription(
    userId: string,
    storeTransactionId: string,
    expiresAt: string
  ): Promise<void> {
    // Get current plan
    const { data: user } = await supabase
      .from('users')
      .select('subscription_plan')
      .eq('id', userId)
      .single();

    const plan = (user?.subscription_plan as SubscriptionPlan) || 'plus';

    // Update latest subscription record
    await supabase
      .from('user_subscriptions')
      .update({
        status: 'active',
        expires_at: expiresAt,
        store_transaction_id: storeTransactionId,
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId)
      .eq('status', 'active');

    // Update user expiry
    await supabase
      .from('users')
      .update({ subscription_expires_at: expiresAt })
      .eq('id', userId);

    // Credit monthly bonus again
    const bonus = SUBSCRIPTION_LIMITS[plan].monthlyPurpleBonus;
    if (bonus > 0) {
      await diamondService.addPurple(
        userId,
        bonus,
        'SUBSCRIPTION_BONUS',
        storeTransactionId
      );
    }
  }

  async cancelSubscription(userId: string): Promise<void> {
    await supabase
      .from('user_subscriptions')
      .update({
        status: 'cancelled',
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId)
      .eq('status', 'active');

    // Don't remove plan immediately — let it expire naturally
  }

  async expireSubscription(userId: string): Promise<void> {
    await supabase
      .from('user_subscriptions')
      .update({
        status: 'expired',
        updated_at: new Date().toISOString(),
      })
      .eq('user_id', userId)
      .eq('status', 'active');

    // Remove plan from user
    await supabase
      .from('users')
      .update({
        subscription_plan: null,
        subscription_expires_at: null,
      })
      .eq('id', userId);
  }

  async changeSubscription(
    userId: string,
    newPlan: SubscriptionPlan,
    storeTransactionId: string,
    expiresAt: string
  ): Promise<void> {
    // Expire old subscription
    await this.expireSubscription(userId);
    // Activate new one
    const { data: user } = await supabase
      .from('users')
      .select('rc_customer_id')
      .eq('id', userId)
      .single();

    await this.activateSubscription(
      userId,
      newPlan,
      user?.rc_customer_id || '',
      storeTransactionId,
      expiresAt
    );
  }

  getLimits(plan: SubscriptionPlan | null) {
    return SUBSCRIPTION_LIMITS[plan || 'free'];
  }
}

export const subscriptionService = new SubscriptionService();
```

**Step 2: Commit**

```bash
git add server/src/services/subscription.service.ts
git commit -m "feat: add subscription service with activate/renew/cancel/expire"
```

---

## Task 4: Backend — RevenueCat Webhook Handler

**Files:**
- Create: `server/src/services/webhook.service.ts`
- Create: `server/src/routes/webhook.routes.ts`
- Create: `server/src/controllers/webhook.controller.ts`
- Create: `server/src/validators/webhook.validator.ts`
- Modify: `server/src/config/env.ts` (REVENUECAT_WEBHOOK_SECRET)
- Modify: `server/src/index.ts` (mount route)

**Step 1: Env config'e RevenueCat secret ekle**

`server/src/config/env.ts` dosyasına ekle:

```typescript
REVENUECAT_WEBHOOK_SECRET: process.env.REVENUECAT_WEBHOOK_SECRET || '',
```

**Step 2: Webhook validator yaz**

```typescript
// server/src/validators/webhook.validator.ts
import { z } from 'zod';

export const rcWebhookSchema = z.object({
  event: z.object({
    type: z.string(),
    app_user_id: z.string(),
    product_id: z.string(),
    store: z.enum(['APP_STORE', 'PLAY_STORE']).optional(),
    purchased_at_ms: z.number().optional(),
    expiration_at_ms: z.number().optional(),
    transaction_id: z.string().optional(),
    original_transaction_id: z.string().optional(),
  }),
  api_version: z.string().optional(),
});
```

**Step 3: Webhook service yaz**

```typescript
// server/src/services/webhook.service.ts
import { supabase } from '../config/supabase.js';
import { diamondService } from './diamond.service.js';
import { subscriptionService } from './subscription.service.js';
import {
  IAP_PRODUCT_MAP,
  SUBSCRIPTION_PRODUCT_MAP,
  RCEventType,
} from '../types/index.js';

class WebhookService {
  async handleRevenueCatEvent(event: {
    type: string;
    app_user_id: string;
    product_id: string;
    store?: string;
    purchased_at_ms?: number;
    expiration_at_ms?: number;
    transaction_id?: string;
    original_transaction_id?: string;
  }): Promise<void> {
    const {
      type,
      app_user_id: userId,
      product_id: productId,
      store,
      expiration_at_ms,
      transaction_id,
    } = event;

    const eventType = type as RCEventType;
    const storeType = store === 'APP_STORE' ? 'apple' : 'google';

    // Consumable purchase
    if (eventType === 'NON_RENEWING_PURCHASE') {
      await this.handleConsumablePurchase(
        userId,
        productId,
        storeType,
        transaction_id || ''
      );
      return;
    }

    // Subscription events
    const plan = SUBSCRIPTION_PRODUCT_MAP[productId];
    if (!plan) return; // Unknown product, ignore

    const expiresAt = expiration_at_ms
      ? new Date(expiration_at_ms).toISOString()
      : new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString();

    switch (eventType) {
      case 'INITIAL_PURCHASE':
        await subscriptionService.activateSubscription(
          userId,
          plan,
          userId, // RC customer ID = app_user_id
          transaction_id || '',
          expiresAt
        );
        break;

      case 'RENEWAL':
        await subscriptionService.renewSubscription(
          userId,
          transaction_id || '',
          expiresAt
        );
        break;

      case 'CANCELLATION':
        await subscriptionService.cancelSubscription(userId);
        break;

      case 'EXPIRATION':
        await subscriptionService.expireSubscription(userId);
        break;

      case 'PRODUCT_CHANGE':
        await subscriptionService.changeSubscription(
          userId,
          plan,
          transaction_id || '',
          expiresAt
        );
        break;

      case 'UNCANCELLATION':
        // Re-activate — treat like renewal
        await subscriptionService.renewSubscription(
          userId,
          transaction_id || '',
          expiresAt
        );
        break;

      default:
        // BILLING_ISSUE etc. — log but don't act
        break;
    }

    // Log IAP transaction
    await this.logIapTransaction(
      userId,
      productId,
      storeType,
      transaction_id || '',
      eventType,
      null, // amount_usd — RevenueCat doesn't always provide
      null // purple_credited — only for consumables
    );
  }

  private async handleConsumablePurchase(
    userId: string,
    productId: string,
    store: string,
    transactionId: string
  ): Promise<void> {
    // Check duplicate
    const { data: existing } = await supabase
      .from('iap_transactions')
      .select('id')
      .eq('transaction_id', transactionId)
      .single();

    if (existing) return; // Duplicate, skip

    const purpleAmount = IAP_PRODUCT_MAP[productId];
    if (!purpleAmount) return; // Unknown product

    // Credit purple diamonds
    await diamondService.addPurple(
      userId,
      purpleAmount,
      'IAP_PURCHASE',
      transactionId
    );

    // Log IAP transaction
    await this.logIapTransaction(
      userId,
      productId,
      store,
      transactionId,
      'NON_RENEWING_PURCHASE',
      null,
      purpleAmount
    );
  }

  private async logIapTransaction(
    userId: string,
    productId: string,
    store: string,
    transactionId: string,
    rcEventType: string,
    amountUsd: number | null,
    purpleCredited: number | null
  ): Promise<void> {
    await supabase.from('iap_transactions').upsert(
      {
        user_id: userId,
        product_id: productId,
        store,
        transaction_id: transactionId || undefined,
        rc_event_type: rcEventType,
        amount_usd: amountUsd,
        purple_credited: purpleCredited,
      },
      { onConflict: 'transaction_id' }
    );
  }
}

export const webhookService = new WebhookService();
```

**Step 4: Webhook controller yaz**

```typescript
// server/src/controllers/webhook.controller.ts
import { Request, Response, NextFunction } from 'express';
import { webhookService } from '../services/webhook.service.js';
import { env } from '../config/env.js';
import { Errors } from '../utils/errors.js';

export const revenueCatWebhookHandler = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    // Verify webhook auth
    const authHeader = req.headers.authorization;
    if (
      env.REVENUECAT_WEBHOOK_SECRET &&
      authHeader !== `Bearer ${env.REVENUECAT_WEBHOOK_SECRET}`
    ) {
      throw Errors.INVALID_WEBHOOK_AUTH();
    }

    const { event } = req.body;
    await webhookService.handleRevenueCatEvent(event);

    res.json({ success: true });
  } catch (error) {
    next(error);
  }
};
```

**Step 5: Webhook routes yaz**

```typescript
// server/src/routes/webhook.routes.ts
import { Router } from 'express';
import { revenueCatWebhookHandler } from '../controllers/webhook.controller.js';
import { validate } from '../middleware/validate.js';
import { rcWebhookSchema } from '../validators/webhook.validator.js';

const router = Router();

// No auth middleware — RevenueCat authenticates via webhook secret
router.post(
  '/revenuecat',
  validate(rcWebhookSchema),
  revenueCatWebhookHandler
);

export default router;
```

**Step 6: index.ts'e webhook route'u ekle**

`server/src/index.ts`'de route mount kısmına ekle:

```typescript
import webhookRoutes from './routes/webhook.routes.js';
// ...
app.use('/api/v1/webhooks', webhookRoutes);
```

**Step 7: Commit**

```bash
git add server/src/services/webhook.service.ts server/src/controllers/webhook.controller.ts server/src/routes/webhook.routes.ts server/src/validators/webhook.validator.ts server/src/config/env.ts server/src/index.ts
git commit -m "feat: add RevenueCat webhook handler with consumable and subscription support"
```

---

## Task 5: Backend — Subscription Routes ve Controller

**Files:**
- Create: `server/src/routes/subscription.routes.ts`
- Create: `server/src/controllers/subscription.controller.ts`
- Modify: `server/src/index.ts` (mount route)

**Step 1: Subscription controller yaz**

```typescript
// server/src/controllers/subscription.controller.ts
import { Request, Response, NextFunction } from 'express';
import { subscriptionService } from '../services/subscription.service.js';

export const getSubscriptionStatusHandler = async (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const status = await subscriptionService.getStatus(req.user!.userId);
    const limits = subscriptionService.getLimits(status.plan);
    res.json({ subscription: status, limits });
  } catch (error) {
    next(error);
  }
};
```

**Step 2: Subscription routes yaz**

```typescript
// server/src/routes/subscription.routes.ts
import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { generalLimiter } from '../middleware/rateLimit.js';
import { getSubscriptionStatusHandler } from '../controllers/subscription.controller.js';

const router = Router();

router.use(authMiddleware, generalLimiter);

router.get('/status', getSubscriptionStatusHandler);

export default router;
```

**Step 3: index.ts'e route ekle**

```typescript
import subscriptionRoutes from './routes/subscription.routes.js';
// ...
app.use('/api/v1/subscriptions', subscriptionRoutes);
```

**Step 4: Commit**

```bash
git add server/src/controllers/subscription.controller.ts server/src/routes/subscription.routes.ts server/src/index.ts
git commit -m "feat: add subscription status endpoint"
```

---

## Task 6: Backend — /me Response'a Subscription Bilgisi Ekle

**Files:**
- Modify: `server/src/services/user.service.ts`

**Step 1: getMe içinde subscription alanlarını select'e ekle**

`user.service.ts`'deki `getMe()` metodunda `.select(...)` kısmına bu alanları ekle:

```typescript
subscription_plan, subscription_expires_at, daily_swipes_used, daily_swipes_reset_at, daily_undos_used
```

**Step 2: Response mapping'e subscription bilgisi ekle**

getMe return objesine ekle:

```typescript
subscriptionPlan: user.subscription_plan || null,
subscriptionExpiresAt: user.subscription_expires_at || null,
dailySwipesUsed: user.daily_swipes_used || 0,
dailyUndosUsed: user.daily_undos_used || 0,
```

**Step 3: Commit**

```bash
git add server/src/services/user.service.ts
git commit -m "feat: add subscription fields to /me response"
```

---

## Task 7: Flutter — purchases_flutter Paketi ve RevenueCat Konfigürasyonu

**Files:**
- Modify: `pubspec.yaml`
- Create: `lib/core/services/revenuecat_service.dart`

**Step 1: pubspec.yaml'a purchases_flutter ekle**

```yaml
dependencies:
  purchases_flutter: ^8.5.0
```

**Step 2: `flutter pub get` çalıştır**

Run: `flutter pub get`

**Step 3: RevenueCat service yaz**

```dart
// lib/core/services/revenuecat_service.dart
import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  static const _appleApiKey = 'appl_XXXX'; // TODO: .env'den al
  static const _googleApiKey = 'goog_XXXX'; // TODO: .env'den al

  static Future<void> init(String userId) async {
    final apiKey = Platform.isIOS ? _appleApiKey : _googleApiKey;

    final config = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(config);
  }

  static Future<Offerings> getOfferings() async {
    return await Purchases.getOfferings();
  }

  static Future<CustomerInfo> purchasePackage(Package package) async {
    return await Purchases.purchasePackage(package);
  }

  static Future<CustomerInfo> restorePurchases() async {
    return await Purchases.restorePurchases();
  }

  static Future<CustomerInfo> getCustomerInfo() async {
    return await Purchases.getCustomerInfo();
  }

  static Future<void> logIn(String userId) async {
    await Purchases.logIn(userId);
  }

  static Future<void> logOut() async {
    await Purchases.logOut();
  }
}
```

**Step 4: Commit**

```bash
git add pubspec.yaml lib/core/services/revenuecat_service.dart
git commit -m "feat: add purchases_flutter and RevenueCat service"
```

---

## Task 8: Flutter — Subscription Model ve Provider

**Files:**
- Create: `lib/data/models/subscription_model.dart`
- Create: `lib/providers/subscription_provider.dart`
- Modify: `lib/core/network/services/diamond_service.dart` (subscription endpoint)
- Modify: `lib/providers/api_provider.dart` (subscription provider registration)

**Step 1: Subscription model yaz**

```dart
// lib/data/models/subscription_model.dart
import 'package:equatable/equatable.dart';

class SubscriptionInfo extends Equatable {
  final String? plan; // 'plus' | 'premium' | null
  final String? status; // 'active' | 'expired' | 'cancelled' | null
  final String? expiresAt;
  final bool isActive;

  const SubscriptionInfo({
    this.plan,
    this.status,
    this.expiresAt,
    this.isActive = false,
  });

  bool get isPlus => isActive && plan == 'plus';
  bool get isPremium => isActive && plan == 'premium';
  bool get isFree => !isActive;
  bool get hasAds => isFree;
  bool get canSeeWhoViewed => isPremium;

  int get dailySwipeLimit => isPremium
      ? 999999
      : isPlus
          ? 50
          : 20;

  int get dailyUndoLimit => isPremium
      ? 999999
      : isPlus
          ? 3
          : 0;

  int get monthlyPurpleBonus => isPremium
      ? 300
      : isPlus
          ? 100
          : 0;

  factory SubscriptionInfo.fromJson(Map<String, dynamic> json) {
    return SubscriptionInfo(
      plan: json['plan'] as String?,
      status: json['status'] as String?,
      expiresAt: json['expiresAt'] as String?,
      isActive: json['isActive'] as bool? ?? false,
    );
  }

  factory SubscriptionInfo.free() => const SubscriptionInfo();

  @override
  List<Object?> get props => [plan, status, expiresAt, isActive];
}

class SubscriptionLimits extends Equatable {
  final int dailySwipes;
  final int dailyUndos;
  final int monthlyPurpleBonus;
  final int weeklyBoosts;
  final bool canSeeWhoViewed;
  final bool hasAds;

  const SubscriptionLimits({
    required this.dailySwipes,
    required this.dailyUndos,
    required this.monthlyPurpleBonus,
    required this.weeklyBoosts,
    required this.canSeeWhoViewed,
    required this.hasAds,
  });

  factory SubscriptionLimits.fromJson(Map<String, dynamic> json) {
    return SubscriptionLimits(
      dailySwipes: json['dailySwipes'] as int? ?? 20,
      dailyUndos: json['dailyUndos'] as int? ?? 0,
      monthlyPurpleBonus: json['monthlyPurpleBonus'] as int? ?? 0,
      weeklyBoosts: json['weeklyBoosts'] as int? ?? 0,
      canSeeWhoViewed: json['canSeeWhoViewed'] as bool? ?? false,
      hasAds: json['hasAds'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        dailySwipes,
        dailyUndos,
        monthlyPurpleBonus,
        weeklyBoosts,
        canSeeWhoViewed,
        hasAds,
      ];
}
```

**Step 2: Subscription service endpoint'ini diamond_service.dart'a ekle**

`lib/core/network/services/diamond_service.dart`'a ekle:

```dart
@GET('/subscriptions/status')
Future<HttpResponse<Map<String, dynamic>>> getSubscriptionStatus();
```

**Step 3: Subscription provider yaz**

```dart
// lib/providers/subscription_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../data/models/subscription_model.dart';
import '../core/services/revenuecat_service.dart';
import 'api_provider.dart';

class SubscriptionNotifier extends AsyncNotifier<SubscriptionInfo> {
  @override
  Future<SubscriptionInfo> build() async {
    return await fetchStatus();
  }

  Future<SubscriptionInfo> fetchStatus() async {
    try {
      final service = ref.read(diamondServiceProvider);
      final response = await service.getSubscriptionStatus();
      final data = response.data;
      final subscription = data['subscription'] as Map<String, dynamic>?;
      if (subscription == null) return SubscriptionInfo.free();
      return SubscriptionInfo.fromJson(subscription);
    } catch (_) {
      return SubscriptionInfo.free();
    }
  }

  Future<bool> purchasePackage(Package package) async {
    try {
      await RevenueCatService.purchasePackage(package);
      // Webhook will handle crediting — just refresh status
      state = AsyncData(await fetchStatus());
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> restorePurchases() async {
    try {
      await RevenueCatService.restorePurchases();
      state = AsyncData(await fetchStatus());
    } catch (_) {
      // Silently fail
    }
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionNotifier, SubscriptionInfo>(
  () => SubscriptionNotifier(),
);
```

**Step 4: Commit**

```bash
git add lib/data/models/subscription_model.dart lib/providers/subscription_provider.dart lib/core/network/services/diamond_service.dart lib/providers/api_provider.dart
git commit -m "feat: add subscription model, provider, and API endpoint"
```

---

## Task 9: Flutter — Diamonds Ekranı Yeniden Tasarım

**Files:**
- Modify: `lib/features/diamonds/screens/diamonds_screen.dart`
- Create: `lib/features/diamonds/widgets/diamond_balance_card.dart`
- Create: `lib/features/diamonds/widgets/subscription_banner.dart`
- Create: `lib/features/diamonds/widgets/purchase_grid.dart`

**Step 1: Diamond balance card widget yaz**

```dart
// lib/features/diamonds/widgets/diamond_balance_card.dart
// Yeşil ve mor elmas bakiyelerini gösteren kart
// DiamondIcon.purple() ve DiamondIcon.green() kullanır
// AppColors ve AppSpacing'den tema değerleri
```

**Step 2: Subscription banner widget yaz**

```dart
// lib/features/diamonds/widgets/subscription_banner.dart
// Subscriber değilse: "Qulo Premium'a geç!" promosyon banner'ı
// Subscriber ise: aktif plan badge (Plus/Premium rozeti)
// "Planları Gör" butonu → subscription karşılaştırma sayfasına yönlendirir
```

**Step 3: Purchase grid widget yaz**

```dart
// lib/features/diamonds/widgets/purchase_grid.dart
// 3x2 grid, 6 consumable paket
// Her paket: miktar, fiyat, DiamondIcon animasyonu
// "Best Value" etiketli paket (tier 3)
// onTap → RevenueCatService.purchasePackage()
```

**Step 4: Diamonds screen'i güncelle**

Mevcut `diamonds_screen.dart`'ı güncelle:
- Bakiye kartı (yeni widget)
- Subscription banner (subscriber değilse)
- Consumable paket grid'i (3x2)
- İşlem geçmişi (son 5, "Tümü" linki)

**Step 5: Commit**

```bash
git add lib/features/diamonds/
git commit -m "feat: redesign diamonds screen with subscription banner and purchase grid"
```

---

## Task 10: Flutter — Subscription Karşılaştırma Sayfası

**Files:**
- Create: `lib/features/diamonds/screens/subscription_comparison_screen.dart`
- Modify: `lib/routing/app_routes.dart` (yeni route)

**Step 1: Karşılaştırma ekranını yaz**

```dart
// lib/features/diamonds/screens/subscription_comparison_screen.dart
// Full-screen modal (rootNavigatorKey ile)
// 3 plan kartı: Free, Plus ($4.99/ay), Premium ($9.99/ay, ÖNERİ badge)
// Her planda özellik listesi (ikon + açıklama)
// "Başla" butonları → RevenueCat purchase flow
// "Satın Almaları Geri Yükle" linki altta
```

**Step 2: Route ekle**

`lib/routing/app_routes.dart`'a ekle:

```dart
GoRoute(
  path: 'subscription',
  name: RouteNames.subscription,
  builder: (context, state) => const SubscriptionComparisonScreen(),
),
```

`RouteNames`'e ekle:

```dart
static const subscription = 'subscription';
```

**Step 3: Commit**

```bash
git add lib/features/diamonds/screens/subscription_comparison_screen.dart lib/routing/app_routes.dart
git commit -m "feat: add subscription comparison screen with plan selection"
```

---

## Task 11: Flutter — i18n Güncellemesi

**Files:**
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: Yeni i18n key'leri ekle**

TR ve EN sözlüklerine ekle:

```dart
// Subscription
'subscription_plans': 'Planını Seç' / 'Choose Your Plan',
'qulo_plus': 'Qulo Plus',
'qulo_premium': 'Qulo Premium',
'recommended': 'ÖNERİLEN' / 'RECOMMENDED',
'monthly_price_plus': '₺149.99/ay' / '$4.99/mo',
'monthly_price_premium': '₺299.99/ay' / '$9.99/mo',
'daily_swipes': 'Günlük swipe' / 'Daily swipes',
'unlimited': 'Sınırsız' / 'Unlimited',
'monthly_diamond_bonus': 'Aylık elmas bonusu' / 'Monthly diamond bonus',
'undo_swipes': 'Geri alma' / 'Undo swipes',
'auto_boost': 'Otomatik boost' / 'Auto boost',
'weekly': 'Haftalık' / 'Weekly',
'daily': 'Günlük' / 'Daily',
'who_viewed': 'Kim baktı' / 'Who viewed',
'no_ads': 'Reklam yok' / 'No ads',
'start_plan': 'Başla' / 'Start',
'restore_purchases': 'Satın Almaları Geri Yükle' / 'Restore Purchases',
'maybe_later': 'Belki sonra' / 'Maybe later',
'current_plan': 'Mevcut Plan' / 'Current Plan',

// Purchase
'best_value': 'En İyi Fiyat' / 'Best Value',
'popular': 'Popüler' / 'Popular',
'purchase_diamonds': 'Elmas Satın Al' / 'Purchase Diamonds',
'upgrade_to_premium': 'Premium\'a Geç!' / 'Upgrade to Premium!',
'see_plans': 'Planları Gör' / 'See Plans',

// Upsell
'diamonds_empty': 'Elmasların bitti!' / 'Out of diamonds!',
'swipe_limit_reached': 'Bugünlük swipe hakkın doldu' / 'Daily swipe limit reached',
'first_match_congrats': 'Tebrikler, ilk eşleşmen!' / 'Congrats on your first match!',
'want_more_matches': 'Daha fazla eşleşme ister misin?' / 'Want more matches?',
'special_offer': 'Özel Teklif' / 'Special Offer',
'limited_time': 'Sınırlı süre' / 'Limited time',
```

**Step 2: Commit**

```bash
git add lib/core/l10n/app_localizations.dart
git commit -m "feat: add subscription and IAP i18n keys (TR + EN)"
```

---

## Task 12: Flutter — Upsell Tetikleyici Sistemi

**Files:**
- Create: `lib/core/services/upsell_service.dart`
- Create: `lib/features/diamonds/widgets/upsell_sheets.dart`

**Step 1: Upsell service yaz**

```dart
// lib/core/services/upsell_service.dart
import 'package:shared_preferences/shared_preferences.dart';

class UpsellService {
  static const _maxUpsellsPerSession = 2;
  static int _sessionUpsellCount = 0;

  // Tetikleyici key'leri
  static const _keyOnboardingShown = 'upsell_onboarding_shown';
  static const _keyFirstMatchShown = 'upsell_first_match_shown';
  static const _keyDay3Shown = 'upsell_day3_shown';
  static const _keyLastDiamondEmpty = 'upsell_last_diamond_empty';
  static const _keyLastBoostNeed = 'upsell_last_boost_need';

  static Future<bool> shouldShowOnboarding() async {
    if (_sessionUpsellCount >= _maxUpsellsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyOnboardingShown) ?? false);
  }

  static Future<void> markOnboardingShown() async {
    _sessionUpsellCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingShown, true);
  }

  static Future<bool> shouldShowDiamondEmpty() async {
    if (_sessionUpsellCount >= _maxUpsellsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_keyLastDiamondEmpty) ?? 0;
    final hoursSince =
        DateTime.now().millisecondsSinceEpoch - lastShown;
    return hoursSince > 24 * 60 * 60 * 1000; // 24 saat cooldown
  }

  static Future<void> markDiamondEmptyShown() async {
    _sessionUpsellCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyLastDiamondEmpty,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<bool> shouldShowFirstMatch() async {
    if (_sessionUpsellCount >= _maxUpsellsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_keyFirstMatchShown) ?? false);
  }

  static Future<void> markFirstMatchShown() async {
    _sessionUpsellCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstMatchShown, true);
  }

  static Future<bool> shouldShowSwipeLimit() async {
    // Oturum başına 1 kez
    return _sessionUpsellCount < _maxUpsellsPerSession;
  }

  static Future<bool> shouldShowDay3Offer(DateTime registeredAt) async {
    if (_sessionUpsellCount >= _maxUpsellsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_keyDay3Shown) ?? false) return false;
    final daysSince = DateTime.now().difference(registeredAt).inDays;
    return daysSince >= 3;
  }

  static Future<void> markDay3Shown() async {
    _sessionUpsellCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDay3Shown, true);
  }

  static Future<bool> shouldShowBoostNeed() async {
    if (_sessionUpsellCount >= _maxUpsellsPerSession) return false;
    final prefs = await SharedPreferences.getInstance();
    final lastShown = prefs.getInt(_keyLastBoostNeed) ?? 0;
    final hoursSince =
        DateTime.now().millisecondsSinceEpoch - lastShown;
    return hoursSince > 12 * 60 * 60 * 1000; // 12 saat cooldown
  }

  static Future<void> markBoostNeedShown() async {
    _sessionUpsellCount++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyLastBoostNeed,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Oturum başında sıfırla
  static void resetSession() {
    _sessionUpsellCount = 0;
  }
}
```

**Step 2: Upsell bottom sheet widget'larını yaz**

```dart
// lib/features/diamonds/widgets/upsell_sheets.dart
// 3 bottom sheet widget:
//
// 1. PremiumUpsellSheet — full sheet, plan karşılaştırma
//    Kullanım: Onboarding sonrası, ilk match
//
// 2. ConsumableUpsellSheet — compact sheet, 6 paket grid
//    Kullanım: Elmas bitti, boost ihtiyacı
//
// 3. SwipeLimitSheet — limit uyarısı
//    Kullanım: Swipe limiti dolduğunda
//
// Hepsi NavigationService.showAppBottomSheet() ile gösterilir
// CustomBottomSheet sealed class kullanılır
```

**Step 3: Tetikleyicileri ilgili ekranlara entegre et**

Dokunulacak dosyalar:
- `lib/features/discover/screens/discover_screen.dart` — swipe limit, onboarding
- `lib/features/matches/screens/matches_screen.dart` — ilk match
- `lib/features/quiz/screens/quiz_screen.dart` — elmas bitti (güç kullanımında)
- `lib/features/profile/screens/profile_screen.dart` — boost ihtiyacı

Her tetikleyicide pattern:
```dart
if (await UpsellService.shouldShowXxx()) {
  ref.read(navigationServiceProvider).showAppBottomSheet(
    CustomBottomSheet(builder: (context) => XxxUpsellSheet()),
  );
  await UpsellService.markXxxShown();
}
```

**Step 4: Commit**

```bash
git add lib/core/services/upsell_service.dart lib/features/diamonds/widgets/upsell_sheets.dart
git commit -m "feat: add upsell trigger system with cooldown management"
```

---

## Task 13: Flutter — RevenueCat Auth Entegrasyonu

**Files:**
- Modify: `lib/providers/auth_provider.dart`

**Step 1: Login sonrası RevenueCat init**

Auth provider'daki login success akışına ekle:

```dart
// Login başarılı olduktan sonra
await RevenueCatService.init(user.id);
await RevenueCatService.logIn(user.id);
```

**Step 2: Logout'ta RevenueCat logout**

```dart
// Logout akışında
await RevenueCatService.logOut();
```

**Step 3: Commit**

```bash
git add lib/providers/auth_provider.dart
git commit -m "feat: integrate RevenueCat with auth flow (login/logout)"
```

---

## Task 14: Final — DiamondProvider'da Purchase Flow Güncelleme

**Files:**
- Modify: `lib/providers/diamond_provider.dart`

**Step 1: Purchase metodunu RevenueCat ile güncelle**

Mevcut `purchase()` metodunu güncelle — artık backend'e direkt istek atmak yerine RevenueCat SDK üzerinden satın alma başlatır, webhook backend'i günceller, client bakiyeyi yeniden fetch eder:

```dart
Future<bool> purchaseConsumable(Package package) async {
  try {
    await RevenueCatService.purchasePackage(package);
    // Webhook will credit diamonds — just refresh balance
    await fetchBalance();
    return true;
  } catch (_) {
    return false;
  }
}
```

**Step 2: Commit**

```bash
git add lib/providers/diamond_provider.dart
git commit -m "feat: update diamond provider with RevenueCat purchase flow"
```

---

## Özet

| Task | Açıklama | Dosya Sayısı |
|---|---|---|
| 1 | DB Migration | 1 create |
| 2 | Backend tipler & sabitler | 2 modify |
| 3 | Subscription service | 1 create |
| 4 | Webhook handler | 5 create, 2 modify |
| 5 | Subscription routes | 2 create, 1 modify |
| 6 | /me response güncelleme | 1 modify |
| 7 | purchases_flutter & RC service | 1 modify, 1 create |
| 8 | Subscription model & provider | 2 create, 2 modify |
| 9 | Diamonds ekranı redesign | 1 modify, 3 create |
| 10 | Subscription karşılaştırma | 1 create, 1 modify |
| 11 | i18n güncelleme | 1 modify |
| 12 | Upsell tetikleyici sistemi | 2 create, ~4 modify |
| 13 | RevenueCat auth entegrasyonu | 1 modify |
| 14 | Diamond provider güncelleme | 1 modify |

**Toplam:** 14 task, ~19 yeni dosya, ~13 modifiye dosya
