// App Store Connect — "What's New" (release notes) otomatik doldurma.
// Kullanım: APP_STORE_API_ISSUER=... node asc_whatsnew.mjs [--apply]
// --apply olmadan: sadece durum raporu (read-only). --apply ile: PATCH whatsNew.
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';

const KEY_ID = 'B24C75LYRD';
const ISSUER = process.env.APP_STORE_API_ISSUER;
const BUNDLE_ID = 'com.wordpress.calikusuberkant.qulorelease';
const VERSION = '2.0.5';
const APPLY = process.argv.includes('--apply');
const P8_PATH = `${os.homedir()}/private_keys/AuthKey_${KEY_ID}.p8`;

if (!ISSUER) { console.error('APP_STORE_API_ISSUER yok'); process.exit(1); }
const P8 = fs.readFileSync(P8_PATH, 'utf8');

// ES256 JWT
function jwt() {
  const b64 = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const head = b64({ alg: 'ES256', kid: KEY_ID, typ: 'JWT' });
  const body = b64({ iss: ISSUER, iat: now, exp: now + 1100, aud: 'appstoreconnect-v1' });
  const sig = crypto.sign('SHA256', Buffer.from(`${head}.${body}`), { key: P8, dsaEncoding: 'ieee-p1363' }).toString('base64url');
  return `${head}.${body}.${sig}`;
}

