const C="tower-v27", TC="tiles-v1", LC="libs-v1";
// v21.17: 항공사진·표고 지도 조각은 휴대폰에 저장해 두고 다음부터 바로 꺼내 씀 (최대 약 4000장)
const TILE=/^https:\/\/(api\.vworld\.kr\/req\/wmts\/|server\.arcgisonline\.com\/ArcGIS\/rest\/services\/World_Imagery\/|s3\.amazonaws\.com\/elevation-tiles-prod\/)/;
// v21.23: 3D·서버 연결 프로그램(버전 고정)은 휴대폰에 저장 → 전화가 안 터져도 앱이 열림
const LIB=/^https:\/\/(cdnjs\.cloudflare\.com\/ajax\/libs\/|cdn\.jsdelivr\.net\/npm\/|unpkg\.com\/|fonts\.googleapis\.com\/|fonts\.gstatic\.com\/)/;
const CORE=["https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js",
  "https://cdn.jsdelivr.net/npm/three@0.128.0/examples/js/controls/OrbitControls.js",
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.js",
  "https://unpkg.com/leaflet@1.9.4/dist/leaflet.js","https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"];
let puts=0;
async function trim(c){const k=await c.keys();if(k.length>4000)await Promise.all(k.slice(0,k.length-3500).map(r=>c.delete(r)));}
self.addEventListener("install",e=>{self.skipWaiting();e.waitUntil(caches.open(LC).then(c=>Promise.all(CORE.map(u=>c.match(u).then(h=>h||fetch(u,{mode:"cors"}).then(r=>{if(r.ok)return c.put(u,r);}).catch(()=>{}))))))});
self.addEventListener("activate",e=>{e.waitUntil((async()=>{const k=await caches.keys();await Promise.all(k.filter(x=>x!==TC&&x!==LC&&x!==C).map(x=>caches.delete(x)));await self.clients.claim();})())});
// 신호가 약할 때 한참 기다리지 않게: 앱 화면은 5초 안에 못 받으면 저장해 둔 것으로
const timeout=(p,ms)=>new Promise((res,rej)=>{const t=setTimeout(()=>rej(new Error("timeout")),ms);p.then(v=>{clearTimeout(t);res(v);},e=>{clearTimeout(t);rej(e);});});
self.addEventListener("fetch",e=>{
  const u=new URL(e.request.url);
  if(e.request.method!=="GET")return;
  if(TILE.test(e.request.url)){
    e.respondWith(caches.open(TC).then(async c=>{
      const hit=await c.match(e.request);if(hit)return hit;
      const r=await fetch(e.request);
      if(r.ok&&r.type!=="opaque"){c.put(e.request,r.clone());if(++puts%200===0)trim(c);}
      return r;
    }));
    return;
  }
  if(LIB.test(e.request.url)){
    e.respondWith(caches.open(LC).then(async c=>{
      const hit=await c.match(e.request.url);if(hit)return hit;
      const r=await fetch(e.request);if(r.ok)c.put(e.request.url,r.clone());return r;
    }));
    return;
  }
  if(u.origin!==location.origin)return;
  // v21.37: 휴대폰에 남은 옛 화면(최대 10분) 대신 항상 서버에 새 버전이 있는지 확인
  e.respondWith(timeout(fetch(e.request.url,{cache:"no-cache",credentials:"same-origin"}),e.request.mode==="navigate"?5000:8000).then(r=>{const cp=r.clone();caches.open(C).then(c=>c.put(e.request,cp));return r})
    .catch(()=>caches.match(e.request,{ignoreSearch:true}).then(h=>h||(e.request.mode==="navigate"?caches.match("./index.html").then(x=>x||caches.match("./")):undefined)).then(h=>h||Response.error())));
});
