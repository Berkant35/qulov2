---
name: reference-salt-okuma-prod-probe
description: Supabase MCP yokken prod'u salt okuma yoklama yolu — node/tsx --env-file=.env ile sunucunun kendi istemcisi; .mts şart; RLS/şema katalogu okunamaz
metadata:
  type: reference
---

Supabase MCP bağlı değilse (2026-09-30 oturumu) prod'a salt okuma:
- Düz sorgu: scratchpad'de `.mjs`, `createRequire(qulo-server/package.json)` ile `@supabase/supabase-js`, anahtarlar
  `process.env.SUPABASE_URL` / `SUPABASE_SERVICE_ROLE_KEY`; çalıştır: `cd qulo-server && node --env-file=.env <dosya>.mjs`.
  Anahtar ekrana basılmaz, `.env` okunmaz (kanca engeller; `--env-file` serbest).
- Üretim kodunu canlı veriyle çalıştırmak: `npx tsx --env-file=.env <dosya>.mts` — **`.mts` şart** (`.ts` cjs'e düşer, top-level
  await hatası), servisleri mutlak yoldan dinamik `import()` et. Cron/sunucu başlamaz.
- Sınır: PostgREST yalnız public şema → `information_schema`, RLS (`relrowsecurity`), DDL, migration YOK; bunlar MCP ya da kullanıcı.
  `select("*").limit(1)` ile canlı kolon adları okunabilir (repo migration'ına güvenme).
