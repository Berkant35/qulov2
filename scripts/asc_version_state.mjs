#!/usr/bin/env node
// App Store Connect'te bir surum numarasinin yeni build kabul edip etmedigini kontrol eder.
//
// NEDEN: 2026-09-01'de 2.0.7+70 build'i alindi, yuklendi ve Apple reddetti:
//   90186 — "Invalid Pre-Release Train. The train version '2.0.7' is closed"
//   90062 — "CFBundleShortVersionString must contain a higher version than the
//            previously approved version"
// Yani 2.0.7 zaten READY_FOR_SALE oldugu icin o surume hicbir build gonderilemiyordu.
// Build numarasini artirmak ise ceremez — pubspec'teki surumu yukseltmek gerekir.
// Bu 20 dakikalik bir build turu bosa gitti. Bu script o turu bastan onler.
//
// Kullanim: node scripts/asc_version_state.mjs 2.0.8
// Cikis:    0 = bu surume build gonderilebilir, 1 = gonderilemez (sebep yazilir)

import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { createSign } from 'node:crypto';

const KEY_ID = process.env.APP_STORE_API_KEY;
const ISSUER_ID = process.env.APP_STORE_API_ISSUER;
const BUNDLE_ID = process.env.IOS_BUNDLE_ID || 'com.wordpress.calikusuberkant.qulorelease';
const WANTED = process.argv[2];

if (!KEY_ID || !ISSUER_ID) {
  console.error('Eksik env: APP_STORE_API_KEY, APP_STORE_API_ISSUER');
  process.exit(2);
}
if (!WANTED) {
  console.error('Kullanim: node scripts/asc_version_state.mjs <surum>  (or: 2.0.8)');
  process.exit(2);
}

const PRIVATE_KEY = readFileSync(`${homedir()}/.private_keys/AuthKey_${KEY_ID}.p8`, 'utf8');

function jwt() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const header = b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' });
  const payload = b64({
    iss: ISSUER_ID,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 20 * 60,
    aud: 'appstoreconnect-v1',
  });
  const signer = createSign('SHA256');
  signer.update(`${header}.${payload}`);
  const sig = signer.sign({ key: PRIVATE_KEY, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  return `${header}.${payload}.${sig}`;
}

const token = jwt();
async function api(path) {
  const res = await fetch(`https://api.appstoreconnect.apple.com/v1${path}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${path} → ${res.status}\n${text}`);
  return JSON.parse(text);
}

// Yeni build kabul eden state'ler. Bunlarin disindaki her sey (ozellikle
// READY_FOR_SALE) o surum hattinin kapali oldugu anlamina gelir.
const OPEN_STATES = new Set([
  'PREPARE_FOR_SUBMISSION',
  'DEVELOPER_REJECTED',
  'REJECTED',
  'METADATA_REJECTED',
  'WAITING_FOR_REVIEW',
  'INVALID_BINARY',
  'READY_FOR_REVIEW',
  'DEVELOPER_REMOVED_FROM_SALE',
]);

const apps = await api(`/apps?filter[bundleId]=${encodeURIComponent(BUNDLE_ID)}&limit=1`);
const appId = apps.data?.[0]?.id;
if (!appId) {
  console.error(`Uygulama bulunamadi: ${BUNDLE_ID}`);
  process.exit(2);
}

const versions = await api(`/apps/${appId}/appStoreVersions?limit=50`);
const match = versions.data.find((v) => v.attributes.versionString === WANTED);

if (!match) {
  console.error(`HATA: App Store Connect'te ${WANTED} surumu YOK.`);
  console.error('Once App Store Connect > "+ Surum" ile bu surumu olustur,');
  console.error('sonra build gonder. Aksi halde build hicbir surume baglanmaz.');
  process.exit(1);
}

const state = match.attributes.appStoreState;
if (!OPEN_STATES.has(state)) {
  console.error(`HATA: ${WANTED} surumu "${state}" durumunda — yeni build KABUL ETMIYOR.`);
  console.error('');
  console.error('Apple bunu 90186 / 90062 hatalariyla reddeder. Build numarasini');
  console.error('artirmak COZMEZ; pubspec.yaml icindeki surumu yukseltmen gerekir.');
  console.error('');
  const open = versions.data.filter((v) => OPEN_STATES.has(v.attributes.appStoreState));
  if (open.length) {
    console.error('Su an build kabul eden surumler: ' +
      open.map((v) => `${v.attributes.versionString} (${v.attributes.appStoreState})`).join(', '));
  } else {
    console.error('Su an build kabul eden hicbir surum yok — App Store Connect\'te yeni surum olustur.');
  }
  process.exit(1);
}

console.log(`${WANTED} — ${state} (build kabul ediyor)`);
