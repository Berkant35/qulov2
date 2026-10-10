#!/usr/bin/env node
// App Store Connect — surumu incelemeye gonder (reviewSubmission).
//
// NEDEN: fastlane'de bu adim yok; 2.0.10'da uc API cagrisi elle yapildi ve
// sonraki surumde yeniden kesfedilmek zorunda kaldi. Bu script o uc adimi
// tek yerde tutar ve VARSAYILAN OLARAK KURU CALISIR: durumu yazar, gondermez.
//
// Onkosullar (script kontrol eder): surum PREPARE_FOR_SUBMISSION, build bagli,
// build VALID, usesNonExemptEncryption null degil.
//
// Kullanim:
//   node scripts/asc_submit_review.mjs 2.0.11            # kuru calistirma
//   node scripts/asc_submit_review.mjs 2.0.11 --apply    # GONDERIR (geri alinamaz*)
//   (*) Gonderim ASC'de "Cancel Submission" ile geri cekilebilir ama inceleme
//       sirasi kaybolur; bu yuzden --apply yalniz kullanici "yayinla" deyince.
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { createSign } from 'node:crypto';

const KEY_ID = process.env.APP_STORE_API_KEY;
const ISSUER_ID = process.env.APP_STORE_API_ISSUER;
const BUNDLE_ID = process.env.IOS_BUNDLE_ID || 'com.wordpress.calikusuberkant.qulorelease';
const VERSION = process.argv[2];
const APPLY = process.argv.includes('--apply');
if (!KEY_ID || !ISSUER_ID) { console.error('Eksik env: APP_STORE_API_KEY, APP_STORE_API_ISSUER'); process.exit(2); }
if (!VERSION) { console.error('Kullanim: node scripts/asc_submit_review.mjs <surum> [--apply]'); process.exit(2); }

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
  if (!res.ok) throw new Error(`${res.status} ${path}\n${text.slice(0, 3000)}`);
  return text ? JSON.parse(text) : {};
}

const app = (await api(`/v1/apps?filter[bundleId]=${BUNDLE_ID}`)).data?.[0];
if (!app) throw new Error(`Uygulama bulunamadi: ${BUNDLE_ID}`);
const ver = (await api(`/v1/apps/${app.id}/appStoreVersions?filter[versionString]=${VERSION}&filter[platform]=IOS`)).data?.[0];
if (!ver) throw new Error(`${VERSION} surumu ASC'de yok`);
const state = ver.attributes.appStoreState;
const build = (await api(`/v1/appStoreVersions/${ver.id}/build`)).data;
console.log(`Surum ${VERSION}: ${state}, releaseType ${ver.attributes.releaseType}`);
console.log(`Bagli build: ${build ? `${build.attributes.version} (${build.attributes.processingState}, usesNonExemptEncryption=${build.attributes.usesNonExemptEncryption})` : 'YOK'}`);

const problems = [];
// READY_FOR_REVIEW = ASC'de "Incelemeye ekle" yapilmis ama gonderilmemis taslak. Icinde BU surum
// varsa yeni gonderim acmak yerine o taslak gonderilir (2.0.14'te boyleydi; eski akis burada takiliyordu).
const open = (await api(`/v1/reviewSubmissions?filter[app]=${app.id}&filter[state]=READY_FOR_REVIEW,WAITING_FOR_REVIEW,IN_REVIEW,UNRESOLVED_ISSUES`)).data ?? [];
let draft = null;
let empty = null; // onceki --apply ogeyi ekleyemeden kaldiysa bos taslak kalir (2.0.15: eksik URL → 409) — yeniden kullanilir
for (const s of open) {
  const items = (await api(`/v1/reviewSubmissions/${s.id}/items?include=appStoreVersion`)).data ?? [];
  if (s.attributes.state !== 'READY_FOR_REVIEW') {
    // Apple ayni anda birden cok gonderime izin veriyor (2026-10-06: iki Asset Library gonderimi birlikte
    // WAITING_FOR_REVIEW). Engel yalniz icinde bir uygulama surumu olan acik gonderim; digerleri bilgi.
    const withVersion = items.some((it) => it.relationships?.appStoreVersion?.data);
    if (withVersion) problems.push(`acik inceleme gonderimi var (surum iceriyor): ${s.id} ${s.attributes.state}`);
    else console.log(`Bilgi: surum icermeyen acik gonderim var: ${s.id} ${s.attributes.state} (${items.length} oge) — engel sayilmadi`);
    continue;
  }
  const hasVersion = items.some((it) => it.relationships?.appStoreVersion?.data?.id === ver.id);
  if (!items.length && !empty) { empty = s; console.log(`Bilgi: bos taslak gonderim ${s.id} — surum buna eklenecek`); continue; }
  if (hasVersion && !draft) draft = s;
  else problems.push(`baska bir taslak gonderim var: ${s.id} (${items.length} oge, bu surum ${hasVersion ? 'icinde' : 'yok'})`);
}
const allowedStates = draft ? ['PREPARE_FOR_SUBMISSION', 'READY_FOR_REVIEW'] : ['PREPARE_FOR_SUBMISSION'];
if (!allowedStates.includes(state)) problems.push(`surum durumu ${state}, ${allowedStates.join(' / ')} olmali`);
if (!build) problems.push('surume build bagli degil');
else {
  if (build.attributes.processingState !== 'VALID') problems.push(`build ${build.attributes.processingState}`);
  if (build.attributes.usesNonExemptEncryption === null) problems.push('export compliance (usesNonExemptEncryption) bos');
}
if (problems.length) {
  console.error('GONDERILEMEZ:'); for (const p of problems) console.error(`  - ${p}`);
  process.exit(1);
}
if (draft) console.log(`Taslak inceleme gonderimi bulundu: ${draft.id} (bu surumu iceriyor) — o gonderilecek.`);
if (!APPLY) { console.log('KURU CALISTIRMA: onkosullar tamam, --apply ile incelemeye gonderilir.'); process.exit(0); }

let subId = draft?.id;
if (!subId) {
  subId = empty?.id ?? (await api('/v1/reviewSubmissions', { method: 'POST', body: JSON.stringify({ data: { type: 'reviewSubmissions', attributes: { platform: 'IOS' }, relationships: { app: { data: { type: 'apps', id: app.id } } } } }) })).data.id;
  await api('/v1/reviewSubmissionItems', { method: 'POST', body: JSON.stringify({ data: { type: 'reviewSubmissionItems', relationships: { reviewSubmission: { data: { type: 'reviewSubmissions', id: subId } }, appStoreVersion: { data: { type: 'appStoreVersions', id: ver.id } } } } }) });
}
const done = await api(`/v1/reviewSubmissions/${subId}`, { method: 'PATCH', body: JSON.stringify({ data: { type: 'reviewSubmissions', id: subId, attributes: { submitted: true } } }) });
console.log(`GONDERILDI: reviewSubmission ${subId} → ${done.data.attributes.state}`);
