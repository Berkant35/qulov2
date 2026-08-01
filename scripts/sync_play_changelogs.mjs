#!/usr/bin/env node
// scripts/testflight_release_notes.json → android/fastlane/metadata/android/<locale>/changelogs/<versionCode>.txt
//
// Release notlari TEK kaynakta tutulur (testflight_release_notes.json); App Store,
// TestFlight ve Play ayni metni kullanir. Bu script Play'in bekledigi dosya
// duzenini uretir.
//
// ONEMLI: Hedef diller SABIT LISTE DEGIL — Play Console'daki GERCEK magaza
// listelemesi dilleri API'den cekilir. Sebep: sabit 16 dilli liste ilk denemede
// "Invalid request - This app has no title for language fr-FR" hatasi verdi.
// Play, magaza listelemesi olmayan bir dile release notu kabul etmiyor; ayrica
// Play'in 6 Ingilizce varyanti (en-AU/CA/GB/IN/SG/ZA) listede hic yoktu.
//
// Eslestirme sirasi: birebir dil kodu -> temel dil (en-AU -> en) -> en.
//
// Kullanim:
//   node scripts/sync_play_changelogs.mjs            # versionCode pubspec.yaml'dan
//   node scripts/sync_play_changelogs.mjs 69         # elle versionCode

import { readFileSync, writeFileSync, mkdirSync, rmSync, existsSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { homedir } from 'node:os';
import crypto from 'node:crypto';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const NOTES_FILE = join(ROOT, 'scripts/testflight_release_notes.json');
const METADATA_DIR = join(ROOT, 'android/fastlane/metadata/android');
const KEY_PATH = process.env.PLAY_JSON_KEY_FILE || join(homedir(), 'private_keys/qulo-play-service-account.json');
const PACKAGE = 'com.wordpress.calikusuberkant.qulo';
const PLAY_LIMIT = 500; // Play Console dil basina karakter siniri

function versionCodeFromPubspec() {
  const pubspec = readFileSync(join(ROOT, 'pubspec.yaml'), 'utf8');
  const line = pubspec.match(/^version:\s*(.+)$/m)?.[1]?.trim();
  const code = line?.split('+')[1];
  if (!code) throw new Error(`pubspec.yaml'dan versionCode okunamadi (satir: ${line})`);
  return code;
}

/** Play Console'daki gercek magaza listelemesi dillerini dondurur. */
async function fetchPlayLocales() {
  if (!existsSync(KEY_PATH)) {
    throw new Error(
      `Play service account anahtari bulunamadi: ${KEY_PATH}\n` +
      `Kurulum icin: android/fastlane/SETUP.md`,
    );
  }
  const key = JSON.parse(readFileSync(KEY_PATH, 'utf8'));
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${b64({ alg: 'RS256', typ: 'JWT' })}.${b64({
    iss: key.client_email,
    scope: 'https://www.googleapis.com/auth/androidpublisher',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  })}`;
  const sig = crypto.sign('RSA-SHA256', Buffer.from(unsigned), key.private_key).toString('base64url');

  const tokRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${unsigned}.${sig}`,
    }),
  });
  const tok = await tokRes.json();
  if (!tok.access_token) throw new Error(`Play token alinamadi: ${JSON.stringify(tok)}`);

  const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}`;
  const headers = { Authorization: `Bearer ${tok.access_token}`, 'Content-Type': 'application/json' };

  const editRes = await fetch(`${base}/edits`, { method: 'POST', headers });
  if (!editRes.ok) throw new Error(`Play edit acilamadi: ${editRes.status} ${await editRes.text()}`);
  const edit = await editRes.json();

  const listRes = await fetch(`${base}/edits/${edit.id}/listings`, { headers });
  if (!listRes.ok) throw new Error(`Play listelemeleri alinamadi: ${listRes.status} ${await listRes.text()}`);
  const listings = await listRes.json();

  // Salt okuma yaptik; edit'i birakiyoruz ki askida kalmasin.
  await fetch(`${base}/edits/${edit.id}`, { method: 'DELETE', headers }).catch(() => {});

  return (listings.listings ?? []).map((l) => l.language).sort();
}

/** Play dil kodu -> notes anahtari. Birebir, sonra temel dil, sonra en. */
function noteFor(notes, locale) {
  if (notes[locale]) return { key: locale, text: notes[locale] };
  const base = locale.split('-')[0];
  if (notes[base]) return { key: base, text: notes[base] };
  return { key: 'en (yedek)', text: notes.en };
}

const versionCode = process.argv[2] || versionCodeFromPubspec();
const notes = JSON.parse(readFileSync(NOTES_FILE, 'utf8'));
if (!notes.en) throw new Error(`${NOTES_FILE} icinde 'en' yok — yedek dil zorunlu`);

const playLocales = await fetchPlayLocales();
console.log(`Play'deki magaza dilleri (${playLocales.length}): ${playLocales.join(' ')}\n`);

// Play'de olmayan dillerin klasorleri kalmasin — supply onlari da yuklemeye calisip patlar.
if (existsSync(METADATA_DIR)) {
  for (const dir of readdirSync(METADATA_DIR)) {
    if (!playLocales.includes(dir)) {
      rmSync(join(METADATA_DIR, dir), { recursive: true, force: true });
      console.log(`  - ${dir} kaldirildi (Play'de magaza listelemesi yok)`);
    }
  }
}

let tooLong = 0;
for (const locale of playLocales) {
  const { key, text } = noteFor(notes, locale);
  if (text.length > PLAY_LIMIT) {
    console.error(`  ✗ ${locale}: ${text.length} karakter — Play siniri ${PLAY_LIMIT}`);
    tooLong++;
    continue;
  }
  const dir = join(METADATA_DIR, locale, 'changelogs');
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, `${versionCode}.txt`), `${text}\n`, 'utf8');
  const via = key === locale ? '' : `  (kaynak: ${key})`;
  console.log(`  ✓ ${locale}/changelogs/${versionCode}.txt${via}`);
}

if (tooLong) {
  console.error(`\n${tooLong} dil siniri asti — duzeltmeden yukleme yapma.`);
  process.exit(1);
}

console.log(`\nHazir: versionCode ${versionCode}, ${playLocales.length} dil.`);
