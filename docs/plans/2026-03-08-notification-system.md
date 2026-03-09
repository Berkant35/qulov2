# Notification System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Push notification altyapısını tamamla, bildirim merkezi (inbox) ekle, backoffice kampanya yönetimi + segment bazlı hedefli bildirim gönderimi sağla.

**Architecture:** Backend'de mevcut NotificationService genişletilir — her bildirim `notifications` tablosuna yazılır + FCM push gönderilir. CampaignService yeni eklenir — segment builder ile hedef kitle belirlenir, batch gönderim yapılır, analitik izlenir. Flutter'da NotificationManager singleton olarak FCM lifecycle'ı yönetir, NotificationNotifier inbox state'ini tutar, bildirim merkezinde liste + in-app banner gösterilir.

**Tech Stack:** Express + TypeScript (backend), Supabase PostgreSQL (DB), Firebase Cloud Messaging (push), Flutter + Riverpod (mobile), EJS (admin panel)

---

## Phase 1: Database & Migration

### Task 1: Notification & Campaign Tabloları

**Files:**
- Create: `supabase/migrations/009_notifications_and_campaigns.sql`

**Step 1: Migration SQL'i yaz**

```sql
-- ============================================================
-- 009_notifications_and_campaigns.sql
-- Notification inbox + Campaign management
-- ============================================================

-- ─── ENUMS ───
CREATE TYPE campaign_status AS ENUM ('draft', 'scheduled', 'sending', 'sent', 'cancelled');
CREATE TYPE campaign_event_type AS ENUM ('sent', 'delivered', 'opened', 'clicked');

-- ─── notifications ───
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  campaign_id UUID,
  type TEXT NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  image_url TEXT,
  action_url TEXT,
  action_label TEXT,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_notifications_user_read ON notifications(user_id, is_read);
CREATE INDEX idx_notifications_created_at ON notifications(created_at DESC);

-- ─── campaigns ───
CREATE TABLE campaigns (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  title TEXT NOT NULL,
  push_title TEXT NOT NULL,
  push_body TEXT NOT NULL,
  image_url TEXT,
  action_url TEXT,
  action_label TEXT,
  segment JSONB NOT NULL DEFAULT '{}',
  status campaign_status NOT NULL DEFAULT 'draft',
  scheduled_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  created_by UUID NOT NULL REFERENCES admin_users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- FK for notifications → campaigns (deferred because campaigns created after notifications)
ALTER TABLE notifications ADD CONSTRAINT fk_notifications_campaign
  FOREIGN KEY (campaign_id) REFERENCES campaigns(id) ON DELETE SET NULL;

-- ─── campaign_stats ───
CREATE TABLE campaign_stats (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id UUID NOT NULL UNIQUE REFERENCES campaigns(id) ON DELETE CASCADE,
  total_targeted INTEGER NOT NULL DEFAULT 0,
  total_sent INTEGER NOT NULL DEFAULT 0,
  total_delivered INTEGER NOT NULL DEFAULT 0,
  total_opened INTEGER NOT NULL DEFAULT 0,
  total_clicked INTEGER NOT NULL DEFAULT 0
);

-- ─── campaign_events ───
CREATE TABLE campaign_events (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  campaign_id UUID NOT NULL REFERENCES campaigns(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  event campaign_event_type NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_campaign_events_campaign ON campaign_events(campaign_id);
CREATE INDEX idx_campaign_events_user ON campaign_events(user_id);

-- ─── RLS disabled (service_role) ───
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_stats ENABLE ROW LEVEL SECURITY;
ALTER TABLE campaign_events ENABLE ROW LEVEL SECURITY;
```

**Step 2: Kullanıcı Supabase SQL Editor'da çalıştırır**

**Step 3: Commit**
```bash
git add supabase/migrations/009_notifications_and_campaigns.sql
git commit -m "feat: add notifications and campaigns tables (migration 009)"
```

---

## Phase 2: Backend — NotificationService Güncelleme

### Task 2: NotificationService'e DB Yazma Ekle

**Files:**
- Modify: `server/src/services/notification.service.ts`

**Step 1: PushType'ı genişlet, notifications tablosuna yazma ekle**

Mevcut `sendPush` metodunu güncelle — her bildirimde önce `notifications` tablosuna INSERT yap, sonra FCM gönder. `notification_id` ve `action_url`'i FCM data'ya ekle.

```typescript
// Tip tanımını genişlet
type PushType = 'new_message' | 'new_message_image' | 'new_match' | 'quiz_started' | 'passport_expired' | 'campaign';

// action_url mapping (system bildirimleri için)
const ACTION_URL_MAP: Partial<Record<PushType, string>> = {
  new_match: '/matches',
  quiz_started: '/discover',
  passport_expired: '/profile/passport',
};

// sendPush imzasını genişlet
static async sendPush(
  userId: string,
  type: PushType,
  params: Record<string, string> = {},
  data?: Record<string, string>,
  options?: {
    title?: string;
    imageUrl?: string;
    actionUrl?: string;
    actionLabel?: string;
    campaignId?: string;
  },
): Promise<void> {
  try {
    const { data: user, error } = await supabase
      .from('users')
      .select('push_token, locale')
      .eq('id', userId)
      .single();

    if (error || !user) return;

    const locale = user.locale && locales[user.locale] ? user.locale : 'en';
    const template = locales[locale]?.push?.[type];
    if (!template && !options?.title) return;

    const body = template ? interpolate(template, params) : '';
    const pushTitle = options?.title ?? 'Qulo';
    const pushBody = body;
    const actionUrl = options?.actionUrl ?? ACTION_URL_MAP[type] ?? null;

    // 1. notifications tablosuna yaz
    const { data: notification } = await supabase
      .from('notifications')
      .insert({
        user_id: userId,
        campaign_id: options?.campaignId ?? null,
        type,
        title: pushTitle,
        body: pushBody,
        image_url: options?.imageUrl ?? null,
        action_url: actionUrl,
        action_label: options?.actionLabel ?? null,
      })
      .select('id')
      .single();

    // 2. FCM push gönder
    if (!user.push_token) return;
    const fcm = getFcm();
    if (!fcm) return;

    await fcm.send({
      token: user.push_token,
      notification: { title: pushTitle, body: pushBody },
      data: {
        type,
        notification_id: notification?.id ?? '',
        action_url: actionUrl ?? '',
        ...data,
      },
    });
  } catch (err) {
    console.error(`[NotificationService] Failed (type=${type}, user=${userId}):`, err);
  }
}
```

