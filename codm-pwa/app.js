"use strict";
const $ = id => document.getElementById(id);
const LEGENDARY = 8001;
const MILESTONES = [
  ["GM II",6400],["GM III",6800],["GM IV",7200],["GM V",7600],["LEGEND",8001]
];
const STORAGE_PREFIX = "rankcommand-web-v1-";
const fmt = x => x == null || !Number.isFinite(x) ? "—" : Math.round(x).toLocaleString("en-US");
const signed = x => x == null || !Number.isFinite(x) ? "—" : (x > 0 ? "+" : "") + fmt(x);
const safeText = (id,text) => { const el=$(id); if(el)el.textContent=String(text??"—"); };
const validUID = value => /^\d{12,22}$/.test(value);
const own = (object,key) => Object.prototype.hasOwnProperty.call(object,key);
let uid="", player=null, readings=[], range="all", chosenGain=50, refreshing=false, timer=null;
let currentTab="command";
function load(key,fallback){try{const raw=localStorage.getItem(STORAGE_PREFIX+key);return raw?JSON.parse(raw):fallback}catch{return fallback}}
function store(key,value){try{localStorage.setItem(STORAGE_PREFIX+key,JSON.stringify(value))}catch{}}
function uidKey(key){return uid+":"+key}
function loadAccount(){
  player=load(uidKey("player"),null);
  readings=load(uidKey("readings"),[]);
  if(!Array.isArray(readings))readings=[];
  readings=readings.filter(x=>Number.isSafeInteger(x.xp)&&x.xp>=0&&typeof x.timestamp==="number"&&typeof x.rank==="string").slice(-1000);
}
function showConnect(){
  $("connectPanel").hidden=false;
  $("dashboard").hidden=true;
  $("uidInput").value=uid;
  $("consent").checked=false;
  safeText("netMessage","Connect your CODM player UID");
  safeText("lastCheck","");
}
function setStatus(label,state="idle"){
  safeText("netMessage",label);
  document.querySelector(".beacon").className="beacon "+(state==="live"?"live":state==="error"?"error":"");
}
function note(message){
  const el=$("notice");
  el.textContent=message;el.hidden=false;
  if(timer)clearTimeout(timer);
  timer=setTimeout(()=>{el.hidden=true},3500);
}
function normalPlayer(raw){
  if(!raw||!raw.success||typeof raw.nickname!=="string"||!raw.rank||!Number.isSafeInteger(raw.rank.rating)||raw.rank.rating<0||typeof raw.rank.multiplayerRank!=="string") throw new Error("The stats provider returned incomplete rank information.");
  return {
    nickname:raw.nickname.slice(0,100),pic:typeof raw.pic==="string"?raw.pic:null,
    countryCode:typeof raw.countryCode==="string"?raw.countryCode:null,
    countryId:raw.countryId == null?null:String(raw.countryId),
    shortId:raw.shortId == null?null:String(raw.shortId).slice(0,64),
    level:raw.level&&Number.isFinite(Number(raw.level.current))?Number(raw.level.current):null,
    levelArt:raw.level&&typeof raw.level.image==="string"?raw.level.image:null,
    rank:raw.rank.multiplayerRank.slice(0,80),
    rankClass:raw.rank.class==null?null:String(raw.rank.class),
    rankArt:typeof raw.rank.image==="string"?raw.rank.image:null,
    xp:raw.rank.rating, checkedAt:Date.now()
  };
}
function allowedArt(raw){
  try{const url=new URL(raw);const h=url.hostname.toLowerCase();return url.protocol==="https:"&&(h==="codashop.com"||h.endsWith(".codashop.com"))?url.href:null}catch{return null}
}
function displayArt(id,fallbackId,url){
  const el=$(id),fallback=$(fallbackId),safe=allowedArt(url);
  el.hidden=true;fallback.hidden=false;el.removeAttribute("src");
  if(!safe)return;
  el.onload=()=>{
    if(el.src!==safe)return;
    if(id==="rankArt"){
      // Only show authentic rank imagery and never blow a thumbnail up.
      const width=el.naturalWidth||0,height=el.naturalHeight||0;
      if(!width||!height){el.hidden=true;fallback.hidden=false;return}
      const maxWidth=108,maxHeight=114;
      const scale=Math.min(1,maxWidth/width,maxHeight/height);
      el.style.width=Math.floor(width*scale)+"px";
      el.style.height=Math.floor(height*scale)+"px";
    }
    el.hidden=false;fallback.hidden=true;
  };
  el.onerror=()=>{el.hidden=true;fallback.hidden=false};
  el.src=safe;
}
async function refresh(force=false){
  if(refreshing||!uid)return;
  if(!navigator.onLine){setStatus("Offline · saved readings available","error");return}
  if(!force&&player?.checkedAt&&Date.now()-player.checkedAt<60000)return;
  refreshing=true;setStatus("Syncing live Multiplayer XP…");
  $("refreshBtn").disabled=true;
  try{
    const controller=new AbortController();
    const timeout=setTimeout(()=>controller.abort(),12000);
    let response;
    try{response=await fetch("/api/player?uid="+encodeURIComponent(uid),{cache:"no-store",signal:controller.signal,headers:{"Accept":"application/json"}})}
    finally{clearTimeout(timeout)}
    const result=await response.json().catch(()=>null);
    if(!response.ok)throw new Error(result?.error||"Stats service unavailable ("+response.status+")");
    const newPlayer=normalPlayer(result);
    if(uid!==load("uid",""))return;
    player=newPlayer;
    if(!readings.length||readings[readings.length-1].xp!==player.xp||readings[readings.length-1].rank!==player.rank){
      readings.push({timestamp:player.checkedAt,xp:player.xp,rank:player.rank});
      readings=readings.slice(-1000);store(uidKey("readings"),readings);
    }
    store(uidKey("player"),player);
    setStatus("Synced from unofficial stats provider","live");
    render();
  }catch(error){
    setStatus("Live lookup unavailable · showing saved data","error");
    note(error.name==="AbortError"?"The stats lookup timed out. Try again later.":error.message);
  }finally{refreshing=false;$("refreshBtn").disabled=false}
}
function connect(newUID){
  if(!validUID(newUID)){note("Please enter a valid numeric CODM UID.");return}
  if(!$("consent").checked){note("Please acknowledge the unofficial data provider.");return}
  uid=newUID;store("uid",uid);store("acceptedUid",uid);
  loadAccount();
  $("connectPanel").hidden=true;$("dashboard").hidden=false;
  render();refresh(true);
}
function showTab(tab){
  currentTab=tab;
  document.querySelectorAll("[data-tab]").forEach(b=>{
    const on=b.dataset.tab===tab;b.classList.toggle("active",on);
    b.setAttribute("aria-current",on?"page":"false");
  });
  document.querySelectorAll(".pane").forEach(p=>p.classList.toggle("active",p.id==="pane-"+tab));
  if(tab==="analytics")requestAnimationFrame(drawChart);
}
function deltaAt(i){return i>0?readings[i].xp-readings[i-1].xp:null}
function netWithin(ms){
  const start=Date.now()-ms;
  const selected=readings.filter(x=>x.timestamp>=start);
  return selected.length<2?null:selected[selected.length-1].xp-selected[0].xp;
}
function todayNet(){
  const now=new Date();const midnight=new Date(now.getFullYear(),now.getMonth(),now.getDate()).getTime();
  const xs=readings.filter(x=>x.timestamp>=midnight);
  return xs.length<2?null:xs[xs.length-1].xp-xs[0].xp;
}
function render(){
  if(!player)return;
  const remaining=Math.max(0,LEGENDARY-player.xp);
  safeText("rankLabel",player.rank);
  safeText("playerName",player.nickname);
  safeText("levelBadge","LEVEL "+(player.level??"—"));
  safeText("currentXP",fmt(player.xp));
  safeText("percent",Math.round(Math.min(1,player.xp/LEGENDARY)*100)+"% COMPLETE");
  safeText("xpRemaining",fmt(remaining)+" XP TO LEGENDARY");
  $("progressBar").style.width=(Math.min(100,player.xp/LEGENDARY*100))+"%";
  const next=MILESTONES.find(m=>player.xp<m[1]);
  safeText("nextTier",next?next[0]:"LEGENDARY UNLOCKED");
  safeText("nextXP",next?fmt(next[1]-player.xp)+" XP":"✓");
  safeText("liveBadge","LAST READING");
  safeText("lastCheck",new Date(player.checkedAt).toLocaleString(undefined,{hour:"numeric",minute:"2-digit"}));
  displayArt("rankArt","badgeUnavailable",player.rankArt);
  const glowForRank = (rank) => {
    const s=String(rank||"").toLowerCase().replace(/[\s_-]+/g," ");
    if(s.includes("legendary"))return "#ff8d49";
    if(s.includes("grand master"))return "#ffca55";
    if(s.includes("master"))return "#bd9eff";
    if(s.includes("pro"))return "#85b4ff";
    if(s.includes("elite"))return "#65dbec";
    if(s.includes("veteran"))return "#bbc7d1";
    if(s.includes("rookie"))return "#e5b587";
    return "#d8b669";
  };
  $("interactiveRank").style.setProperty("--rank-glow",glowForRank(player.rank));
  $("interactiveRank").setAttribute("aria-label","Original "+player.rank+" COD Mobile badge; tap to toggle glow");
  const last=readings.length>1?deltaAt(readings.length-1):null;
  safeText("mDelta",signed(last));
  safeText("mToday",signed(todayNet()));
  safeText("mWeek",signed(netWithin(7*86400000)));
  safeText("mBest",readings.length?fmt(Math.max(...readings.map(x=>x.xp))):"—");
  renderMilestones();renderPlanner();renderPlayer();renderAnalytics();renderHistory();
}

