// Minimal offline shell. Do not intercept API lookups or cache other players' stats.
const CACHE="rankcommand-static-v9";
const ASSETS=["/","/index.html","/style.css","/app.js","/icon.svg","/manifest.webmanifest"];
self.addEventListener("install",event=>{
  event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(ASSETS)));
  self.skipWaiting();
});
self.addEventListener("activate",event=>{
  event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key!==CACHE).map(key=>caches.delete(key)))));
  self.clients.claim();
});
self.addEventListener("fetch",event=>{
  const req=event.request;
  if(req.method!=="GET"||new URL(req.url).pathname.startsWith("/api/"))return;
  const url=new URL(req.url);
  if(url.origin!==self.location.origin)return;
  event.respondWith(fetch(req).then(response=>{
    if(response.ok&&url.pathname!=="/sw.js"){const copy=response.clone();caches.open(CACHE).then(cache=>cache.put(req,copy))}
    return response;
  }).catch(()=>caches.match(req).then(r=>r||caches.match("/index.html"))));
});