**Step 2: Mevcut çağrıları güncelle**

`chat.service.ts`'te `new_message` için `action_url` ekle:
```typescript
// data payload'a matchId ekle
NotificationService.sendPush(otherUserId, pushType, { name: senderName }, {}, {
  actionUrl: `/matches/chat/${matchId}`,
}).catch(() => {});
```

`quiz.service.ts`'te de benzer şekilde güncelle.

**Step 3: Test et**
```bash
cd server && npm test
```

**Step 4: Commit**
```bash
git add server/src/services/notification.service.ts server/src/services/chat.service.ts server/src/services/quiz.service.ts
git commit -m "feat: persist notifications to DB and add action_url mapping"
```

---

### Task 3: Notification API Endpoints

**Files:**
- Create: `server/src/services/notification-api.service.ts`
- Create: `server/src/controllers/notification.controller.ts`
- Create: `server/src/routes/notification.routes.ts`
- Modify: `server/src/index.ts` (route register)

**Step 1: Service oluştur**

```typescript
// server/src/services/notification-api.service.ts
import { supabase } from '../config/supabase.js';

class NotificationApiService {
  async getNotifications(userId: string, page: number, limit: number) {
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    const { data, count, error } = await supabase
      .from('notifications')
      .select('*', { count: 'exact' })
      .eq('user_id', userId)
      .order('created_at', { ascending: false })
      .range(from, to);

    if (error) throw error;
    return { notifications: data ?? [], total: count ?? 0 };
  }

  async getUnreadCount(userId: string): Promise<number> {
    const { count, error } = await supabase
      .from('notifications')
      .select('*', { count: 'exact', head: true })
      .eq('user_id', userId)
      .eq('is_read', false);

    if (error) throw error;
    return count ?? 0;
  }

  async markAsRead(userId: string, notificationId: string) {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('id', notificationId)
      .eq('user_id', userId);

    if (error) throw error;
  }

  async markAllAsRead(userId: string) {
    const { error } = await supabase
      .from('notifications')
      .update({ is_read: true })
      .eq('user_id', userId)
      .eq('is_read', false);

    if (error) throw error;
  }

  async trackClick(userId: string, notificationId: string) {
    // notification'ın campaign_id'sini bul
    const { data: notif } = await supabase
      .from('notifications')
      .select('campaign_id')
      .eq('id', notificationId)
      .eq('user_id', userId)
      .single();

    if (!notif?.campaign_id) return;

    // campaign_events'e click ekle
    await supabase.from('campaign_events').insert({
      campaign_id: notif.campaign_id,
      user_id: userId,
      event: 'clicked',
    });

    // campaign_stats güncelle
    await supabase.rpc('increment_campaign_stat', {
      p_campaign_id: notif.campaign_id,
      p_field: 'total_clicked',
    });
  }
}

export const notificationApiService = new NotificationApiService();
```