function renderMilestones(){
  const root=$("milestones");root.replaceChildren();
  const first=MILESTONES.find(x=>player.xp<x[1]);
  MILESTONES.forEach(([title,threshold])=>{
    const el=document.createElement("button");el.type="button";
    el.className="milestone"+(player.xp>=threshold?" done":first?.[1]===threshold?" next":"");
    el.setAttribute("aria-label",title+" milestone: "+fmt(threshold)+" rank XP. Tap for progress.");
    const icon=document.createElement("div");icon.className="badge";icon.textContent=player.xp>=threshold?"✓":title==="LEGEND"?"♛":"✦";
    const label=document.createElement("b");label.textContent=title;
    const number=document.createElement("small");number.textContent=fmt(threshold);
    el.append(icon,label,number);
    el.addEventListener("click",()=>{
      root.querySelectorAll(".milestone").forEach(item=>item.classList.remove("selected"));
      el.classList.add("selected");
      note(player.xp>=threshold ? title+" achieved!" : title+": "+fmt(threshold-player.xp)+" XP remaining.");
    });
    root.append(el);
  });
}
function renderPlanner(){
  safeText("assumedGain","+"+chosenGain);
  safeText("winsEstimate",fmt(Math.ceil(Math.max(0,LEGENDARY-player.xp)/chosenGain)));
  const root=$("gainChoices");root.replaceChildren();
  [30,40,50,60,70].forEach(gain=>{
    const b=document.createElement("button");b.textContent="+"+gain;b.className=chosenGain===gain?"selected":"";
    b.onclick=()=>{chosenGain=gain;renderPlanner()};root.append(b);
  });
}
function row(label,value){
  const el=document.createElement("div");el.className="data-row";
  const n=document.createElement("span");n.textContent=label;
  const v=document.createElement("strong");v.textContent=value==null||value===""?"Not provided":String(value);
  el.append(n,v);return el;
}
function countryName(code){
  if(!code)return null;
  try{return new Intl.DisplayNames([navigator.language||"en"],{type:"region"}).of(code.toUpperCase())}
  catch{return null}
}
function renderPlayer(){
  safeText("profileName",player.nickname);safeText("profileRank",player.rank);
  safeText("profileLevel","LEVEL "+(player.level??"—"));
  displayArt("avatar","avatarFallback",player.pic);
  displayArt("levelArt","levelArtFallback",player.levelArt);
  const el=$("identityRows");el.replaceChildren();
  [
    ["NICKNAME",player.nickname],["PLAYER UID",uid],["SHORT PLAYER ID",player.shortId],
    ["PLAYER LEVEL",player.level],["COUNTRY",countryName(player.countryCode)],
    ["COUNTRY CODE",player.countryCode],["COUNTRY ID",player.countryId],
    ["MULTIPLAYER RANK",player.rank],["RANK CLASS",player.rankClass],
    ["MULTIPLAYER RATING",fmt(player.xp)],["LAST CHECK",new Date(player.checkedAt).toLocaleString()]
  ].forEach(([a,b])=>el.append(row(a,b)));
}
function renderAnalytics(){
  const root=$("analyticsRows");root.replaceChildren();
  const deltas=readings.slice(1).map((r,i)=>r.xp-readings[i].xp);
  const plus=deltas.filter(n=>n>0),minus=deltas.filter(n=>n<0);
  const items=[
    ["RECORDED CHANGES",fmt(deltas.length)],["FIRST READING",readings.length?new Date(readings[0].timestamp).toLocaleString():"—"],
    ["NET TRACKED XP",readings.length>1?signed(readings.at(-1).xp-readings[0].xp):"—"],
    ["TOTAL OBSERVED GAINS",plus.length?"+"+fmt(plus.reduce((a,b)=>a+b,0)):"—"],
    ["TOTAL OBSERVED LOSSES",minus.length?fmt(minus.reduce((a,b)=>a+b,0)):"—"],
    ["BIGGEST OBSERVED GAIN",plus.length?signed(Math.max(...plus)):"—"],
    ["BIGGEST OBSERVED DROP",minus.length?signed(Math.min(...minus)):"—"],
    ["MEAN POSITIVE CHANGE",plus.length?"+"+fmt(plus.reduce((a,b)=>a+b,0)/plus.length):"—"],
    ["HIGHEST RECORDED XP",readings.length?fmt(Math.max(...readings.map(x=>x.xp))):"—"],
    ["TODAY'S NET",signed(todayNet())],["7-DAY NET",signed(netWithin(7*86400000))]
  ];
  items.forEach(([a,b])=>root.append(row(a,b)));
  if(currentTab==="analytics")requestAnimationFrame(drawChart);
}
function renderHistory(){
  safeText("archiveCount",fmt(readings.length)+" stored XP readings (changes + baseline; up to 1,000)");
  const root=$("historyList");root.replaceChildren();
  if(!readings.length){const d=document.createElement("p");d.className="history-empty";d.textContent="No readings yet. Sync your account to start tracking.";root.append(d);return}
  readings.slice(-60).reverse().forEach((entry,reversedIndex)=>{
    const idx=readings.length-1-reversedIndex,delta=deltaAt(idx);
    const r=document.createElement("div");r.className="history-row";
    const icon=document.createElement("span");icon.className="arrow"+(delta<0?" loss":"");icon.textContent=delta===null?"•":delta<0?"↘":"↗";
    const date=document.createElement("span");date.className="date";date.textContent=new Date(entry.timestamp).toLocaleString();
    const note=document.createElement("small");note.textContent=entry.rank;date.append(note);
    const value=document.createElement("span");value.className="delta"+(delta<0?" loss":"");value.textContent=delta===null?"BASELINE":signed(delta);
    const xp=document.createElement("small");xp.textContent=fmt(entry.xp)+" XP";value.append(xp);
    r.append(icon,date,value);root.append(r);
  });
}
function drawChart(){
  const canvas=$("chart"),box=canvas.parentElement,empty=$("chartEmpty");
  const selected=readings.filter(x=>range==="all"||x.timestamp>=Date.now()-Number(range)*86400000);
  if(selected.length<2){canvas.hidden=true;empty.style.display="flex";return}
  empty.style.display="none";canvas.hidden=false;
  const ctx=canvas.getContext("2d"),rect=box.getBoundingClientRect();
  const dpr=Math.min(2,window.devicePixelRatio||1),w=Math.max(250,rect.width),h=Math.max(150,rect.height);
  canvas.width=Math.floor(w*dpr);canvas.height=Math.floor(h*dpr);ctx.scale(dpr,dpr);
  ctx.clearRect(0,0,w,h);
  const margin={left:49,right:12,top:15,bottom:30},cw=w-margin.left-margin.right,ch=h-margin.top-margin.bottom;
  const values=selected.map(x=>x.xp),low=Math.min(...values),high=Math.max(...values),pad=Math.max(10,(high-low)*.15),min=low-pad,max=high+pad;
  const t0=selected[0].timestamp,t1=selected.at(-1).timestamp;
  const atX=x=>margin.left+(t1===t0?0.5:(x-t0)/(t1-t0))*cw;
  const atY=y=>margin.top+ch-(y-min)/(max-min)*ch;
  ctx.font="10px -apple-system,sans-serif";ctx.textAlign="right";ctx.fillStyle="#aab5c2";ctx.strokeStyle="#ffffff1c";
  for(let i=0;i<=4;i++){let y=margin.top+ch/4*i;ctx.beginPath();ctx.moveTo(margin.left,y);ctx.lineTo(w-margin.right,y);ctx.stroke();ctx.fillText(fmt(max-(max-min)/4*i),margin.left-6,y+3)}
  ctx.textAlign="left";ctx.fillText(new Date(t0).toLocaleDateString(),margin.left,h-7);
  ctx.textAlign="right";ctx.fillText(new Date(t1).toLocaleDateString(),w-margin.right,h-7);
  ctx.beginPath();selected.forEach((x,i)=>{const a=atX(x.timestamp),b=atY(x.xp);i?ctx.lineTo(a,b):ctx.moveTo(a,b)});
  ctx.strokeStyle="#ffc547";ctx.lineWidth=3;ctx.lineJoin="round";ctx.stroke();
  selected.forEach(x=>{ctx.beginPath();ctx.arc(atX(x.timestamp),atY(x.xp),3.5,0,Math.PI*2);ctx.fillStyle="#ffd66d";ctx.fill()});
}
function csvText(){
  const q=s=>'"'+String(s).replaceAll('"','""')+'"';
  return "timestamp_iso,multiplayer_ranked_xp,rank,xp_change_since_previous_reading\r\n"+
    readings.map((x,i)=>[new Date(x.timestamp).toISOString(),x.xp,q(x.rank),i===0?"":x.xp-readings[i-1].xp].join(",")).join("\r\n");
}
function exportHistory(){
  if(!readings.length){note("No recorded history to export yet.");return}
  const blob=new Blob([csvText()],{type:"text/csv;charset=utf-8"});
  const url=URL.createObjectURL(blob),link=document.createElement("a");
  link.href=url;link.download="codm-ranked-xp-"+uid+".csv";
  document.body.append(link);link.click();link.remove();
  setTimeout(()=>URL.revokeObjectURL(url),1500);
  note("History CSV is ready to save or share.");
}
// Interactive game-inspired rank glow: tapping charges it; pointer movement steers
// the lighting only. The rank image stays static for maximum source sharpness.
const rankButton=$("interactiveRank");
const reducedMotion=window.matchMedia("(prefers-reduced-motion: reduce)");
function resetRankLight(){
  rankButton.style.setProperty("--orbit-x","0deg");
  rankButton.style.setProperty("--orbit-y","0deg");
  rankButton.style.setProperty("--light-x","50%");
  rankButton.style.setProperty("--light-y","45%");
}
rankButton.addEventListener("pointermove",event=>{
  if(reducedMotion.matches)return;
  const rect=rankButton.getBoundingClientRect();
  const x=Math.max(0,Math.min(1,(event.clientX-rect.left)/rect.width));
  const y=Math.max(0,Math.min(1,(event.clientY-rect.top)/rect.height));
  rankButton.style.setProperty("--orbit-x",((x-.5)*18).toFixed(1)+"deg");
  rankButton.style.setProperty("--orbit-y",((.5-y)*15).toFixed(1)+"deg");
  rankButton.style.setProperty("--light-x",Math.round(x*100)+"%");
  rankButton.style.setProperty("--light-y",Math.round(y*100)+"%");
});
rankButton.addEventListener("pointerleave",resetRankLight);
rankButton.addEventListener("pointercancel",resetRankLight);
rankButton.addEventListener("pointerup",resetRankLight);
rankButton.addEventListener("click",()=>{
  const charged=rankButton.classList.toggle("charged");
  rankButton.setAttribute("aria-pressed",charged?"true":"false");
  rankButton.setAttribute("aria-label",charged?"Turn off rank emblem glow":"Activate rank emblem glow");
  safeText("chargeHint",charged?"✦ GLOW CHARGED · TAP TO DIM":"✧ TAP EMBLEM TO CHARGE");
});

