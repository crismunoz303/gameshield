// Read-only server-side proxy. No credentials, game manipulation, or daily gift claims.
// UID is passed to an unofficial service. The endpoint can become unavailable.
const UPSTREAM = "https://callofdutymobile.vercel.app/user/";
const uidPattern = /^\d{12,22}$/;
const lookupCache = new Map();
const CACHE_MS = 20000;
function picture(value){
  if(typeof value!=="string"||value.length>1500)return null;
  try {const url=new URL(value), host=url.hostname.toLowerCase();
    return url.protocol==="https:"&&(host==="codashop.com"||host.endsWith(".codashop.com"))?url.href:null;
  } catch {return null}
}
function text(value,n=100){return typeof value==="string"?value.slice(0,n):null}
function numeric(value){const parsed=Number(value);return Number.isFinite(parsed)&&parsed>=0?parsed:null}
module.exports = async function handler(req,res){
  res.setHeader("X-Content-Type-Options","nosniff");
  res.setHeader("Cache-Control","private, no-store, max-age=0");
  if(req.method!=="GET"){res.setHeader("Allow","GET");return res.status(405).json({error:"GET requests only."})}
  const uid=typeof req.query.uid==="string"?req.query.uid:"";
  if(!uidPattern.test(uid))return res.status(400).json({error:"A valid numeric COD Mobile UID is required."});
  const cached=lookupCache.get(uid);
  if(cached&&Date.now()-cached.at<CACHE_MS)return res.status(200).json(cached.profile);
  if(lookupCache.size>250)lookupCache.clear();
  const controller=new AbortController();
  const timeout=setTimeout(()=>controller.abort(),9000);
  try{
    const response=await fetch(UPSTREAM+encodeURIComponent(uid),{
      method:"GET",signal:controller.signal,
      headers:{"Accept":"application/json","User-Agent":"RankCommandReadOnly/1.0"}
    });
    if(!response.ok)return res.status(response.status===404?404:502).json({error:response.status===404?"Player not found. Check the UID.":"The third-party stats service is unavailable."});
    const length=Number(response.headers.get("content-length")||0);
    if(length>64000)return res.status(502).json({error:"Unexpected stats response."});
    const raw=await response.text();
    if(raw.length>64000)return res.status(502).json({error:"Unexpected stats response size."});
    const source=JSON.parse(raw);
    const rating=numeric(source?.rank?.rating);
    const rank=text(source?.rank?.multiplayerRank,80);
    const nickname=text(source?.nickname,100);
    if(source?.success!==true||rating==null||!rank||!nickname)
      return res.status(502).json({error:"The stats service didn't return usable player details."});
    const data={
      success:true,nickname,pic:picture(source.pic),
      countryCode:text(source.countryCode,4),
      countryId:source.countryId==null?null:String(source.countryId).slice(0,32),
      shortId:source.shortId==null?null:String(source.shortId).slice(0,64),
      level:{current:numeric(source.level?.current),image:picture(source.level?.image)},
      rank:{class:source.rank?.class==null?null:String(source.rank.class).slice(0,20),
        multiplayerRank:rank,image:picture(source.rank?.image),rating}
    };
    // Deliberately discard dailyGift / claim URL and all unrecognized fields.
    lookupCache.set(uid,{at:Date.now(),profile:data});
    return res.status(200).json(data);
  }catch(e){return res.status(502).json({error:e.name==="AbortError"?"Stats provider timed out.":"Couldn't contact the unofficial stats provider."})}
  finally{clearTimeout(timeout)}
};