**Step 2: RPC fonksiyonu için migration ekle (009'a ekle veya ayrı)**

Bu RPC fonksiyonunu 009 migration'a ekle:
```sql
-- Atomic increment for campaign stats
CREATE OR REPLACE FUNCTION increment_campaign_stat(p_campaign_id UUID, p_field TEXT)
RETURNS void AS $$
BEGIN
  EXECUTE format(
    'UPDATE campaign_stats SET %I = %I + 1 WHERE campaign_id = $1',
    p_field, p_field
  ) USING p_campaign_id;
END;
$$ LANGUAGE plpgsql;
```

**Step 3: Controller oluştur**

```typescript
// server/src/controllers/notification.controller.ts
import type { Request, Response, NextFunction } from 'express';
import { notificationApiService } from '../services/notification-api.service.js';

export async function getNotificationsHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const page = parseInt(req.query.page as string) || 1;
    const limit = parseInt(req.query.limit as string) || 20;
    const result = await notificationApiService.getNotifications(req.user!.userId, page, limit);
    res.json(result);
  } catch (err) { next(err); }
}

export async function getUnreadCountHandler(req: Request, res: Response, next: NextFunction) {
  try {
    const count = await notificationApiService.getUnreadCount(req.user!.userId);
    res.json({ count });
  } catch (err) { next(err); }
}

export async function markAsReadHandler(req: Request, res: Response, next: NextFunction) {
  try {
    await notificationApiService.markAsRead(req.user!.userId, req.params.id);
    res.json({ success: true });
  } catch (err) { next(err); }
}

export async function markAllAsReadHandler(req: Request, res: Response, next: NextFunction) {
  try {
    await notificationApiService.markAllAsRead(req.user!.userId);
    res.json({ success: true });
  } catch (err) { next(err); }
}

export async function trackClickHandler(req: Request, res: Response, next: NextFunction) {
  try {
    await notificationApiService.trackClick(req.user!.userId, req.params.id);
    res.json({ success: true });
  } catch (err) { next(err); }
}
```

**Step 4: Route oluştur**

```typescript
// server/src/routes/notification.routes.ts
import { Router } from 'express';
import { authMiddleware } from '../middleware/auth.js';
import { generalLimiter } from '../middleware/rateLimit.js';
import {
  getNotificationsHandler,
  getUnreadCountHandler,
  markAsReadHandler,
  markAllAsReadHandler,
  trackClickHandler,
} from '../controllers/notification.controller.js';

const router = Router();
router.use(authMiddleware, generalLimiter);

router.get('/', getNotificationsHandler);
router.get('/unread-count', getUnreadCountHandler);
router.patch('/:id/read', markAsReadHandler);
router.post('/read-all', markAllAsReadHandler);
router.post('/:id/click', trackClickHandler);

export default router;
```

**Step 5: index.ts'e route ekle**

```typescript
import notificationRoutes from './routes/notification.routes.js';
// ...
app.use('/api/v1/notifications', notificationRoutes);
```

**Step 6: Commit**
```bash
git add server/src/services/notification-api.service.ts server/src/controllers/notification.controller.ts server/src/routes/notification.routes.ts server/src/index.ts
git commit -m "feat: add notification inbox API endpoints"
```

---

## Phase 3: Backend — Campaign Service

### Task 4: Segment Builder + Campaign Service

**Files:**
- Create: `server/src/services/campaign.service.ts`
- Create: `server/src/validators/campaign.validator.ts`

**Step 1: Validator oluştur**

```typescript
// server/src/validators/campaign.validator.ts
import { z } from 'zod';

export const segmentSchema = z.object({
  gender: z.enum(['MAN', 'WOMAN']).optional(),
  age_min: z.number().int().min(18).max(99).optional(),
  age_max: z.number().int().min(18).max(99).optional(),
  cities: z.array(z.string()).optional(),
  subscription_plan: z.string().optional(),
  last_active_days: z.number().int().min(1).optional(),
  profile_completion_min: z.number().int().min(0).max(100).optional(),
  profile_completion_max: z.number().int().min(0).max(100).optional(),
  has_match: z.boolean().optional(),
  registered_after: z.string().optional(),
});

export type SegmentInput = z.infer<typeof segmentSchema>;

export const createCampaignSchema = z.object({
  title: z.string().min(1).max(200),
  push_title: z.string().min(1).max(100),
  push_body: z.string().min(1).max(500),
  image_url: z.string().url().optional(),
  action_url: z.string().max(200).optional(),
  action_label: z.string().max(50).optional(),
  segment: segmentSchema,
  scheduled_at: z.string().optional(),
});

export type CreateCampaignInput = z.infer<typeof createCampaignSchema>;
```

**Step 2: Service oluştur**

```typescript
// server/src/services/campaign.service.ts
import { supabase } from '../config/supabase.js';
import { NotificationService } from './notification.service.js';
import type { SegmentInput, CreateCampaignInput } from '../validators/campaign.validator.js';

class CampaignService {
  // ─── Segment → SQL Query Builder ───
  private buildSegmentQuery(segment: SegmentInput) {
    let query = supabase
      .from('users')
      .select('id, push_token', { count: 'exact' })
      .eq('is_deleted', false);

    if (segment.gender) query = query.eq('gender', segment.gender);
    if (segment.age_min) query = query.gte('age', segment.age_min);
    if (segment.age_max) query = query.lte('age', segment.age_max);
    if (segment.cities?.length) query = query.in('city', segment.cities);
    if (segment.subscription_plan) query = query.eq('subscription_plan', segment.subscription_plan);
    if (segment.last_active_days) {
      const since = new Date(Date.now() - segment.last_active_days * 86400000).toISOString();
      query = query.gte('last_seen_at', since);
    }
    if (segment.profile_completion_min !== undefined) {
      query = query.gte('profile_completion', segment.profile_completion_min);
    }
    if (segment.profile_completion_max !== undefined) {
      query = query.lte('profile_completion', segment.profile_completion_max);
    }
    if (segment.has_match !== undefined) {
      // has_match kontrolü ayrı query gerektirir, basit tutuyoruz
    }
    if (segment.registered_after) {
      query = query.gte('created_at', segment.registered_after);
    }

    return query;
  }

  async previewSegmentCount(segment: SegmentInput): Promise<number> {
    const { count } = await this.buildSegmentQuery(segment);
    return count ?? 0;
  }

  async createCampaign(data: CreateCampaignInput, adminId: string) {
    const { data: campaign, error } = await supabase
      .from('campaigns')
      .insert({
        title: data.title,
        push_title: data.push_title,
        push_body: data.push_body,
        image_url: data.image_url ?? null,
        action_url: data.action_url ?? null,
        action_label: data.action_label ?? null,
        segment: data.segment,
        status: data.scheduled_at ? 'scheduled' : 'draft',
        scheduled_at: data.scheduled_at ?? null,
        created_by: adminId,
      })
      .select()
      .single();

    if (error) throw error;

    // Stats kaydı oluştur
    await supabase.from('campaign_stats').insert({ campaign_id: campaign.id });

    return campaign;
  }

  async sendCampaign(campaignId: string) {
    // Campaign'ı al
    const { data: campaign } = await supabase
      .from('campaigns')
      .select('*')
      .eq('id', campaignId)
      .single();

    if (!campaign || campaign.status === 'sent' || campaign.status === 'cancelled') {
      throw new Error('Campaign cannot be sent');
    }

    // Status → sending
    await supabase.from('campaigns').update({ status: 'sending' }).eq('id', campaignId);

    // Hedef kullanıcıları al
    const segment = campaign.segment as SegmentInput;
    const { data: users, count } = await this.buildSegmentQuery(segment);

    // Stats güncelle
    await supabase
      .from('campaign_stats')
      .update({ total_targeted: count ?? 0 })
      .eq('campaign_id', campaignId);

    // Batch gönderim (500'er)
    const BATCH_SIZE = 500;
    const allUsers = users ?? [];
    let totalSent = 0;
    let totalDelivered = 0;

    for (let i = 0; i < allUsers.length; i += BATCH_SIZE) {
      const batch = allUsers.slice(i, i + BATCH_SIZE);

      const results = await Promise.allSettled(
        batch.map(async (user) => {
          try {
            await NotificationService.sendPush(
              user.id,
              'campaign',
              {},
              {},
              {
                title: campaign.push_title,
                imageUrl: campaign.image_url,
                actionUrl: campaign.action_url,
                actionLabel: campaign.action_label,
                campaignId: campaignId,
              },
            );

            // Event log
            await supabase.from('campaign_events').insert({
              campaign_id: campaignId,
              user_id: user.id,
              event: user.push_token ? 'delivered' : 'sent',
            });

            return user.push_token ? 'delivered' : 'sent';
          } catch {
            return 'sent';
          }
        }),
      );

      for (const r of results) {
        if (r.status === 'fulfilled') {
          totalSent++;
          if (r.value === 'delivered') totalDelivered++;
        }
      }
    }

    // Final stats güncelle
    await supabase
      .from('campaign_stats')
      .update({ total_sent: totalSent, total_delivered: totalDelivered })
      .eq('campaign_id', campaignId);

    // Status → sent
    await supabase
      .from('campaigns')
      .update({ status: 'sent', sent_at: new Date().toISOString() })
      .eq('id', campaignId);

    return { totalSent, totalDelivered };
  }

  async cancelCampaign(campaignId: string) {
    await supabase
      .from('campaigns')
      .update({ status: 'cancelled' })
      .eq('id', campaignId)
      .in('status', ['draft', 'scheduled']);
  }

  async getCampaigns(page: number, limit: number) {
    const from = (page - 1) * limit;
    const to = from + limit - 1;

    const { data, count } = await supabase
      .from('campaigns')
      .select('*, campaign_stats(*)', { count: 'exact' })
      .order('created_at', { ascending: false })
      .range(from, to);

    return { campaigns: data ?? [], total: count ?? 0 };
  }

  async getCampaignDetail(campaignId: string) {
    const { data: campaign } = await supabase
      .from('campaigns')
      .select('*, campaign_stats(*)')
      .eq('id', campaignId)
      .single();

    return campaign;
  }

  async getCampaignBreakdown(campaignId: string) {
    // Cinsiyet bazlı breakdown
    const { data: genderBreakdown } = await supabase
      .from('campaign_events')
      .select('event, users!inner(gender)')
      .eq('campaign_id', campaignId);

    // Gün bazlı trend
    const { data: dailyTrend } = await supabase
      .from('campaign_events')
      .select('event, created_at')
      .eq('campaign_id', campaignId)
      .order('created_at', { ascending: true });

    return { genderBreakdown: genderBreakdown ?? [], dailyTrend: dailyTrend ?? [] };
  }
}

export const campaignService = new CampaignService();
```

**Step 3: Commit**
```bash
git add server/src/services/campaign.service.ts server/src/validators/campaign.validator.ts
git commit -m "feat: add campaign service with segment builder and batch sending"
```

---

### Task 5: Admin Campaign Routes + Views

**Files:**
- Modify: `server/src/admin/admin.routes.ts`
- Modify: `server/src/admin/admin.controller.ts`
- Modify: `server/src/admin/admin.service.ts`
- Create: `server/src/admin/views/campaigns.ejs`
- Create: `server/src/admin/views/campaign-new.ejs`
- Create: `server/src/admin/views/campaign-detail.ejs`

**Step 1: Admin routes'a campaign endpoint'leri ekle**

`admin.routes.ts`'e (protected section sonuna):
```typescript
router.get("/campaigns", (req, res) => adminController.campaigns(req, res));
router.get("/campaigns/new", (req, res) => adminController.campaignNew(req, res));
router.post("/campaigns", csrfValidate, (req, res) => adminController.campaignCreate(req, res));
router.get("/campaigns/:id", (req, res) => adminController.campaignDetail(req, res));
router.post("/campaigns/:id/send", csrfValidate, (req, res) => adminController.campaignSend(req, res));
router.post("/campaigns/:id/cancel", csrfValidate, (req, res) => adminController.campaignCancel(req, res));
router.post("/campaigns/preview-count", csrfValidate, (req, res) => adminController.campaignPreviewCount(req, res));
```

**Step 2: Controller metotlarını ekle**

`admin.controller.ts`'e campaign metotları:
```typescript
async campaigns(req: Request, res: Response) {
  const page = parseInt(req.query.page as string) || 1;
  const { campaigns, total } = await campaignService.getCampaigns(page, 20);
  const totalPages = Math.ceil(total / 20);
  res.render("campaigns", { campaigns, page, totalPages, total, session: req.session });
}

async campaignNew(req: Request, res: Response) {
  res.render("campaign-new", { session: req.session, csrfToken: req.session.csrfToken });
}

async campaignCreate(req: Request, res: Response) {
  const data = req.body;
  const segment = {
    gender: data.segment_gender || undefined,
    age_min: data.segment_age_min ? parseInt(data.segment_age_min) : undefined,
    age_max: data.segment_age_max ? parseInt(data.segment_age_max) : undefined,
    cities: data.segment_cities ? data.segment_cities.split(',').map((c: string) => c.trim()) : undefined,
    subscription_plan: data.segment_subscription || undefined,
    last_active_days: data.segment_last_active ? parseInt(data.segment_last_active) : undefined,
    profile_completion_min: data.segment_completion_min ? parseInt(data.segment_completion_min) : undefined,
    profile_completion_max: data.segment_completion_max ? parseInt(data.segment_completion_max) : undefined,
    registered_after: data.segment_registered_after || undefined,
  };

  const campaign = await campaignService.createCampaign({
    title: data.title,
    push_title: data.push_title,
    push_body: data.push_body,
    image_url: data.image_url || undefined,
    action_url: data.action_url || undefined,
    action_label: data.action_label || undefined,
    segment,
    scheduled_at: data.scheduled_at || undefined,
  }, req.session.adminId!);

  res.redirect(`/admin/campaigns/${campaign.id}`);
}

async campaignDetail(req: Request, res: Response) {
  const campaign = await campaignService.getCampaignDetail(req.params.id);
  if (!campaign) return res.status(404).render("error", { message: "Campaign not found", session: req.session });
  const breakdown = await campaignService.getCampaignBreakdown(req.params.id);
  res.render("campaign-detail", { campaign, breakdown, session: req.session, csrfToken: req.session.csrfToken });
}

async campaignSend(req: Request, res: Response) {
  await campaignService.sendCampaign(req.params.id);
  res.redirect(`/admin/campaigns/${req.params.id}`);
}

async campaignCancel(req: Request, res: Response) {
  await campaignService.cancelCampaign(req.params.id);
  res.redirect(`/admin/campaigns/${req.params.id}`);
}

async campaignPreviewCount(req: Request, res: Response) {
  const segment = req.body;
  const count = await campaignService.previewSegmentCount(segment);
  res.json({ count });
}
```

**Step 3: EJS view'ları oluştur**

`campaigns.ejs` — Kampanya listesi tablosu (başlık, durum badge'i, tarih, hedef/gönderilen/açılan/tıklanan, yeni kampanya butonu)

`campaign-new.ejs` — Form: İçerik alanları (title, push_title, push_body, image_url, action_url, action_label) + Segment builder (gender select, age range inputs, cities textarea, subscription select, last_active input, completion range, registered_after date) + Canlı segment count (AJAX /preview-count) + Gönder/Zamanla butonları

`campaign-detail.ejs` — İçerik önizleme kartı + Stats kartları (4'lü: hedef, gönderilen, açılan %, tıklanan %) + Gönder/İptal butonları (status'e göre) + Breakdown tablosu (cinsiyet) + Günlük trend (basit tablo)

**Step 4: Dashboard nav'a campaigns link ekle**

Tüm admin view'ların nav bölümüne "Campaigns" linki ekle.

**Step 5: Commit**
```bash
git add server/src/admin/
git commit -m "feat: add campaign management to admin panel"
```

---

## Phase 4: Flutter — NotificationManager + Provider

### Task 6: NotificationManager Singleton

**Files:**
- Create: `lib/core/services/notification_manager.dart`

**Step 1: Singleton manager oluştur**

```dart
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  // Background'da gelen bildirimi işle (gerekirse)
}

class NotificationManager {
  NotificationManager._();
  static final NotificationManager instance = NotificationManager._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  String? _token;
  String? get token => _token;

  Future<void> init() async {
    // Background handler kaydet
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);

    // İzin iste (Android 13+ ve iOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Token al
    _token = await _messaging.getToken();

    // Token yenilenme stream'i
    _messaging.onTokenRefresh.listen((newToken) {
      _token = newToken;
      _onTokenRefresh?.call(newToken);
    });
  }

  // Callback'ler — provider tarafından set edilir
  void Function(String token)? _onTokenRefresh;
  void Function(RemoteMessage message)? _onForegroundMessage;
  void Function(RemoteMessage message)? _onMessageOpenedApp;

  void setCallbacks({
    void Function(String token)? onTokenRefresh,
    void Function(RemoteMessage message)? onForegroundMessage,
    void Function(RemoteMessage message)? onMessageOpenedApp,
  }) {
    _onTokenRefresh = onTokenRefresh;
    _onForegroundMessage = onForegroundMessage;
    _onMessageOpenedApp = onMessageOpenedApp;

    // Foreground listener
    FirebaseMessaging.onMessage.listen((message) {
      _onForegroundMessage?.call(message);
    });

    // Tap handler (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _onMessageOpenedApp?.call(message);
    });
  }

  /// Uygulama kapalıyken tıklanan bildirimi al (bir kez)
  Future<RemoteMessage?> getInitialMessage() {
    return _messaging.getInitialMessage();
  }
}
```

**Step 2: Provider'a ekle**

`api_provider.dart`'a:
```dart
import '../core/services/notification_manager.dart';

final notificationManagerProvider = Provider<NotificationManager>(
  (_) => NotificationManager.instance,
);
```

**Step 3: Commit**
```bash
git add lib/core/services/notification_manager.dart lib/providers/api_provider.dart
git commit -m "feat: add NotificationManager singleton for FCM lifecycle"
```

---

### Task 7: Notification Model + Retrofit Service + Repository

**Files:**
- Create: `lib/data/models/notification_model.dart`
- Create: `lib/core/network/services/notification_service.dart`
- Create: `lib/data/repositories/notification_repository.dart`
- Modify: `lib/data/repositories/repositories.dart` (barrel export)
- Modify: `lib/providers/api_provider.dart` (wiring)

**Step 1: Model**

```dart
// lib/data/models/notification_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel {
  final String id;
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'campaign_id')
  final String? campaignId;
  final String type;
  final String title;
  final String body;
  @JsonKey(name: 'image_url')
  final String? imageUrl;
  @JsonKey(name: 'action_url')
  final String? actionUrl;
  @JsonKey(name: 'action_label')
  final String? actionLabel;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'created_at')
  final String createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    this.campaignId,
    required this.type,
    required this.title,
    required this.body,
    this.imageUrl,
    this.actionUrl,
    this.actionLabel,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) => _$NotificationModelFromJson(json);
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}
```

**Step 2: Retrofit service**

```dart
// lib/core/network/services/notification_service.dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import '../../../data/models/notification_model.dart';

part 'notification_service.g.dart';

@RestApi()
abstract class NotificationRetrofitService {
  factory NotificationRetrofitService(Dio dio) = _NotificationRetrofitService;

  @GET('/notifications')
  Future<Map<String, dynamic>> getNotifications(
    @Query('page') int page,
    @Query('limit') int limit,
  );

  @GET('/notifications/unread-count')
  Future<Map<String, dynamic>> getUnreadCount();

  @PATCH('/notifications/{id}/read')
  Future<void> markAsRead(@Path('id') String id);

  @POST('/notifications/read-all')
  Future<void> markAllAsRead();

  @POST('/notifications/{id}/click')
  Future<void> trackClick(@Path('id') String id);
}
```

**Step 3: Repository**

```dart
// lib/data/repositories/notification_repository.dart
import 'package:dio/dio.dart';
import '../../core/network/result.dart';
import '../../core/network/services/notification_service.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final NotificationRetrofitService _service;

  NotificationRepository(this._service);

  Future<Result<List<NotificationModel>>> getNotifications(int page, int limit) async {
    try {
      final response = await _service.getNotifications(page, limit);
      final list = (response['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return Success(list);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<int>> getUnreadCount() async {
    try {
      final response = await _service.getUnreadCount();
      return Success(response['count'] as int);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }

  Future<Result<void>> trackClick(String id) async {
    try {
      await _service.trackClick(id);
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.toAppFailure());
    }
  }
}
```

**Step 4: Provider wiring**

`api_provider.dart`'a:
```dart
final notificationServiceProvider = Provider<NotificationRetrofitService>(
  (ref) => NotificationRetrofitService(ref.read(networkManagerProvider).dio),
);
final notificationRepositoryProvider = Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.read(notificationServiceProvider)),
);
```

**Step 5: Code generation çalıştır**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Step 6: Commit**
```bash
git add lib/data/models/notification_model.dart lib/core/network/services/notification_service.dart lib/data/repositories/notification_repository.dart lib/providers/api_provider.dart lib/data/repositories/repositories.dart
git commit -m "feat: add notification model, service, and repository"
```

---

### Task 8: NotificationNotifier (State Management)

**Files:**
- Create: `lib/providers/notification_provider.dart`
- Modify: `lib/providers/auth_provider.dart` (login sonrası init)
- Modify: `lib/main.dart` (initial message check)

**Step 1: Provider oluştur**

```dart
// lib/providers/notification_provider.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/notification_manager.dart';
import '../data/models/notification_model.dart';
import 'api_provider.dart';
import 'user_provider.dart';

class NotificationState {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() => const NotificationState();

  Future<void> init() async {
    final manager = ref.read(notificationManagerProvider);

    // FCM init
    await manager.init();

    // Token'ı backend'e gönder
    final token = manager.token;
    if (token != null) {
      await ref.read(userProvider.notifier).updatePushToken(token);
    }

    // Callback'leri ayarla
    manager.setCallbacks(
      onTokenRefresh: (newToken) {
        ref.read(userProvider.notifier).updatePushToken(newToken);
      },
      onForegroundMessage: _handleForegroundMessage,
      onMessageOpenedApp: _handleMessageTap,
    );

    // Terminated state'ten açılan bildirimi kontrol et
    final initialMessage = await manager.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageTap(initialMessage);
    }

    // Unread count çek
    await fetchUnreadCount();
  }

  void _handleForegroundMessage(RemoteMessage message) {
    // Unread count artır
    state = state.copyWith(unreadCount: state.unreadCount + 1);
    // In-app banner gösterimi UI tarafında yapılacak (overlay)
    _onForegroundNotification?.call(message);
  }

  void _handleMessageTap(RemoteMessage message) {
    final actionUrl = message.data['action_url'] as String?;
    final notificationId = message.data['notification_id'] as String?;

    if (notificationId != null) {
      markAsRead(notificationId);
    }

    if (actionUrl != null) {
      _onNavigate?.call(actionUrl);
    }
  }

  // UI callback'leri
  void Function(RemoteMessage)? _onForegroundNotification;
  void Function(String actionUrl)? _onNavigate;

  void setUICallbacks({
    void Function(RemoteMessage)? onForegroundNotification,
    void Function(String actionUrl)? onNavigate,
  }) {
    _onForegroundNotification = onForegroundNotification;
    _onNavigate = onNavigate;
  }

  Future<void> fetchNotifications({int page = 1}) async {
    state = state.copyWith(isLoading: true);
    final result = await ref.read(notificationRepositoryProvider).getNotifications(page, 20);
    result.when(
      success: (list) {
        final all = page == 1 ? list : [...state.notifications, ...list];
        state = state.copyWith(notifications: all, isLoading: false);
      },
      failure: (_) => state = state.copyWith(isLoading: false),
    );
  }

  Future<void> fetchUnreadCount() async {
    final result = await ref.read(notificationRepositoryProvider).getUnreadCount();
    result.when(
      success: (count) => state = state.copyWith(unreadCount: count),
      failure: (_) {},
    );
  }

  Future<void> markAsRead(String id) async {
    await ref.read(notificationRepositoryProvider).markAsRead(id);
    final updated = state.notifications.map((n) {
      if (n.id == id) {
        return NotificationModel(
          id: n.id, userId: n.userId, campaignId: n.campaignId,
          type: n.type, title: n.title, body: n.body,
          imageUrl: n.imageUrl, actionUrl: n.actionUrl, actionLabel: n.actionLabel,
          isRead: true, createdAt: n.createdAt,
        );
      }
      return n;
    }).toList();
    state = state.copyWith(
      notifications: updated,
      unreadCount: (state.unreadCount - 1).clamp(0, 999),
    );
  }

  Future<void> markAllAsRead() async {
    await ref.read(notificationRepositoryProvider).markAllAsRead();
    final updated = state.notifications.map((n) {
      return NotificationModel(
        id: n.id, userId: n.userId, campaignId: n.campaignId,
        type: n.type, title: n.title, body: n.body,
        imageUrl: n.imageUrl, actionUrl: n.actionUrl, actionLabel: n.actionLabel,
        isRead: true, createdAt: n.createdAt,
      );
    }).toList();
    state = state.copyWith(notifications: updated, unreadCount: 0);
  }

  Future<void> trackClick(String id) async {
    await ref.read(notificationRepositoryProvider).trackClick(id);
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
```

**Step 2: Auth provider'da login sonrası init**

`auth_provider.dart`'ta login/register success sonrası:
```dart
// Login success callback'inde
ref.read(notificationProvider.notifier).init();
```

**Step 3: Commit**
```bash
git add lib/providers/notification_provider.dart lib/providers/auth_provider.dart lib/main.dart
git commit -m "feat: add notification state management with FCM lifecycle"
```

---

## Phase 5: Flutter — Bildirim Merkezi UI

### Task 9: SVG İkonlar + i18n Keys

**Files:**
- Create: `assets/icons/ic_bell.svg`
- Create: `assets/icons/ic_bell_filled.svg`
- Modify: `lib/core/constants/q_icons.dart`
- Modify: `lib/core/l10n/app_localizations.dart`

**Step 1: Çan ikonu SVG'leri**

`ic_bell.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
```

`ic_bell_filled.svg`:
```svg
<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="currentColor" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/></svg>
```

**Step 2: QIcons'a ekle**

```dart
// Notifications
static const icBell = 'assets/icons/ic_bell.svg';
static const icBellFilled = 'assets/icons/ic_bell_filled.svg';
```

**Step 3: i18n keys ekle**

TR:
```dart
'notifications': 'Bildirimler',
'mark_all_read': 'Tümünü Okundu Yap',
'no_notifications': 'Henüz bildirim yok',
'just_now': 'Az önce',
'minutes_ago': '{} dk önce',
'hours_ago': '{} saat önce',
'days_ago': '{} gün önce',
```

EN:
```dart
'notifications': 'Notifications',
'mark_all_read': 'Mark All Read',
'no_notifications': 'No notifications yet',
'just_now': 'Just now',
'minutes_ago': '{} min ago',
'hours_ago': '{} hours ago',
'days_ago': '{} days ago',
```

**Step 4: Commit**
```bash
git add assets/icons/ic_bell*.svg lib/core/constants/q_icons.dart lib/core/l10n/app_localizations.dart
git commit -m "feat: add notification icons and i18n keys"
```

---

### Task 10: Bildirim Merkezi Ekranı

**Files:**
- Create: `lib/features/notifications/screens/notifications_screen.dart`
- Create: `lib/features/notifications/widgets/notification_card.dart`
- Modify: `lib/routing/route_names.dart`
- Modify: `lib/routing/app_routes.dart`
- Modify: `lib/routing/app_router.dart` (import)

**Step 1: NotificationCard widget**

```dart
// lib/features/notifications/widgets/notification_card.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/notification_model.dart';

class NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback? onActionTap;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: notification.isRead ? null : AppColors.primarySurface.withValues(alpha: 0.3),
          border: Border(bottom: BorderSide(color: AppColors.divider, width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Unread dot
            if (!notification.isRead)
              Container(
                width: 8, height: 8,
                margin: const EdgeInsets.only(top: 6, right: AppSpacing.sm),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              )
            else
              const SizedBox(width: 8 + AppSpacing.sm),

            // Image (opsiyonel)
            if (notification.imageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                child: CachedNetworkImage(
                  imageUrl: notification.imageUrl!,
                  width: 48, height: 48, fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
            ],

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification.title,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(notification.body,
                    style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: AppSpacing.xs),
                  Text(_timeAgo(notification.createdAt),
                    style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textHint)),

                  // CTA butonu
                  if (notification.actionLabel != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    SizedBox(
                      height: 32,
                      child: AppButton(
                        label: notification.actionLabel!,
                        onPressed: onActionTap,
                        variant: AppButtonVariant.outline,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _timeAgo(String isoDate) {
    final date = DateTime.parse(isoDate);
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Az önce';
    if (diff.inHours < 1) return '${diff.inMinutes} dk önce';
    if (diff.inDays < 1) return '${diff.inHours} saat önce';
    return '${diff.inDays} gün önce';
  }
}
```

**Step 2: NotificationsScreen**

```dart
// lib/features/notifications/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/navigation/navigation.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_scaffold.dart';
import '../../../core/l10n/l10n.dart';
import '../../../providers/notification_provider.dart';
import '../widgets/notification_card.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(notificationProvider);

    return AppScaffold(
      title: context.tr('notifications'),
      showBackButton: true,
      padding: EdgeInsets.zero,
      actions: [
        if (notifState.unreadCount > 0)
          TextButton(
            onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
            child: Text(context.tr('mark_all_read'),
              style: TextStyle(color: AppColors.primary, fontSize: 12)),
          ),
      ],
      body: notifState.isLoading && notifState.notifications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notifState.notifications.isEmpty
              ? Center(child: Text(context.tr('no_notifications')))
              : RefreshIndicator(
                  onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
                  child: ListView.builder(
                    itemCount: notifState.notifications.length,
                    itemBuilder: (context, index) {
                      final notif = notifState.notifications[index];
                      return NotificationCard(
                        notification: notif,
                        onTap: () => _onNotificationTap(notif),
                        onActionTap: notif.actionLabel != null
                            ? () => _onActionTap(notif)
                            : null,
                      );
                    },
                  ),
                ),
    );
  }

  void _onNotificationTap(notification) {
    ref.read(notificationProvider.notifier).markAsRead(notification.id);
    if (notification.actionUrl != null) {
      ref.read(navigationServiceProvider).go(notification.actionUrl);
    }
  }

  void _onActionTap(notification) {
    ref.read(notificationProvider.notifier).trackClick(notification.id);
    if (notification.actionUrl != null) {
      ref.read(navigationServiceProvider).go(notification.actionUrl);
    }
  }
}
```

**Step 3: Route ekle**

`route_names.dart`'a:
```dart
static const notifications = 'notifications';
```

`app_routes.dart`'ta profile routes'a:
```dart
GoRoute(
  path: 'notifications',
  name: RouteNames.notifications,
  builder: (context, state) => const NotificationsScreen(),
),
```

`app_router.dart`'a import ekle.

**Step 4: Commit**
```bash
git add lib/features/notifications/ lib/routing/
git commit -m "feat: add notifications screen with inbox UI"
```

---

### Task 11: Profile Ekranına Bildirim İkonu + Badge

**Files:**
- Modify: `lib/features/profile/screens/profile_screen.dart`

**Step 1: AppBar actions'a çan ikonu + unread badge ekle**

Profile screen'in AppBar'ına:
```dart
actions: [
  Stack(
    children: [
      IconButton(
        icon: QIcon(QIcons.icBell, size: 24),
        onPressed: () => ref.read(navigationServiceProvider).go(RouteNames.notifications),
      ),
      if (unreadCount > 0)
        Positioned(
          right: 8, top: 8,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
            child: Text('$unreadCount',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
    ],
  ),
],
```

`unreadCount`'u provider'dan al:
```dart
final unreadCount = ref.watch(notificationProvider.select((s) => s.unreadCount));
```

**Step 2: Commit**
```bash
git add lib/features/profile/screens/profile_screen.dart
git commit -m "feat: add notification bell icon with unread badge to profile"
```

---

### Task 12: In-App Banner (Foreground Bildirim)

**Files:**
- Create: `lib/core/widgets/in_app_banner.dart`
- Modify: `lib/app.dart` (overlay ekleme)

**Step 1: Banner widget oluştur**

```dart
// lib/core/widgets/in_app_banner.dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class InAppBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const InAppBanner({
    super.key,
    required this.title,
    required this.body,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<InAppBanner> createState() => _InAppBannerState();
}

class _InAppBannerState extends State<InAppBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // 4 saniye sonra otomatik kapat
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) _dismiss();
    });
  }

  void _dismiss() {
    _controller.reverse().then((_) => widget.onDismiss());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: () {
          widget.onTap?.call();
          _dismiss();
        },
        onVerticalDragEnd: (_) => _dismiss(),
        child: SafeArea(
          bottom: false,
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications, color: AppColors.primary, size: 24),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(widget.body,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 2: App'te overlay entegrasyonu**

`app.dart`'ta (veya MainShell'de) `notificationProvider` dinleyerek foreground bildirim geldiğinde `OverlayEntry` ile `InAppBanner` göster.

**Step 3: Commit**
```bash
git add lib/core/widgets/in_app_banner.dart lib/app.dart
git commit -m "feat: add in-app notification banner for foreground messages"
```

---

## Phase 6: Entegrasyon + Son Dokunuşlar

### Task 13: Opened Event Tracking

**Files:**
- Modify: `lib/providers/notification_provider.dart`

Bildirim merkezi açıldığında `opened` event'i kaydetmek için — `markAsRead` çağrıldığında eğer kampanya bildiriyse `opened` event'i de gönder.

Backend'de `trackClick` benzeri bir `trackOpened` endpoint veya mevcut `markAsRead`'e event ekleme:

`notification-api.service.ts`'te `markAsRead`'i genişlet:
```typescript
async markAsRead(userId: string, notificationId: string) {
  const { data: notif } = await supabase
    .from('notifications')
    .select('campaign_id, is_read')
    .eq('id', notificationId)
    .eq('user_id', userId)
    .single();

  if (!notif) return;

  // Okundu yap
  await supabase
    .from('notifications')
    .update({ is_read: true })
    .eq('id', notificationId)
    .eq('user_id', userId);

  // İlk kez okunuyorsa opened event kaydet
  if (!notif.is_read && notif.campaign_id) {
    await supabase.from('campaign_events').insert({
      campaign_id: notif.campaign_id,
      user_id: userId,
      event: 'opened',
    });
    await supabase.rpc('increment_campaign_stat', {
      p_campaign_id: notif.campaign_id,
      p_field: 'total_opened',
    });
  }
}
```

**Step 1: Backend güncelle**

**Step 2: Commit**
```bash
git add server/src/services/notification-api.service.ts
git commit -m "feat: track opened events when notification is read"
```

---

### Task 14: Campaign i18n Templates (Push Body)

**Files:**
- Modify: `server/src/locales/en.json`
- Modify: `server/src/locales/tr.json`

Campaign bildirimleri admin'in girdiği metni kullandığı için locale dosyasına `campaign` key eklenmesine gerek yok — mevcut push template'ten `campaign` tipi çıkarılabilir.

Ancak `notification.service.ts`'te campaign tipi için özel handling:
```typescript
// campaign tipinde template kullanma, doğrudan options.title kullan
if (type === 'campaign') {
  // template'e bakma, options'tan al
}
```

Bu zaten Task 2'de yapıldı (`!template && !options?.title` kontrolü).

**Step 1: Commit (eğer değişiklik varsa)**
```bash
git add server/src/locales/
git commit -m "chore: update locale files for campaign support"
```

---

### Task 15: Tüm Sistemin Entegrasyon Testi

**Step 1: Migration'ı çalıştır** (Supabase SQL Editor)

**Step 2: Backend'i başlat**
```bash
cd server && npm run dev
```

**Step 3: Flutter'ı çalıştır**
```bash
flutter run
```

**Step 4: Test senaryoları**
1. Login → token backend'e gönderildi mi? (server loglarını kontrol et)
2. Profile ekranında çan ikonu görünüyor mu?
3. Çana tıkla → bildirim merkezi açılıyor mu?
4. Admin panelinde /admin/campaigns → kampanya listesi
5. Yeni kampanya oluştur → segment builder çalışıyor mu?
6. Kampanya gönder → bildirimler inbox'ta göründü mü?
7. Bildirime tıkla → action_url'e navigate etti mi?
8. Kampanya detayında stats güncellenmiş mi?

**Step 5: dart analyze**
```bash
dart analyze lib/
```

**Step 6: Commit (varsa fix)**
```bash
git add -A
git commit -m "fix: integration test fixes for notification system"
```

---

### Task 16: Final Cleanup + Analiz

**Step 1: Kullanılmayan import'ları temizle**
```bash
dart analyze lib/
```

**Step 2: Final commit**
```bash
git add -A
git commit -m "chore: cleanup and finalize notification system"
```
