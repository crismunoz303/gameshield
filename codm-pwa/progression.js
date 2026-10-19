/* Rank benchmarks transcribed from an explicitly dated historical reference.
  DO NOT treat these as current verified in-game thresholds.
  CODM player rank and rating come from the live profile provider, not this table.
  2023 source: https://news.codashop.com/ph/call-of-duty-mobile-ranking-system-explained/
*/
(function(root){
"use strict";
const reference=Object.freeze({date:"2023-02-16",label:"CODASHOP / 2023 REFERENCE",url:"https://news.codashop.com/ph/call-of-duty-mobile-ranking-system-explained/",verifiedCurrent:false});
const sections=[
 ["ROOKIE",1,[1,201,401,601,801]],
 ["VETERAN",1001,[1001,1201,1401,1601,1801]],
 ["ELITE",2001,[2001,2201,2401,2601,2801]],
 ["PRO",3001,[3001,3301,3601,3901,4201]],
 ["MASTER",4501,[4501,4801,5101,5401,5701]],
 ["GRAND MASTER",6001,[6001,6401,6801,7201,7601]],
 ["LEGENDARY",8001,[8001]]
];
const numeral=["I","II","III","IV","V"];
const MAIN=Object.freeze(sections.map(row=>Object.freeze({name:row[0],at:row[1]})));
const CHECKPOINTS=Object.freeze(sections.flatMap(row=>row[2].map((at,i)=>Object.freeze({label:row[0]+(row[0]==="LEGENDARY"?"":" "+numeral[i]),at,verifiedCurrent:false,referenceDate:reference.date}))));
function asXP(xp){return Number.isFinite(xp)?Math.max(0,Math.round(xp)):0}
function rankIndex(xp){const n=asXP(xp);let i=0;MAIN.forEach((r,j)=>{if(n>=r.at)i=j});return i}
function currentBand(xp){const i=rankIndex(xp);return {name:MAIN[i].name,from:MAIN[i].at,to:MAIN[i+1]?.at??null,position:i,max:MAIN.length-1,verifiedCurrent:false}}
function next(xp){return CHECKPOINTS.find(m=>m.at>asXP(xp))||null}
function promotion(xp){const p=next(xp);return p?{...p,remaining:p.at-asXP(xp),historical:true}:{label:"LEGENDARY",at:8001,remaining:0,complete:true,historical:true,verifiedCurrent:false}}
function nearby(xp,max=6){const i=CHECKPOINTS.findIndex(x=>x.at>asXP(xp));const size=Math.max(3,Math.min(8,Math.floor(max)));const end=i<0?CHECKPOINTS.length-1:i;const start=Math.max(0,Math.min(CHECKPOINTS.length-size,end-2));return CHECKPOINTS.slice(start,start+size)}
function progress(xp){return Math.max(0,Math.min(100,asXP(xp)/8001*100))}
// A rating drop alone does not verify a season reset. Never invent causes.
function isReset(){return false}
const result=Object.freeze({reference,MAIN,CHECKPOINTS,asXP,rankIndex,currentBand,next,promotion,nearby,progress,isReset});
root.RankProgress=result;
if(typeof module!=="undefined"&&module.exports)module.exports=result;
})(typeof window!=="undefined"?window:globalThis);
