/* Directly sourced Gunsmith attachment lists. No performance, ranking, or TTK fields. */
(function(root){"use strict";
const season=Object.freeze({label:"SEASON 9 // VAMPIRES VS WEREWOLVES",launched:"2026-10-14",reviewed:"2026-10-19",official:"https://www.callofduty.com/blog/2026/10/call-of-duty-mobile-season-9-vampires-werewolves"});
const source=[
{id:"type25",name:"TYPE 25",class:"AR",role:"PUBLISHED AGGRESSIVE BUILD",style:"Close-range oriented guide setup",
kind:"Published gunsmith guide",source:"Zilliongamer · Type 25",
url:"https://zilliongamer.com/call-of-duty-mobile/c/weapon-guide/best-type-25-gunsmith-loadout-attachments-in-cod-mobile",
notes:"The five attachments are listed together in the linked Type 25 Gunsmith guide.",
attachments:[["Stock","RTC Steady Stock"],["Laser","OWC Laser - Tactical"],["Underbarrel","Strike Foregrip"],["Rear Grip","Granulated Grip Tape"],["Ammunition","Stopping Power Reload"]]},
{id:"uss9",name:"USS 9",class:"SMG",role:"PLAYER-SHARED SETUP",style:"Community suggestion",
kind:"Community comment",source:"CallOfDutyMobile subreddit · written five-attachment suggestion",
url:"https://www.reddit.com/r/CallOfDutyMobile/comments/1v0w154/guys_are_these_attachments_good/",
notes:"These five USS 9 attachments appear together in the linked community discussion.",
attachments:[["Muzzle","Monolithic Suppressor"],["Barrel","FSS Carbine Pro"],["Stock","No Stock"],["Ammunition",".41 AE 32 Round Mags"],["Rear Grip","Granulated Grip Tape"]]}
];
const entries=Object.freeze(source.map(item=>{if(item.attachments.length!==5||!item.url.startsWith("https://"))throw Error("Invalid sourced build");
 return Object.freeze({...item,attachments:Object.freeze(item.attachments.map(x=>Object.freeze({slot:x[0],name:x[1]})))})}));
root.RankMeta=Object.freeze({season,entries});
if(typeof module!=="undefined"&&module.exports)module.exports=root.RankMeta;
})(typeof window!=="undefined"?window:globalThis);
