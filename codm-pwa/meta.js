/* Curated, source-attributed CODM Multiplayer Gunsmith builds.
 * Content reviewed 2026-10-19. NOT official, not real-time.
 * TTK is intentionally null: no independent measurement for these exact
 * attachment sets, range, hit zones, and current patch was verified.
 */
(function(root){
"use strict";
const season=Object.freeze({
 label:"SEASON 9 // VAMPIRES VS WEREWOLVES",
 launched:"2026-10-14",
 reviewed:"2026-10-19",
 official:"https://www.callofduty.com/blog/2026/10/call-of-duty-mobile-season-9-vampires-werewolves"
});
const raw=[
 {id:"grav",name:"GRAV",class:"AR",role:"MID-RANGE FLEX",style:"Range control",
  published:"2026-10-16",kind:"Community build",source:"CODMobile_Loadouts · player report",
  url:"https://www.reddit.com/r/CODMobile_Loadouts/comments/1x74yte/thoughts/",
  notes:"Recent player-posted five-slot Grav setup. The barrel and suppressor were also recommended in the discussion; performance depends on recoil control.",
  attachments:[["Muzzle","Agency Suppressor"],["Barrel","18.7” Takedown"],["Underbarrel","Foregrip"],["Ammunition","40 Rnd Fast Mag"],["Rear Grip","Serpent Wrap"]]},
 {id:"type25",name:"TYPE 25",class:"AR",role:"AGGRESSIVE AR",style:"Close-quarter pressure",
  published:"2026-10-17",kind:"Published gunsmith guide",source:"Zilliongamer · Type 25 aggressive",
  url:"https://zilliongamer.com/call-of-duty-mobile/c/weapon-guide/best-type-25-gunsmith-loadout-attachments-in-cod-mobile",
  notes:"Published aggressive build. Stopping Power Reload affects ammunition behavior; confirm the available in-game Gunsmith option before equipping.",
  attachments:[["Stock","RTC Steady Stock"],["Laser","OWC Laser - Tactical"],["Underbarrel","Strike Foregrip"],["Rear Grip","Granulated Grip Tape"],["Ammunition","Stopping Power Reload"]]},
 {id:"uss9",name:"USS 9",class:"SMG",role:"RANKED FLEX",style:"Close-to-mid mobility",
  published:"2026-07-20",kind:"Community build",source:"CallOfDutyMobile · shared build",
  url:"https://www.reddit.com/r/CallOfDutyMobile/comments/1v0w154/guys_are_these_attachments_good/",
  notes:"A community-shared build from July. USS 9 remains cited by meta lists, but this exact build was not re-tested for the October patch.",
  attachments:[["Muzzle","Monolithic Suppressor"],["Barrel","FSS Carbine Pro"],["Stock","No Stock"],["Ammunition",".41 AE 32 Round Mags"],["Rear Grip","Granulated Grip Tape"]]},
 {id:"cx9",name:"CX-9",class:"SMG",role:"CLOSE-RANGE ENTRY",style:"Fast engagements",
  published:"2026-09-28",kind:"Published gunsmith guide",source:"Esportport · SMG gunsmith guide",
  url:"https://esportport.com/cod-mobile-season-10-best-smg-sniper-gunsmith-loadouts-2026/",
  notes:"Five-slot build reported by a September guide. Its article's season number conflicts with Activision's official October Season 9; the loadout is NOT validated for the current patch.",
  attachments:[["Barrel","CX-38S Integrated Suppressor"],["Stock","CX-FR Stock"],["Perk","Sleight of Hand"],["Ammunition","50 Round Drums"],["Rear Grip","CX-9 Ace Grip"]]},
 {id:"switchblade",name:"SWITCHBLADE X9",class:"SMG",role:"MOBILE SLAYER",style:"Aggressive flanks",
  published:"2026-09-28",kind:"Published gunsmith guide",source:"Esportport · SMG gunsmith guide",
  url:"https://esportport.com/cod-mobile-season-10-best-smg-sniper-gunsmith-loadouts-2026/",
  notes:"Guide-backed five-slot build, not independently tested in the current October update. Confirm attachment labels in your Gunsmith.",
  attachments:[["Muzzle","Tactical Suppressor"],["Barrel","MIP Extended Light Barrel"],["Stock","YKM Light Stock"],["Ammunition","Extended Mag A"],["Rear Grip","Granulated Grip Tape"]]},
 {id:"fennec",name:"FENNEC",class:"SMG",role:"HARDPOINT BREAKER",style:"Very close range",
  published:"2026-09-28",kind:"Published gunsmith guide",source:"Esportport · SMG gunsmith guide",
  url:"https://esportport.com/cod-mobile-season-10-best-smg-sniper-gunsmith-loadouts-2026/",
  notes:"Published close-range configuration. No current-season damage or TTK test for the exact five attachments has been verified.",
  attachments:[["Muzzle","Monolithic Suppressor"],["Barrel","ZLR 18” Deadfall"],["Stock","FTAC Locktight Stock"],["Underbarrel","Operator Foregrip"],["Ammunition","Extended Mag A"]]}
];
const entries=Object.freeze(raw.map(row=>{
 if(row.attachments.length!==5||!["AR","SMG"].includes(row.class)||
   !/^https:\/\//.test(row.url))throw Error("Invalid curated meta build");
 return Object.freeze({...row,ttk:null,ttkStatus:"NOT VERIFIED",
   attachments:Object.freeze(row.attachments.map(a=>Object.freeze({slot:a[0],name:a[1]})))});
}));
root.RankMeta=Object.freeze({season,entries});
if(typeof module!=="undefined"&&module.exports)module.exports=root.RankMeta;
})(typeof window!=="undefined"?window:globalThis);
