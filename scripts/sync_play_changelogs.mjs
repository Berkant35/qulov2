#!/usr/bin/env node
// scripts/testflight_release_notes.json → android/fastlane/metadata/android/<locale>/changelogs/<versionCode>.txt
//
// Release notlari TEK kaynakta tutulur (testflight_release_notes.json); App Store,
// TestFlight ve Play ayni metni kullanir. Bu script Play'in bekledigi dosya
// duzenini uretir — elle 16 dil kopyalamak hataya cok acikti.
//
// Kullanim:
//   node scripts/sync_play_changelogs.mjs            # versionCode pubspec.yaml'dan
//   node scripts/sync_play_changelogs.mjs 68         # elle versionCode

import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
const NOTES_FILE = join(ROOT, 'scripts/testflight_release_notes.json');
const METADATA_DIR = join(ROOT, 'android/fastlane/metadata/android');

// Play Console'un supply icin bekledigi dizin adlari.
const PLAY_LOCALES = {
  tr: 'tr-TR', en: 'en-US', de: 'de-DE', es: 'es-ES', fr: 'fr-FR', it: 'it-IT',
  pt: 'pt-PT', nl: 'nl-NL', pl: 'pl-PL', ru: 'ru-RU', sv: 'sv-SE', ar: 'ar',
  hi: 'hi-IN', ja: 'ja-JP', ko: 'ko-KR', zh: 'zh-CN',
};

const PLAY_LIMIT = 500; // Play Console dil basina karakter siniri

function versionCodeFromPubspec() {
  const pubspec = readFileSync(join(ROOT, 'pubspec.yaml'), 'utf8');
  const line = pubspec.match(/^version:\s*(.+)$/m)?.[1]?.trim();
  const code = line?.split('+')[1];
  if (!code) throw new Error(`pubspec.yaml'dan versionCode okunamadi (satir: ${line})`);
  return code;
}

const versionCode = process.argv[2] || versionCodeFromPubspec();
const notes = JSON.parse(readFileSync(NOTES_FILE, 'utf8'));

const missing = Object.keys(PLAY_LOCALES).filter((k) => !notes[k]);
if (missing.length) {
  console.error(`Eksik dil(ler) ${NOTES_FILE} icinde: ${missing.join(', ')}`);
  process.exit(1);
}

let tooLong = 0;
for (const [key, locale] of Object.entries(PLAY_LOCALES)) {
  const text = notes[key];
  if (text.length > PLAY_LIMIT) {
    console.error(`✗ ${locale}: ${text.length} karakter — Play siniri ${PLAY_LIMIT}`);
    tooLong++;
    continue;
  }
  const dir = join(METADATA_DIR, locale, 'changelogs');
  mkdirSync(dir, { recursive: true });
  writeFileSync(join(dir, `${versionCode}.txt`), `${text}\n`, 'utf8');
  console.log(`✓ ${locale}/changelogs/${versionCode}.txt (${text.length} kar)`);
}

if (tooLong) {
  console.error(`\n${tooLong} dil siniri asti — duzeltmeden yukleme yapma.`);
  process.exit(1);
}

console.log(`\nHazir: versionCode ${versionCode}, ${Object.keys(PLAY_LOCALES).length} dil.`);
