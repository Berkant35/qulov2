// App Store Connect — keyword (ASO) güncelleme + mevcut yedekleme.
// Kullanım: APP_STORE_API_ISSUER=... node asc_keywords.mjs [--apply]
// --apply olmadan: mevcut keywords/name/subtitle raporu + yedek (read-only).
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';

const KEY_ID = 'B24C75LYRD';
const ISSUER = process.env.APP_STORE_API_ISSUER;
const BUNDLE_ID = 'com.wordpress.calikusuberkant.qulorelease';
const VERSION = '2.0.4';
const APPLY = process.argv.includes('--apply');
const P8 = fs.readFileSync(`${os.homedir()}/private_keys/AuthKey_${KEY_ID}.p8`, 'utf8');
if (!ISSUER) { console.error('APP_STORE_API_ISSUER yok'); process.exit(1); }

function jwt() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const head = b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' });
  const body = b64({ iss: ISSUER, iat: now, exp: now + 1100, aud: 'appstoreconnect-v1' });
  const sig = crypto.sign('SHA256', Buffer.from(`${head}.${body}`), { key: P8, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  return `${head}.${body}.${sig}`;
}
const TOKEN = jwt();
async function api(path, opts = {}) {
  const res = await fetch(`https://api.appstoreconnect.apple.com${path}`, {
    ...opts, headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json', ...(opts.headers || {}) },
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${res.status} ${path}\n${text}`);
  return text ? JSON.parse(text) : {};
}

// Optimize keyword setleri — virgülle ayrık, BOŞLUKSUZ (boşluk char harcar),
// ≤100 char. App adı/subtitle'daki kelimeler (Qulo, meet, questions) TEKRAR yok.
const EN = 'dating,chat,singles,match,love,flirt,relationship,date,romance,quiz,personality,friends';
const PT = 'namoro,chat,solteiros,amor,paquera,relacionamento,encontros,conhecer,quiz,amizade,romance';
const K = {
  'en-US': EN, 'en-GB': EN, 'en-AU': EN, 'en-CA': EN,
  'tr': 'arkadaşlık,sohbet,flört,tanışma,aşk,ilişki,bekar,buluşma,sevgili,uyumluluk,test,arkadaş',
  'de-DE': 'dating,flirten,chat,singles,partner,liebe,beziehung,kennenlernen,verlieben,quiz,freunde',
  'fr-FR': 'rencontre,chat,célibataire,amour,flirt,relation,séduction,rendez-vous,quiz,amitié,couple',
  'es-ES': 'citas,chat,solteros,amor,ligar,relación,pareja,conocer,coquetear,quiz,amistad,romance',
  'it': 'incontri,chat,single,amore,flirt,relazione,appuntamenti,conoscere,quiz,amicizia,romantico',
  'nl-NL': 'dating,chat,singles,liefde,flirten,relatie,daten,ontmoeten,quiz,vriendschap,romantiek',
  'sv': 'dejting,chatt,singlar,kärlek,flörta,relation,dejt,träffa,quiz,vänskap,romantik,par',
  'pl': 'randki,czat,single,miłość,flirt,związek,poznać,spotkania,quiz,przyjaźń,romans,para',
  'cs': 'seznamka,chat,láska,vztah,flirt,rande,poznat,kvíz,přátelství,romantika,partner,single',
  'hu': 'társkereső,chat,szerelem,kapcsolat,flört,szingli,randi,ismerkedés,kvíz,barátság,romantika',
  'ru': 'знакомства,чат,любовь,отношения,флирт,свидания,одиночки,дружба,пара,тест,роман,встречи',
  'pt-PT': PT, 'pt-BR': PT,
  'ar-SA': 'تعارف,زواج,حب,مسلم,حلال,دردشة,علاقة,مواعدة,عزاب,شريك,صداقة,اختبار',
  'ja': '出会い,チャット,恋愛,マッチング,デート,婚活,恋人,友達,相性,診断,恋活,出会い系',
  'ko': '데이팅,채팅,소개팅,연애,만남,사랑,싱글,친구,궁합,소개,연인,데이트',
  'zh-Hans': '约会,聊天,交友,单身,恋爱,脱单,缘分,配对,测试,情侣,相亲,浪漫',
  'hi': 'shaadi,rishta,desi,डेटिंग,चैट,प्यार,सिंगल,मुलाकात,रोमांस,दोस्ती,जोड़ी,प्रेम',
};

const app = (await api(`/v1/apps?filter[bundleId]=${BUNDLE_ID}`)).data?.[0];
console.log(`App: ${app.attributes.name} (${app.id})`);
const versions = (await api(`/v1/apps/${app.id}/appStoreVersions?filter[versionString]=${VERSION}&limit=5`)).data;
const editable = ['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED', 'INVALID_BINARY', 'WAITING_FOR_REVIEW'];
const ver = versions.find((v) => editable.includes(v.attributes.appStoreState));
if (!ver) { console.error(`Editable ${VERSION} sürümü yok (${versions.map(v=>v.attributes.appStoreState).join(',')})`); process.exit(1); }

const locs = (await api(`/v1/appStoreVersions/${ver.id}/appStoreVersionLocalizations?limit=50`)).data;
const backup = {};
let updated = 0; const noPlan = [];
for (const loc of locs) {
  const { locale, name, subtitle, keywords } = loc.attributes;
  backup[locale] = { name, subtitle, keywords };
  const next = K[locale];
  if (!next) { noPlan.push(locale); continue; }
  const len = [...next].length; // unicode-aware length (Apple 100-char limit)
  const flag = len > 100 ? ' ⚠️>100' : '';
  console.log(`${locale}: (${len})${flag}\n   eski: ${keywords || '(boş)'}\n   yeni: ${next}`);
  if (APPLY && len <= 100) {
    await api(`/v1/appStoreVersionLocalizations/${loc.id}`, {
      method: 'PATCH',
      body: JSON.stringify({ data: { type: 'appStoreVersionLocalizations', id: loc.id, attributes: { keywords: next } } }),
    });
    updated++;
  }
}
fs.writeFileSync(new URL('./asc_keywords_backup.json', import.meta.url), JSON.stringify(backup, null, 2));
console.log(`\nYedek yazıldı: scripts/asc_keywords_backup.json`);
console.log(APPLY ? `✓ Güncellenen dil: ${updated}` : `(read-only — --apply ile yazılır)`);
if (noPlan.length) console.log(`Plan yok (dokunulmadı): ${noPlan.join(', ')}`);
