#!/usr/bin/env node
// Play Console track durumu (internal + production) — salt okunur.
//
// NEDEN: `fastlane run google_play_track_version_codes` ciktisi changelog spam'inda
// kayboluyor; her magaza adimindan once/sonra track'leri API'den dogrudan okumak gerekiyor
// (2.0.11'de kullanici Console'dan taslagi canliya cekmisti, fastlane fark etmedi).
// Kullanim: node scripts/play_tracks.mjs [internal production ...]
import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import crypto from 'node:crypto';

const PACKAGE = 'com.wordpress.calikusuberkant.qulo';
const KEY_PATH = process.env.PLAY_SERVICE_ACCOUNT_JSON || `${homedir()}/private_keys/qulo-play-service-account.json`;
const TRACKS = process.argv.slice(2).length ? process.argv.slice(2) : ['internal', 'production'];

const sa = JSON.parse(readFileSync(KEY_PATH, 'utf8'));
const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const now = Math.floor(Date.now() / 1000);
const unsigned = `${b64({ alg: 'RS256', typ: 'JWT' })}.${b64({
  iss: sa.client_email, scope: 'https://www.googleapis.com/auth/androidpublisher',
  aud: 'https://oauth2.googleapis.com/token', iat: now, exp: now + 600,
})}`;
const assertion = `${unsigned}.${crypto.sign('RSA-SHA256', Buffer.from(unsigned), sa.private_key).toString('base64url')}`;
const tok = await (await fetch('https://oauth2.googleapis.com/token', {
  method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  body: new URLSearchParams({ grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer', assertion }),
})).json();
if (!tok.access_token) throw new Error(`Play token alinamadi: ${JSON.stringify(tok)}`);

const base = `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}`;
const headers = { Authorization: `Bearer ${tok.access_token}`, 'Content-Type': 'application/json' };
const edit = await (await fetch(`${base}/edits`, { method: 'POST', headers })).json();
if (!edit.id) throw new Error(`Edit acilamadi: ${JSON.stringify(edit)}`);
try {
  for (const track of TRACKS) {
    const res = await fetch(`${base}/edits/${edit.id}/tracks/${track}`, { headers });
    const data = await res.json();
    if (!res.ok) { console.log(`${track}: HATA ${res.status} ${JSON.stringify(data).slice(0, 200)}`); continue; }
    const rel = (data.releases ?? []).map((r) =>
      `${(r.versionCodes ?? []).join('/')} ${r.status}${r.name ? ` (${r.name})` : ''}${r.userFraction ? ` %${Math.round(r.userFraction * 100)}` : ''}`);
    console.log(`${track}: ${rel.length ? rel.join(' | ') : '(bos)'}`);
  }
} finally {
  await fetch(`${base}/edits/${edit.id}`, { method: 'DELETE', headers }).catch(() => {});
}
