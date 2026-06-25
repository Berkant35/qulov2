#!/usr/bin/env node
// Pushes "What to Test" release notes to TestFlight in 16 languages
// via App Store Connect API.
//
// Requires: APP_STORE_API_KEY, APP_STORE_API_ISSUER env vars
// Key file: ~/.private_keys/AuthKey_<KEYID>.p8

import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { createSign } from 'node:crypto';

const KEY_ID = process.env.APP_STORE_API_KEY;
const ISSUER_ID = process.env.APP_STORE_API_ISSUER;
const BUNDLE_ID = process.env.IOS_BUNDLE_ID || 'com.qulo.app';
const VERSION = process.env.IOS_VERSION;
const BUILD_NUMBER = process.env.IOS_BUILD_NUMBER;
const NOTES_FILE = process.argv[2] || 'scripts/testflight_release_notes.json';

if (!KEY_ID || !ISSUER_ID || !VERSION || !BUILD_NUMBER) {
  console.error('Missing env: APP_STORE_API_KEY, APP_STORE_API_ISSUER, IOS_VERSION, IOS_BUILD_NUMBER');
  process.exit(1);
}

const KEY_PATH = `${homedir()}/.private_keys/AuthKey_${KEY_ID}.p8`;
const PRIVATE_KEY = readFileSync(KEY_PATH, 'utf8');

// 16 dil → TestFlight locale eşleştirmesi
const LOCALE_MAP = {
  ar: 'ar-SA', de: 'de-DE', en: 'en-US', es: 'es-ES',
  fr: 'fr-FR', hi: 'hi',   it: 'it',    ja: 'ja',
  ko: 'ko',    nl: 'nl-NL', pl: 'pl',   pt: 'pt-BR',
  ru: 'ru',    sv: 'sv',   tr: 'tr',    zh: 'zh-Hans',
};

const notes = JSON.parse(readFileSync(NOTES_FILE, 'utf8'));

function jwt() {
  const header = { alg: 'ES256', kid: KEY_ID, typ: 'JWT' };
  const payload = {
    iss: ISSUER_ID,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + 20 * 60,
    aud: 'appstoreconnect-v1',
  };
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const signing = `${b64(header)}.${b64(payload)}`;
  const signer = createSign('SHA256');
  signer.update(signing);
  const sig = signer.sign({ key: PRIVATE_KEY, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  return `${signing}.${sig}`;
}

const TOKEN = jwt();
const API = 'https://api.appstoreconnect.apple.com/v1';

async function api(path, opts = {}) {
  const res = await fetch(`${API}${path}`, {
    ...opts,
    headers: {
      Authorization: `Bearer ${TOKEN}`,
      'Content-Type': 'application/json',
      ...(opts.headers || {}),
    },
  });
  const text = await res.text();
  let body;
  try { body = JSON.parse(text); } catch { body = text; }
  if (!res.ok) {
    throw new Error(`${opts.method || 'GET'} ${path} → ${res.status}\n${JSON.stringify(body, null, 2)}`);
  }
  return body;
}

async function findApp() {
  const r = await api(`/apps?filter[bundleId]=${encodeURIComponent(BUNDLE_ID)}&limit=1`);
  if (!r.data?.length) throw new Error(`App not found for bundleId=${BUNDLE_ID}`);
  return r.data[0].id;
}

async function findBuild(appId) {
  // Poll until build appears and finishes processing
  const maxMin = 25;
  const deadline = Date.now() + maxMin * 60 * 1000;
  while (Date.now() < deadline) {
    const r = await api(
      `/builds?filter[app]=${appId}&filter[preReleaseVersion.version]=${VERSION}` +
      `&filter[version]=${BUILD_NUMBER}&limit=1`
    );
    const b = r.data?.[0];
    if (b) {
      const state = b.attributes?.processingState;
      console.log(`Build ${VERSION}(${BUILD_NUMBER}) → ${state}`);
      if (state === 'VALID') return b.id;
      if (state === 'FAILED' || state === 'INVALID') throw new Error(`Build processing ${state}`);
    } else {
      console.log(`Build ${VERSION}(${BUILD_NUMBER}) not visible yet, waiting…`);
    }
    await new Promise(r => setTimeout(r, 30_000));
  }
  throw new Error('Timed out waiting for build processing');
}

async function listLocalizations(buildId) {
  const r = await api(`/builds/${buildId}/betaBuildLocalizations?limit=200`);
  const map = new Map();
  for (const d of r.data || []) map.set(d.attributes.locale, d.id);
  return map;
}

async function upsertNote(buildId, existingMap, locale, whatsNew) {
  if (existingMap.has(locale)) {
    const id = existingMap.get(locale);
    await api(`/betaBuildLocalizations/${id}`, {
      method: 'PATCH',
      body: JSON.stringify({
        data: { type: 'betaBuildLocalizations', id, attributes: { whatsNew } },
      }),
    });
  } else {
    await api(`/betaBuildLocalizations`, {
      method: 'POST',
      body: JSON.stringify({
        data: {
          type: 'betaBuildLocalizations',
          attributes: { locale, whatsNew },
          relationships: { build: { data: { type: 'builds', id: buildId } } },
        },
      }),
    });
  }
}

(async () => {
  const appId = await findApp();
  console.log(`App id: ${appId}`);
  const buildId = await findBuild(appId);
  console.log(`Build id: ${buildId}`);
  const existing = await listLocalizations(buildId);

  for (const [lang, text] of Object.entries(notes)) {
    const locale = LOCALE_MAP[lang];
    if (!locale) { console.warn(`No locale map for ${lang}`); continue; }
    try {
      await upsertNote(buildId, existing, locale, text);
      console.log(`✓ ${lang} → ${locale}`);
    } catch (e) {
      console.error(`✗ ${lang} → ${locale}: ${e.message}`);
    }
  }
  console.log('Done.');
})().catch(e => { console.error(e); process.exit(1); });