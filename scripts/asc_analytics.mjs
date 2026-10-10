#!/usr/bin/env node
// App Store Connect Analytics Reports API — "App Store Discovery and Engagement" raporu.
//
// NEDEN: Apple anahtar kelime bazli veri vermiyor; ASO icin elimizdeki en iyi resmi
// sinyal kaynak turune (App Store Search / Browse / Web Referrer ...) gore gosterim,
// sayfa goruntuleme ve indirmedir. Bu rapor onu gunluk verir.
//
// Kullanim (qulov2/ kokunden):
//   node --env-file=.env scripts/asc_analytics.mjs status            # istekler + raporlar
//   node --env-file=.env scripts/asc_analytics.mjs request           # ONGOING + ONE_TIME_SNAPSHOT ac (yoksa)
//   node --env-file=.env scripts/asc_analytics.mjs fetch [gun=30]    # indir + kaynak turune gore ozet
//
// Not: Istegi ilk kez acmak Admin rolu ister. Ilk veri 24-48 saatte gelir.

import { readFileSync, mkdirSync, writeFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { createSign } from 'node:crypto';
import { gunzipSync } from 'node:zlib';

const KEY_ID = process.env.APP_STORE_API_KEY;
const ISSUER_ID = process.env.APP_STORE_API_ISSUER;
const BUNDLE_ID = process.env.IOS_BUNDLE_ID || 'com.wordpress.calikusuberkant.qulorelease';
const REPORT_NAME = 'App Store Discovery and Engagement Standard';
const OUT_DIR = 'build/asc_analytics';

if (!KEY_ID || !ISSUER_ID) {
  console.error('Eksik env: APP_STORE_API_KEY, APP_STORE_API_ISSUER (node --env-file=.env ...)');
  process.exit(2);
}

const PRIVATE_KEY = readFileSync(`${homedir()}/.private_keys/AuthKey_${KEY_ID}.p8`, 'utf8');

function jwt() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const header = b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' });
  const payload = b64({ iss: ISSUER_ID, iat: now, exp: now + 20 * 60, aud: 'appstoreconnect-v1' });
  const signer = createSign('SHA256');
  signer.update(`${header}.${payload}`);
  const sig = signer.sign({ key: PRIVATE_KEY, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  return `${header}.${payload}.${sig}`;
}

const token = jwt();
async function api(path, init = {}) {
  const url = path.startsWith('http') ? path : `https://api.appstoreconnect.apple.com/v1${path}`;
  const res = await fetch(url, {
    ...init,
    headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json', ...init.headers },
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${path} → ${res.status}\n${text}`);
  return text ? JSON.parse(text) : {};
}

async function all(path) {
  const out = [];
  for (let next = path; next; ) {
    const page = await api(next);
    out.push(...page.data);
    next = page.links?.next;
  }
  return out;
}

async function appId() {
  const apps = await api(`/apps?filter[bundleId]=${encodeURIComponent(BUNDLE_ID)}&limit=1`);
  const id = apps.data?.[0]?.id;
  if (!id) throw new Error(`Uygulama bulunamadi: ${BUNDLE_ID}`);
  return id;
}

const requestsOf = (id) => all(`/apps/${id}/analyticsReportRequests`);

async function discoveryReports(requestId) {
  return all(`/analyticsReportRequests/${requestId}/reports?filter[category]=APP_STORE_ENGAGEMENT`);
}

async function status() {
  const id = await appId();
  const requests = await requestsOf(id);
  if (!requests.length) return console.log('Hic rapor istegi yok — `request` calistir.');
  for (const r of requests) {
    const a = r.attributes;
    console.log(`\n${a.accessType}  id=${r.id}  stoppedDueToInactivity=${a.stoppedDueToInactivity}`);
    for (const rep of await discoveryReports(r.id)) {
      const inst = await all(`/analyticsReports/${rep.id}/instances?limit=200`);
      const dates = inst.map((i) => i.attributes.processingDate).sort();
      console.log(`  ${rep.attributes.name}: ${inst.length} instance` +
        (dates.length ? ` (${dates[0]} → ${dates.at(-1)})` : ''));
    }
  }
}

async function request() {
  const id = await appId();
  const existing = new Set((await requestsOf(id))
    .filter((r) => !r.attributes.stoppedDueToInactivity)
    .map((r) => r.attributes.accessType));
  for (const accessType of ['ONGOING', 'ONE_TIME_SNAPSHOT']) {
    if (existing.has(accessType)) {
      console.log(`${accessType}: zaten var`);
      continue;
    }
    const body = {
      data: {
        type: 'analyticsReportRequests',
        attributes: { accessType },
        relationships: { app: { data: { type: 'apps', id } } },
      },
    };
    const res = await api('/analyticsReportRequests', { method: 'POST', body: JSON.stringify(body) });
    console.log(`${accessType}: acildi id=${res.data.id}`);
  }
}

async function download(reportId) {
  let header;
  const rows = [];
  const inst = await all(`/analyticsReports/${reportId}/instances?filter[granularity]=DAILY&limit=200`);
  for (const i of inst) {
    for (const seg of await all(`/analyticsReportInstances/${i.id}/segments`)) {
      const gz = Buffer.from(await (await fetch(seg.attributes.url)).arrayBuffer());
      const lines = gunzipSync(gz).toString('utf8').trim().split('\n');
      header ??= lines[0].split('\t');
      rows.push(...lines.slice(1).map((l) => l.split('\t')));
    }
  }
  return { header, rows };
}

// Snapshot gecmisi de icerir; satirlar kendi `Date` alanina gore suzulur. Bir gun
// ONGOING'de varsa snapshot'taki kopyasi atlanir (cift sayim olmasin).
async function fetchRows(days) {
  const id = await appId();
  const since = new Date(Date.now() - days * 86400e3).toISOString().slice(0, 10);
  const order = { ONGOING: 0, ONE_TIME_SNAPSHOT: 1 };
  const requests = (await requestsOf(id))
    .sort((a, b) => order[a.attributes.accessType] - order[b.attributes.accessType]);
  const covered = new Set();
  const rows = [];
  let header;
  for (const r of requests) {
    const rep = (await discoveryReports(r.id)).find((x) => x.attributes.name === REPORT_NAME);
    if (!rep) continue;
    const part = await download(rep.id);
    if (!part.header) continue;
    header ??= part.header;
    const iDate = header.indexOf('Date');
    const fresh = part.rows.filter((row) => row[iDate] >= since && !covered.has(row[iDate]));
    fresh.forEach((row) => covered.add(row[iDate]));
    rows.push(...fresh);
  }
  return { header, rows };
}

async function fetchCmd(days) {
  const { header, rows } = await fetchRows(days);
  if (!rows.length) return console.log('Henuz veri yok (istekten sonra 24-48 saat bekle).');
  mkdirSync(OUT_DIR, { recursive: true });
  const file = `${OUT_DIR}/discovery_${days}d.tsv`;
  writeFileSync(file, [header, ...rows].map((r) => r.join('\t')).join('\n'));

  const col = (n) => header.indexOf(n);
  const [iSrc, iEvent, iCount] = [col('Source Type'), col('Event'), col('Counts')];
  const table = {};
  for (const r of rows) {
    const t = (table[r[iSrc]] ??= {});
    t[r[iEvent]] = (t[r[iEvent]] ?? 0) + Number(r[iCount] || 0);
  }
  const events = [...new Set(rows.map((r) => r[iEvent]))].sort();
  console.log(`Son ${days} gun, kaynak turune gore (${rows.length} satir → ${file})\n`);
  console.log(['Source Type', ...events].join('\t'));
  for (const [src, t] of Object.entries(table).sort()) {
    console.log([src, ...events.map((e) => t[e] ?? 0)].join('\t'));
  }
}

const [cmd, arg] = process.argv.slice(2);
const commands = { status, request, fetch: () => fetchCmd(Number(arg) || 30) };
if (!commands[cmd]) {
  console.error('Kullanim: asc_analytics.mjs status | request | fetch [gun]');
  process.exit(2);
}
await commands[cmd]();
