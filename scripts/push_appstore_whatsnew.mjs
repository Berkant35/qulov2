#!/usr/bin/env node
// Sets "What's New in This Version" (whatsNew) on App Store version
// localizations across all configured locales.

import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { createSign } from 'node:crypto';

const KEY_ID = process.env.APP_STORE_API_KEY;
const ISSUER_ID = process.env.APP_STORE_API_ISSUER;
const BUNDLE_ID = process.env.IOS_BUNDLE_ID || 'com.wordpress.calikusuberkant.qulorelease';
const NOTES_FILE = process.argv[2] || 'scripts/testflight_release_notes.json';

if (!KEY_ID || !ISSUER_ID) {
  console.error('Missing env: APP_STORE_API_KEY, APP_STORE_API_ISSUER');
  process.exit(1);
}

const PRIVATE_KEY = readFileSync(`${homedir()}/.private_keys/AuthKey_${KEY_ID}.p8`, 'utf8');
const notes = JSON.parse(readFileSync(NOTES_FILE, 'utf8'));

// ASC locale → notes key fallback
function noteFor(locale) {
  const base = locale.split('-')[0];
  if (notes[base]) return notes[base];
  // English variants → en
  if (locale.startsWith('en')) return notes.en;
  // Czech, Hungarian, etc — no source → English fallback
  return notes.en;
}

function jwt() {
  const b64 = o => Buffer.from(JSON.stringify(o)).toString('base64url');
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

(async () => {
  // 1) App
  const apps = await api(`/apps?filter[bundleId]=${encodeURIComponent(BUNDLE_ID)}&limit=1`);
  const appId = apps.data?.[0]?.id;
  if (!appId) throw new Error(`App not found: ${BUNDLE_ID}`);
  console.log(`App: ${appId}`);

  // 2) En son appStoreVersion (editable bir state'te olmalı)
  const versions = await api(
    `/apps/${appId}/appStoreVersions?limit=20`
  );
  const editableStates = new Set([
    'PREPARE_FOR_SUBMISSION',
    'DEVELOPER_REJECTED',
    'REJECTED',
    'METADATA_REJECTED',
    'WAITING_FOR_REVIEW',
    'INVALID_BINARY',
    'READY_FOR_REVIEW',
  ]);
  const version = versions.data.find(v => editableStates.has(v.attributes.appStoreState))
    || versions.data[0];
  console.log(`Version: ${version.attributes.versionString} (${version.attributes.appStoreState}) id=${version.id}`);

  // 3) Lokalizasyonlar
  const locs = await api(`/appStoreVersions/${version.id}/appStoreVersionLocalizations?limit=200`);
  console.log(`Locales: ${locs.data.length}`);

  for (const loc of locs.data) {
    const locale = loc.attributes.locale;
    const whatsNew = noteFor(locale);
    try {
      await api(`/appStoreVersionLocalizations/${loc.id}`, {
        method: 'PATCH',
        body: JSON.stringify({
          data: {
            type: 'appStoreVersionLocalizations',
            id: loc.id,
            attributes: { whatsNew },
          },
        }),
      });
      console.log(`✓ ${locale}`);
    } catch (e) {
      console.error(`✗ ${locale}: ${e.message}`);
    }
  }
  console.log('Done.');
})().catch(e => { console.error(e); process.exit(1); });