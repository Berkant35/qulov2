// App Store Connect — "What's New" (release notes) otomatik doldurma.
// Kullanım: APP_STORE_API_ISSUER=... node asc_whatsnew.mjs [--apply]
// --apply olmadan: sadece durum raporu (read-only). --apply ile: PATCH whatsNew.
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';

const KEY_ID = 'B24C75LYRD';
const ISSUER = process.env.APP_STORE_API_ISSUER;
const BUNDLE_ID = 'com.wordpress.calikusuberkant.qulorelease';
const VERSION = '2.0.4';
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
  'tr': `Keşfette artık profiller otomatik yükleniyor — kesintisiz keşfet, "tekrar ara" derdi yok.\n"Bizi nereden duydun?" — bizi nasıl bulduğunu paylaşabilirsin.\nDaha akıcı ipucu ve bildirim deneyimi; üst üste binen pop-up'lar giderildi.\nÇeşitli hata düzeltmeleri ve performans iyileştirmeleri.`,
  'en-US': `Discover now loads profiles automatically — keep exploring, no more "search again".\n"How did you hear about us?" — tell us how you found Qulo.\nSmoother tips and notifications; overlapping pop-ups are gone.\nVarious bug fixes and performance improvements.`,
  'de-DE': `Entdecken lädt Profile jetzt automatisch – einfach weiterstöbern, kein "Erneut suchen" mehr.\n"Wie hast du von uns erfahren?" – sag uns, wie du Qulo gefunden hast.\nFlüssigere Tipps und Benachrichtigungen; überlappende Pop-ups wurden behoben.\nDiverse Fehlerbehebungen und Leistungsverbesserungen.`,
  'fr-FR': `Découvrir charge désormais les profils automatiquement — continue d'explorer, fini le « rechercher à nouveau ».\n« Comment avez-vous entendu parler de nous ? » — dis-nous comment tu as trouvé Qulo.\nConseils et notifications plus fluides ; les pop-ups qui se chevauchaient ont été corrigés.\nCorrections de bugs et améliorations des performances.`,
  'es-ES': `Descubrir ahora carga los perfiles automáticamente: sigue explorando, sin más "buscar de nuevo".\n"¿Cómo nos conociste?": cuéntanos cómo encontraste Qulo.\nConsejos y notificaciones más fluidos; se eliminaron los pop-ups superpuestos.\nVarias correcciones de errores y mejoras de rendimiento.`,
  'ar-SA': `أصبح "اكتشف" يحمّل الملفات تلقائيًا — تابع الاستكشاف دون "البحث مجددًا".\n"كيف سمعت عنّا؟" — أخبرنا كيف وجدت Qulo.\nتلميحات وإشعارات أكثر سلاسة، وتم إصلاح النوافذ المنبثقة المتداخلة.\nإصلاحات متنوعة للأخطاء وتحسينات في الأداء.`,
  'ru': `В «Обзоре» профили теперь загружаются автоматически — продолжайте смотреть, без «искать снова».\n«Откуда вы о нас узнали?» — расскажите, как вы нашли Qulo.\nБолее плавные подсказки и уведомления; перекрывающиеся всплывающие окна исправлены.\nРазличные исправления ошибок и улучшения производительности.`,
  'pt-PT': `A aba Descobrir agora carrega perfis automaticamente — continue a explorar, sem "procurar novamente".\n"Como ouviu falar de nós?" — conte-nos como encontrou o Qulo.\nDicas e notificações mais fluidas; pop-ups sobrepostos foram corrigidos.\nVárias correções de erros e melhorias de desempenho.`,
  'it': `Scopri ora carica i profili automaticamente — continua a esplorare, niente più "cerca di nuovo".\n"Come ci hai conosciuti?" — raccontaci come hai trovato Qulo.\nSuggerimenti e notifiche più fluidi; i pop-up sovrapposti sono stati risolti.\nVarie correzioni di bug e miglioramenti delle prestazioni.`,
  'ja': `「見つける」がプロフィールを自動で読み込むようになりました。「再検索」なしでそのまま探せます。\n「どこで私たちを知りましたか？」— Quloをどう見つけたか教えてください。\nヒントや通知がよりスムーズに。重なって表示されるポップアップを修正しました。\n各種不具合の修正とパフォーマンスの改善。`,
  'ko': `'탐색'에서 이제 프로필이 자동으로 로드됩니다 — '다시 찾기' 없이 계속 둘러보세요.\n"저희를 어떻게 알게 되셨나요?" — Qulo를 어떻게 찾으셨는지 알려주세요.\n팁과 알림이 더 매끄러워졌고, 겹쳐 보이던 팝업을 수정했습니다.\n다양한 버그 수정 및 성능 개선.`,
  'zh-Hans': `"发现"现在会自动加载资料——尽情浏览，无需再"重新搜索"。\n"你是怎么知道我们的？"——告诉我们你是如何找到 Qulo 的。\n提示和通知更顺畅，修复了相互重叠的弹窗。\n多项错误修复和性能改进。`,
  'nl-NL': `Ontdekken laadt nu profielen automatisch — blijf ontdekken, geen "opnieuw zoeken" meer.\n"Hoe heb je over ons gehoord?" — vertel ons hoe je Qulo hebt gevonden.\nSoepelere tips en meldingen; overlappende pop-ups zijn opgelost.\nDiverse bugfixes en prestatieverbeteringen.`,
  'pl': `Odkrywaj teraz wczytuje profile automatycznie — przeglądaj dalej, koniec z "szukaj ponownie".\n"Skąd o nas wiesz?" — powiedz nam, jak trafiłeś do Qulo.\nPłynniejsze wskazówki i powiadomienia; nakładające się wyskakujące okienka naprawione.\nRóżne poprawki błędów i ulepszenia wydajności.`,
  'sv': `Upptäck laddar nu profiler automatiskt — fortsätt utforska, inget mer "sök igen".\n"Hur hörde du talas om oss?" — berätta hur du hittade Qulo.\nSmidigare tips och aviseringar; överlappande popup-fönster har åtgärdats.\nDiverse buggfixar och prestandaförbättringar.`,
  'hi': `डिस्कवर अब प्रोफ़ाइल अपने आप लोड करता है — बिना "फिर से खोजें" के एक्सप्लोर करते रहें।\n"आपने हमारे बारे में कैसे सुना?" — बताएं कि आपने Qulo को कैसे खोजा।\nसहज सुझाव और सूचनाएं; एक-दूसरे पर आते पॉप-अप ठीक किए गए।\nविभिन्न बग फिक्स और प्रदर्शन सुधार।`,
};

// App Store Connect submit için zorunlu ek diller:
NOTES['en-AU'] = NOTES['en-CA'] = NOTES['en-GB'] = NOTES['en-US'];
NOTES['pt-BR'] = NOTES['pt-PT'];
NOTES['cs'] = `Objevování teď načítá profily automaticky — prozkoumávejte dál, žádné „hledat znovu".\n„Jak jste se o nás dozvěděli?" — řekněte nám, jak jste našli Qulo.\nPlynulejší tipy a oznámení; překrývající se vyskakovací okna jsou opravena.\nRůzné opravy chyb a vylepšení výkonu.`;
NOTES['hu'] = `A Felfedezés mostantól automatikusan tölti be a profilokat — fedezz fel tovább, nincs több „újrakeresés".\n„Honnan hallottál rólunk?" — mondd el, hogyan találtad meg a Qulót.\nGördülékenyebb tippek és értesítések; az egymásra csúszó felugró ablakok javítva.\nKülönféle hibajavítások és teljesítményjavítások.`;

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
