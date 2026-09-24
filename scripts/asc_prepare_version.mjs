#!/usr/bin/env node
// App Store Connect — surum kaydini hazirla: yoksa olustur (PREPARE_FOR_SUBMISSION),
// istenirse islenmis (VALID) build'i bagla. VARSAYILAN OLARAK KURU CALISIR.
//
// NEDEN: `preflight` lane'i surum kaydi yoksa duruyor ("ASC > + Surum ile olustur");
// 2.0.11 READY_FOR_SALE olunca 2.0.12 icin kayit elle acilmak zorundaydi. Bu script
// o adimi ve build baglamayi (asc_submit_review'in onkosulu) tek yerde tutar.
//
// Kullanim:
//   node scripts/asc_prepare_version.mjs 2.0.12                    # durum raporu
//   node scripts/asc_prepare_version.mjs 2.0.12 --apply            # yoksa olusturur
//   node scripts/asc_prepare_version.mjs 2.0.12 --bind 77 --apply  # build 77'yi baglar
// Incelemeye GONDERMEZ (o adim: asc_submit_review.mjs --apply, yalniz "yayinla" deyince).
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { createSign } from 'node:crypto';

const KEY_ID = process.env.APP_STORE_API_KEY;
const ISSUER_ID = process.env.APP_STORE_API_ISSUER;
const BUNDLE_ID = process.env.IOS_BUNDLE_ID || 'com.wordpress.calikusuberkant.qulorelease';
const VERSION = process.argv[2];
const APPLY = process.argv.includes('--apply');
const bindIdx = process.argv.indexOf('--bind');
const BIND = bindIdx > -1 ? process.argv[bindIdx + 1] : null;

if (!KEY_ID || !ISSUER_ID) { console.error('Eksik env: APP_STORE_API_KEY, APP_STORE_API_ISSUER'); process.exit(2); }
if (!VERSION) { console.error('Kullanim: node scripts/asc_prepare_version.mjs <surum> [--bind <buildNo>] [--apply]'); process.exit(2); }

const PK = readFileSync(`${homedir()}/.private_keys/AuthKey_${KEY_ID}.p8`, 'utf8');
const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const now = Math.floor(Date.now() / 1000);
const head = b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' });
const body = b64({ iss: ISSUER_ID, iat: now, exp: now + 900, aud: 'appstoreconnect-v1' });
const sig = createSign('SHA256').update(`${head}.${body}`).sign({ key: PK, dsaEncoding: 'ieee-p1363' }).toString('base64url');
const TOKEN = `${head}.${body}.${sig}`;

async function api(path, opts = {}) {
  const res = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    ...opts,
    headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json' },
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${opts.method || 'GET'} ${path} → ${res.status}\n${text}`);
  return text ? JSON.parse(text) : {};
}

// Yeni build kabul eden (duzenlenebilir) durumlar — asc_version_state.mjs ile ayni liste.
const OPEN = new Set(['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED',
  'WAITING_FOR_REVIEW', 'INVALID_BINARY', 'READY_FOR_REVIEW', 'DEVELOPER_REMOVED_FROM_SALE']);

const app = (await api(`/v1/apps?filter[bundleId]=${encodeURIComponent(BUNDLE_ID)}&limit=1`)).data?.[0];
if (!app) { console.error(`Uygulama bulunamadi: ${BUNDLE_ID}`); process.exit(2); }

const versions = (await api(`/v1/apps/${app.id}/appStoreVersions?filter[platform]=IOS&limit=50`)).data;
const byState = versions.map((v) => `${v.attributes.versionString} (${v.attributes.appStoreState})`).slice(0, 5);
console.log(`Son surumler: ${byState.join(', ')}`);

let ver = versions.find((v) => v.attributes.versionString === VERSION);
const otherOpen = versions.filter((v) => OPEN.has(v.attributes.appStoreState) && v.attributes.versionString !== VERSION);

if (ver) {
  console.log(`${VERSION}: ${ver.attributes.appStoreState} (id ${ver.id})`);
} else if (otherOpen.length) {
  // ASC ayni anda tek "hazirlanan" surume izin verir; olan kaydi yeniden adlandirmak
  // gerekir. Bunu script yapmaz — kararı insan verir (o kayit baska bir surumun notlarini tasiyor olabilir).
  console.error(`HATA: ${VERSION} yok ama acik baska surum var: ${otherOpen.map((v) => v.attributes.versionString).join(', ')}. ASC'de onu ${VERSION} olarak yeniden adlandir.`);
  process.exit(1);
} else if (!APPLY) {
  console.log(`${VERSION} YOK — --apply ile PREPARE_FOR_SUBMISSION olarak olusturulur.`);
} else {
  ver = (await api('/v1/appStoreVersions', {
    method: 'POST',
    body: JSON.stringify({ data: { type: 'appStoreVersions', attributes: { platform: 'IOS', versionString: VERSION },
      relationships: { app: { data: { type: 'apps', id: app.id } } } } }),
  })).data;
  console.log(`✓ Olusturuldu: ${VERSION} → ${ver.attributes.appStoreState} (id ${ver.id})`);
}

if (BIND) {
  const builds = (await api(`/v1/builds?filter[app]=${app.id}&filter[preReleaseVersion.version]=${VERSION}&filter[version]=${BIND}&limit=5`)).data;
  const build = builds[0];
  if (!build) { console.error(`HATA: ${VERSION} (${BIND}) build'i ASC'de yok (henuz yuklenmedi?)`); process.exit(1); }
  const st = build.attributes.processingState;
  console.log(`Build ${BIND}: ${st} (id ${build.id})`);
  if (st !== 'VALID') { console.error('HATA: build henuz VALID degil — islenmesini bekle.'); process.exit(1); }
  if (!ver) { console.error('HATA: baglanacak surum kaydi yok.'); process.exit(1); }
  if (!APPLY) { console.log(`--apply ile build ${BIND} → ${VERSION} baglanir.`); }
  else {
    await api(`/v1/appStoreVersions/${ver.id}/relationships/build`, {
      method: 'PATCH', body: JSON.stringify({ data: { type: 'builds', id: build.id } }),
    });
    console.log(`✓ Build ${BIND} → ${VERSION} baglandi.`);
  }
}