document.querySelectorAll("[data-tab]").forEach(b=>b.addEventListener("click",()=>showTab(b.dataset.tab)));
document.querySelectorAll("[data-range]").forEach(b=>b.addEventListener("click",()=>{
  range=b.dataset.range;document.querySelectorAll("[data-range]").forEach(x=>x.classList.toggle("selected",x===b));drawChart()
}));
$("connectForm").addEventListener("submit",e=>{e.preventDefault();connect($("uidInput").value.trim())});
$("refreshBtn").addEventListener("click",()=>refresh(true));
$("copyUID").addEventListener("click",async()=>{try{await navigator.clipboard.writeText(uid);note("Player UID copied.")}catch{note("Clipboard unavailable: select your UID in Player.")}});
$("exportBtn").addEventListener("click",exportHistory);
$("disconnectBtn").addEventListener("click",()=>{uid="";player=null;readings=[];store("uid","");store("acceptedUid","");showConnect();showTab("command")});
$("clearBtn").addEventListener("click",()=>{if(!uid||!confirm("Delete this player's locally saved XP history? This won't affect COD Mobile."))return;readings=[];store(uidKey("readings"),readings);render();note("Local XP history erased.")});
$("shareBtn").addEventListener("click",async()=>{
  const data={title:"CODM Rank Command",text:"Track your COD Mobile rank with your own UID.",url:location.origin};
  try{if(navigator.share)await navigator.share(data);else if(navigator.clipboard){await navigator.clipboard.writeText(data.url);note("App link copied.")}else note("Share this page's website URL.")}catch{}
});
window.addEventListener("online",()=>{if(uid)refresh(false)});window.addEventListener("offline",()=>setStatus("Offline · saved data available","error"));
window.addEventListener("focus",()=>{if(uid)refresh(false)});
document.addEventListener("visibilitychange",()=>{if(!document.hidden&&uid)refresh(false)});
window.addEventListener("resize",()=>{if(currentTab==="analytics")drawChart()});
if("serviceWorker" in navigator)window.addEventListener("load",()=>navigator.serviceWorker.register("/sw.js").catch(()=>{}));
const previous=load("uid",""),accepted=load("acceptedUid","");
if(validUID(previous)&&accepted===previous){uid=previous;loadAccount();$("connectPanel").hidden=true;$("dashboard").hidden=false;render();setStatus("Showing saved readings · checking live status");refresh(false)}
else showConnect();
