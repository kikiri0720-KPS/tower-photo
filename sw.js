const C="tower-v5", TC="tiles-v1";
// v21.17: 항공사진·표고 지도 조각은 휴대폰에 저장해 두고 다음부터 바로 꺼내 씀 (최대 약 4000장)
const TILE=/^https:\/\/(api\.vworld\.kr\/req\/wmts\/|server\.arcgisonline\.com\/ArcGIS\/rest\/services\/World_Imagery\/|s3\.amazonaws\.com\/elevation-tiles-prod\/)/;
let puts=0;
async function trim(c){const k=await c.keys();if(k.length>4000)await Promise.all(k.slice(0,k.length-3500).map(r=>c.delete(r)));}
self.addEventListener("install",e=>{self.skipWaiting()});
self.addEventListener("activate",e=>{e.waitUntil((async()=>{const k=await caches.keys();await Promise.all(k.filter(x=>x!==TC).map(x=>caches.delete(x)));await self.clients.claim();})())});
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
  if(u.origin!==location.origin)return;
  e.respondWith(fetch(e.request).then(r=>{const cp=r.clone();caches.open(C).then(c=>c.put(e.request,cp));return r}).catch(()=>caches.match(e.request)));
});