const TOKEN = jwt();
const API = 'https://api.appstoreconnect.apple.com';
async function api(path, opts = {}) {
  const res = await fetch(`${API}${path}`, {
    ...opts,
    headers: { Authorization: `Bearer ${TOKEN}`, 'Content-Type': 'application/json', ...(opts.headers || {}) },
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${res.status} ${path}\n${text}`);
  return text ? JSON.parse(text) : {};
}

// App Store Connect locale -> "What's New" metni (16 dil).
const NOTES = {
  'tr': `Uygulama içi rehber turu iyileştirildi — ipuçları artık tam ihtiyacın olan ekranda görünüyor
Davet bağlantılarıyla ilgili düzeltmeler
Hesap silme akışına geri bildirim adımı eklendi — ayrılmadan önce nedenini paylaşabilirsin
Çeşitli hata düzeltmeleri ve performans iyileştirmeleri`,
  'en-US': `Improved in-app guided tour — tips now show up right where you need them
Fixes for invite links
New feedback step when deleting your account — tell us why before you go
Various bug fixes and performance improvements`,
  'de-DE': `Verbesserte In-App-Tour — Tipps erscheinen jetzt genau dort, wo du sie brauchst
Korrekturen bei Einladungslinks
Neuer Feedback-Schritt beim Löschen des Kontos — sag uns vorher, warum du gehst
Diverse Fehlerbehebungen und Leistungsverbesserungen`,
  'fr-FR': `Visite guidée améliorée — les conseils s'affichent désormais exactement là où tu en as besoin
Corrections des liens d'invitation
Nouvelle étape de retour lors de la suppression du compte — dis-nous pourquoi avant de partir
Corrections de bugs et améliorations des performances`,
  'es-ES': `Tour guiado mejorado — los consejos ahora aparecen justo donde los necesitas
Correcciones en los enlaces de invitación
Nuevo paso de comentarios al eliminar tu cuenta — cuéntanos por qué antes de irte
Varias correcciones de errores y mejoras de rendimiento`,
  'ar-SA': `تحسين الجولة الإرشادية داخل التطبيق — تظهر التلميحات الآن في المكان الذي تحتاجها فيه تمامًا
إصلاحات لروابط الدعوة
خطوة ملاحظات جديدة عند حذف الحساب — أخبرنا بالسبب قبل المغادرة
إصلاحات متنوعة للأخطاء وتحسينات في الأداء`,
  'ru': `Улучшен обучающий тур — подсказки теперь появляются именно там, где нужно
Исправления пригласительных ссылок
Новый шаг обратной связи при удалении аккаунта — расскажите нам причину перед уходом
Различные исправления ошибок и улучшения производительности`,
  'pt-PT': `Tour guiado aprimorado — as dicas agora aparecem exatamente onde você precisa
Correções nos links de convite
Nova etapa de feedback ao excluir a conta — conte-nos o motivo antes de sair
Diversas correções de bugs e melhorias de desempenho`,
  'it': `Tour guidato migliorato — i suggerimenti ora appaiono esattamente dove ti servono
Correzioni ai link di invito
Nuovo passaggio di feedback all'eliminazione dell'account — dicci il motivo prima di andare
Varie correzioni di bug e miglioramenti delle prestazioni`,
  'ja': `アプリ内ガイドツアーを改善 — ヒントが必要な画面に正しく表示されるようになりました
招待リンクに関する修正
アカウント削除時に新しいフィードバックステップを追加 — 退会前に理由をお聞かせください
各種バグ修正とパフォーマンス改善`,
  'ko': `앱 내 가이드 투어 개선 — 이제 팁이 필요한 화면에 정확히 표시됩니다
초대 링크 관련 수정
계정 삭제 시 새로운 피드백 단계 추가 — 떠나기 전에 이유를 알려주세요
다양한 버그 수정 및 성능 개선`,
  'zh-Hans': `改进了应用内引导教程 — 提示现在会准确显示在你需要的界面上
修复了邀请链接相关问题
删除账号时新增反馈步骤 — 离开前告诉我们原因
各种错误修复和性能优化`,
  'nl-NL': `Verbeterde rondleiding in de app — tips verschijnen nu precies waar je ze nodig hebt
Fixes voor uitnodigingslinks
Nieuwe feedbackstap bij het verwijderen van je account — vertel ons waarom voordat je gaat
Diverse bugfixes en prestatieverbeteringen`,
  'pl': `Ulepszony samouczek w aplikacji — wskazówki pojawiają się teraz dokładnie tam, gdzie ich potrzebujesz
Poprawki linków z zaproszeniami
Nowy krok opinii przy usuwaniu konta — powiedz nam dlaczego, zanim odejdziesz
Różne poprawki błędów i ulepszenia wydajności`,
  'sv': `Förbättrad guidad tur i appen — tips visas nu precis där du behöver dem
Fixar för inbjudningslänkar
Nytt feedbacksteg när du raderar ditt konto — berätta varför innan du går
Diverse buggfixar och prestandaförbättringar`,
  'hi': `इन-ऐप गाइडेड टूर बेहतर हुआ — सुझाव अब ठीक वहीं दिखते हैं जहाँ आपको चाहिए
आमंत्रण लिंक से जुड़े सुधार
खाता हटाते समय नया फ़ीडबैक चरण — जाने से पहले हमें कारण बताएं
विभिन्न बग समाधान और प्रदर्शन सुधार`,
};

// App Store Connect submit için zorunlu ek diller:
NOTES['en-AU'] = NOTES['en-CA'] = NOTES['en-GB'] = NOTES['en-US'];
NOTES['pt-BR'] = NOTES['pt-PT'];
NOTES['cs'] = `Vylepšená průvodcovská prohlídka v aplikaci — tipy se nyní zobrazují přesně tam, kde je potřebujete.\nOpravy odkazů s pozvánkami.\nNový krok zpětné vazby při mazání účtu — řekněte nám proč, než odejdete.\nRůzné opravy chyb a vylepšení výkonu.`;
NOTES['hu'] = `Továbbfejlesztett alkalmazáson belüli túra — a tippek mostantól pontosan ott jelennek meg, ahol szükséged van rájuk.\nMeghívó linkek javításai.\nÚj visszajelzési lépés a fiók törlésekor — mondd el, miért mész el, mielőtt távozol.\nKülönféle hibajavítások és teljesítményjavítások.`;

const app = (await api(`/v1/apps?filter[bundleId]=${BUNDLE_ID}`)).data?.[0];
if (!app) throw new Error('App bulunamadı');
console.log(`App: ${app.attributes.name} (${app.id})`);

const versions = (await api(`/v1/apps/${app.id}/appStoreVersions?filter[versionString]=${VERSION}&limit=5`)).data;
const editableStates = ['PREPARE_FOR_SUBMISSION', 'DEVELOPER_REJECTED', 'REJECTED', 'METADATA_REJECTED', 'INVALID_BINARY', 'WAITING_FOR_REVIEW'];
let ver = versions.find((v) => editableStates.includes(v.attributes.appStoreState));
console.log(`Sürüm ${VERSION}: ${versions.map((v) => v.attributes.appStoreState).join(', ') || 'YOK'}`);

if (!ver) {
  if (!APPLY) { console.log('Editable sürüm yok. --apply ile yeni 2.0.4 sürümü oluşturulur.'); process.exit(0); }
  console.log('Editable sürüm yok → yeni 2.0.4 (IOS) oluşturuluyor...');
  ver = (await api('/v1/appStoreVersions', {
    method: 'POST',
    body: JSON.stringify({ data: { type: 'appStoreVersions', attributes: { platform: 'IOS', versionString: VERSION }, relationships: { app: { data: { type: 'apps', id: app.id } } } } }),
  })).data;
  console.log(`Oluşturuldu: ${ver.id} (${ver.attributes.appStoreState})`);
}

const locs = (await api(`/v1/appStoreVersions/${ver.id}/appStoreVersionLocalizations?limit=50`)).data;
console.log(`Mevcut diller (${locs.length}): ${locs.map((l) => l.attributes.locale).join(', ')}`);

let updated = 0, skipped = [];
for (const loc of locs) {
  const locale = loc.attributes.locale;
  const text = NOTES[locale];
  if (!text) { skipped.push(locale); continue; }
  if (APPLY) {
    await api(`/v1/appStoreVersionLocalizations/${loc.id}`, {
      method: 'PATCH',
      body: JSON.stringify({ data: { type: 'appStoreVersionLocalizations', id: loc.id, attributes: { whatsNew: text } } }),
    });
    updated++;
  }
}
console.log(APPLY ? `✓ Güncellenen dil: ${updated}` : `Eşleşen dil: ${locs.filter((l) => NOTES[l.attributes.locale]).length}/${locs.length}`);
if (skipped.length) console.log(`Çeviri yok (atlanır): ${skipped.join(', ')}`);
