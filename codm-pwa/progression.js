/* Rank Command rank XP model.
 * Main tiers match widely published MP rank thresholds, not an official live API.
 * Rank labels/images ALWAYS come from the stats provider.
 * Some GM subdivision checkpoints differ by source; flag them as estimates.
 */
(function(root){
 "use strict";
 const MAIN=Object.freeze([
   {name:"ROOKIE",at:0},
   {name:"VETERAN",at:1001},
   {name:"ELITE",at:2001},
   {name:"PRO",at:3001},
   {name:"MASTER",at:4501},
   {name:"GRAND MASTER",at:6001},
   {name:"LEGENDARY",at:8001}
 ]);
 const ROMAN=["I","II","III","IV","V"];
 const points=[
   {label:"ROOKIE I",at:0},
   ...[201,401,601,801].map((at,i)=>({label:"ROOKIE "+ROMAN[i+1],at})),
   ...[1001,1201,1401,1601,1801].map((at,i)=>({label:"VETERAN "+ROMAN[i],at})),
   ...[2001,2201,2401,2601,2801].map((at,i)=>({label:"ELITE "+ROMAN[i],at})),
   ...[3001,3301,3601,3901,4201].map((at,i)=>({label:"PRO "+ROMAN[i],at})),
   {label:"MASTER",at:4501},
   {label:"GRAND MASTER",at:6001},
   {label:"GM II",at:6400,estimated:true},
   {label:"GM III",at:6800,estimated:true},
   {label:"GM IV",at:7200,estimated:true},
   {label:"GM V",at:7600,estimated:true},
   {label:"LEGENDARY",at:8001}
 ];
 const CHECKPOINTS=Object.freeze(points.map(p=>Object.freeze(p)));
 function asXP(xp){return Number.isFinite(xp)?Math.max(0,Math.round(xp)):0}
 function rankIndex(xp){const n=asXP(xp);let i=0;MAIN.forEach((r,idx)=>{if(n>=r.at)i=idx});return i}
 function next(xp){
   const n=asXP(xp);
   return CHECKPOINTS.find(m=>m.at>n)||null;
 }
 function nearby(xp,max=6){
   const n=asXP(xp);
   let idx=CHECKPOINTS.findIndex(m=>m.at>n);
   if(idx<0)idx=CHECKPOINTS.length-1;
   const size=Math.max(3,Math.min(8,Math.floor(max)));
   const start=Math.max(0,Math.min(CHECKPOINTS.length-size,idx-2));
   return CHECKPOINTS.slice(start,start+size);
 }
 function currentBand(xp){
   const i=rankIndex(xp);
   const lo=MAIN[i].at,hi=i===MAIN.length-1?null:MAIN[i+1].at;
   return {name:MAIN[i].name,from:lo,to:hi,position:i,max:MAIN.length-1};
 }
 function promotion(xp){
   const p=next(xp),n=asXP(xp);
   return p?{...p,remaining:p.at-n}:{label:"LEGENDARY",at:8001,remaining:0,complete:true};
 }
 function progress(xp){return Math.max(0,Math.min(100,asXP(xp)/8001*100))}
 function isReset(prev,curr){
   if(!prev||!curr)return false;
   const old=asXP(prev.xp),now=asXP(curr.xp);
   // A large demotion is a likely season reset, not a verified game reset.
   return old-now>=950 && rankIndex(now)<rankIndex(old);
 }
 const result=Object.freeze({MAIN,CHECKPOINTS,asXP,rankIndex,currentBand,promotion,next,nearby,progress,isReset});
 root.RankProgress=result;
 if(typeof module!=="undefined"&&module.exports)module.exports=result;
})(typeof window!=="undefined"?window:globalThis);
