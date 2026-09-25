// Play listings push — docs/marketing/aso-2026-09/play-listing-drafts/ taslaklarını Play'e yazar.
// Varsayılan KURU ÇALIŞMA (edit silinir); `node play_listings_push.mjs --apply` ile commit.
// Çalışma dizinine play_listings_backup_<tarih>.json yedeği yazar.
// Yönetilen yayınlama AÇIK: commit → Google incelemesi → Play Console > Yayın özeti > Yayınla.
import fs from 'node:fs'; import crypto from 'node:crypto'; import os from 'node:os'; import path from 'node:path';
const APPLY=process.argv.includes('--apply');
const key=JSON.parse(fs.readFileSync(`${os.homedir()}/private_keys/qulo-play-service-account.json`,'utf8'));
const PACKAGE='com.wordpress.calikusuberkant.qulo';
const DRAFTS='/Users/berkantcalikusu/IdeaProjects/qulo/docs/marketing/aso-2026-09/play-listing-drafts';
const b64=o=>Buffer.from(JSON.stringify(o)).toString('base64url'); const now=Math.floor(Date.now()/1000);
const u=`${b64({alg:'RS256',typ:'JWT'})}.${b64({iss:key.client_email,scope:'https://www.googleapis.com/auth/androidpublisher',aud:'https://oauth2.googleapis.com/token',iat:now,exp:now+3600})}`;
const sig=crypto.sign('RSA-SHA256',Buffer.from(u),key.private_key).toString('base64url');
const tok=await (await fetch('https://oauth2.googleapis.com/token',{method:'POST',headers:{'content-type':'application/x-www-form-urlencoded'},body:`grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${u}.${sig}`})).json();
const H={authorization:`Bearer ${tok.access_token}`,'content-type':'application/json'};
const base=`https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${PACKAGE}`;
const parse=f=>{const s=fs.readFileSync(path.join(DRAFTS,f),'utf8');const title=s.match(/## title[^\n]*\n(.+)\n/)[1].trim();const short=s.match(/## short_description[^\n]*\n(.+)\n/)[1].trim();const full=s.split('## full_description\n')[1].trim();return {title,shortDescription:short,fullDescription:full};};
const en=parse('en-US.md'), ar=parse('ar.md');
const edit=await (await fetch(`${base}/edits`,{method:'POST',headers:H,body:'{}'})).json();
const cur=(await (await fetch(`${base}/edits/${edit.id}/listings`,{headers:H})).json()).listings;
const byLang=Object.fromEntries(cur.map(l=>[l.language,l]));
fs.writeFileSync(`play_listings_backup_${new Date().toISOString().slice(0,10)}.json`,JSON.stringify(cur,null,1));
// tr-TR: 3 changes only
const tr=byLang['tr-TR'];
let trFull=tr.fullDescription
 .replace("Kaydırmaktan sıkıldınız mı? Qulo'da tanışma fotoğrafla değil, soruyla başlıyor.","Qulo'da kimse size doğrudan yazamaz. Tanışma fotoğrafla değil, sizin sorularınızla başlar.")
 .replace('16 dil desteği','18 dil desteği');
const trShort='Sorularla tanışma ve flört: kaydırma yok. Doğru cevapla eşleş, sohbete başla.';
const plan={};
plan['tr-TR']={language:'tr-TR',title:tr.title,shortDescription:trShort,fullDescription:trFull};
for(const l of ['en-US','en-GB','en-AU','en-CA','en-IN','en-SG','en-ZA']) plan[l]={language:l,...en};
plan['ar']={language:'ar',...ar};
for(const [l,p] of Object.entries(plan)){
  const before=byLang[l]||{};
  console.log(`${l}: title ${before.title?.length??0}->${p.title.length} | short ${before.shortDescription?.length??0}->${p.shortDescription.length} | full ${before.fullDescription?.length??0}->${p.fullDescription.length}`);
  if(p.title.length>30||p.shortDescription.length>80||p.fullDescription.length>4000) throw new Error('limit '+l);
  if(APPLY){ const r=await fetch(`${base}/edits/${edit.id}/listings/${l}`,{method:'PUT',headers:H,body:JSON.stringify(p)}); if(!r.ok) throw new Error(l+' '+r.status+' '+(await r.text()).slice(0,300)); }
}
if(APPLY){
  const v=await fetch(`${base}/edits/${edit.id}:validate`,{method:'POST',headers:H}); console.log('validate',v.status,(await v.text()).slice(0,200));
  const c=await fetch(`${base}/edits/${edit.id}:commit`,{method:'POST',headers:H}); console.log('commit',c.status,(await c.text()).slice(0,300));
} else { await fetch(`${base}/edits/${edit.id}`,{method:'DELETE',headers:H}); console.log('DRY RUN — edit discarded. Run with --apply to commit.'); }
