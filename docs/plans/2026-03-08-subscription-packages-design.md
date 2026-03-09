# Qulo V2 — Subscription Packages Design

## Packages

| Feature | Free | Plus ($4.99/mo) | Premium ($9.99/mo) |
|---------|------|-----------------|-------------------|
| Daily discover | 50 | Unlimited | Unlimited |
| Question slots | 4 | 6 | 10 |
| Undo (rewind) | No | 3/day | Unlimited |
| Passport mode | No | No | Yes |
| Monthly purple diamonds | 0 | 500 | 1500 |
| Ads | Yes | No | No |

## Implementation Requirements

### Backend
- Update SUBSCRIPTION_LIMITS in types/index.ts
- Discover limit: daily_discovers_used counter + reset
- Question slot limit: enforce max questions per plan
- Undo endpoint: POST /users/me/undo-swipe
- Passport mode: location override for discover
- Cron jobs: daily reset, monthly bonus, subscription expire

### Flutter
- Update subscription comparison screen texts
- Update i18n (EN + TR)
- Discover limit UI (counter + upsell when exhausted)
- Question create limit check
- Undo button in discover (Plus/Premium only)

### Removed Features (not in packages)
- "Who viewed me" — removed
- Super like — removed (all monetization via purple diamonds)
- Message limits — everyone has unlimited messaging
- Boost — available to everyone via green diamonds (not subscription-gated)
