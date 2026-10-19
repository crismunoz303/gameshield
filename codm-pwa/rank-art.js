/*
 * Rank Command original vector companion emblems v1.2.
 * Seven fully scale-independent SVGs, with one art direction per MP tier.
 * These are original fan-made graphics, not game asset reproductions.
 * The separate source-image thumbnail retains the image supplied by Codashop.
 */
(function(){
  "use strict";
  const TIERS=[
    {key:"rookie",label:"Rookie",base:"#8a563b",hi:"#ffd49a",edge:"#d89965",dark:"#39211c",glow:"#f5a866"},
    {key:"veteran",label:"Veteran",base:"#577c91",hi:"#eaf9ff",edge:"#92b7cd",dark:"#223a51",glow:"#87d9ff"},
    {key:"elite",label:"Elite",base:"#2c8daa",hi:"#b8fcf9",edge:"#59d6ee",dark:"#0a3448",glow:"#4cdeff"},
    {key:"pro",label:"Pro",base:"#2663ba",hi:"#d0f5ff",edge:"#5dbdff",dark:"#182c66",glow:"#58b7ff"},
    {key:"master",label:"Master",base:"#6b48b5",hi:"#f0d8ff",edge:"#bca0ff",dark:"#34215d",glow:"#bb90ff"},
    {key:"grandmaster",label:"Grand Master",base:"#b4772e",hi:"#fff7c1",edge:"#ffd15d",dark:"#63351e",glow:"#ffc950"},
    {key:"legendary",label:"Legendary",base:"#b8462f",hi:"#ffe8a6",edge:"#ffbf56",dark:"#5e1426",glow:"#ff684d"}
  ];
  function resolve(raw){
    const s=String(raw||"").toLowerCase().replace(/[\-_]+/g," ").replace(/\s+/g," ").trim();
    if(/\blegendary\b/.test(s))return TIERS[6];
    if(/\bgrand\s*master\b/.test(s))return TIERS[5];
    if(/\bmaster\b/.test(s))return TIERS[4];
    if(/\bpro\b/.test(s))return TIERS[3];
    if(/\belite\b/.test(s))return TIERS[2];
    if(/\bveteran\b/.test(s))return TIERS[1];
    if(/\brookie\b/.test(s))return TIERS[0];
    return null;
  }
  function roman(raw){
    const str=String(raw||"").trim().toUpperCase();
    const m=str.match(/(?:\s|-)(IV|III|II|I|V)$/);
    return m?m[1]:"";
  }
  // Metallic wings change silhouette depending on the division.
  function wings(key){
    const left={
      rookie:'<path d="M119 112 80 98 46 112 79 126 113 132 119 112Z" fill="url(#outer)" stroke="var(--badge-edge)" stroke-width="3"/><path d="M116 141 80 131 56 143 95 159Z" fill="url(#inner)"/>',
      veteran:'<path d="M118 93 76 71 24 76 64 107 111 121Z" fill="url(#outer)" stroke="var(--badge-edge)" stroke-width="3"/><path d="M109 133 60 114 23 124 64 146 110 160Z" fill="url(#outer)"/><path d="M112 165 74 147 47 162 93 178Z" fill="url(#inner)"/>',
      elite:'<path d="M119 90 77 59 26 58 67 99 110 117Z" fill="url(#outer)" stroke="var(--badge-edge)" stroke-width="3"/><path d="M109 128 55 103 17 110 66 147 109 156Z" fill="url(#inner)" stroke="var(--badge-edge)" stroke-width="2"/><path d="M111 165 65 146 38 162 89 187Z" fill="url(#outer)"/>',
      pro:'<path d="M117 90 75 52 18 45 59 98 112 117Z" fill="url(#outer)" stroke="var(--badge-edge)" stroke-width="3"/><path d="M111 125 59 101 13 108 57 144 107 157Z" fill="url(#inner)" stroke="var(--badge-edge)" stroke-width="2"/><path d="M110 168 64 147 34 174 92 198Z" fill="url(#outer)"/><path d="m78 84-40-19 19 31 26 12Z" fill="var(--badge-hi)" opacity=".55"/>',
      master:'<path d="M119 91 83 49 25 39 60 96 111 118Z" fill="url(#outer)" stroke="var(--badge-edge)" stroke-width="3"/><path d="M108 126 64 93 13 98 52 142 110 160Z" fill="url(#inner)" stroke="var(--badge-edge)" stroke-width="3"/><path d="M108 166 61 146 27 171 81 201 108 197Z" fill="url(#outer)" stroke="var(--badge-edge)" stroke-width="2"/><path d="m76 57 28 43-46-31" fill="var(--badge-hi)" opacity=".5"/>',
      grandmaster:'<path d="M118 89 97 35 75 59 47 35 53 77 13 59 38 116 112 131Z" fill="url(#outer)" stroke="var(--badge-edge)" stroke-width="4"/><path d="M107 129 61 101 16 115 56 150 108 157Z" fill="url(#inner)" stroke="var(--badge-edge)" stroke-width="3"/><path d="M105 167 54 145 25 170 80 203 105 193Z" fill="url(#outer)" stroke="var(--badge-edge)" stroke-width="3"/><path d="m79 52 24 64-42-31-29-13 49 57-59-22" fill="none" stroke="var(--badge-hi)" stroke-width="5" opacity=".7"/>',
      legendary:'<path d="M115 92 99 35 79 61 58 20 47 70 12 51 36 106 111 133Z" fill="url(#outer)" stroke="var(--badge-edge)" stroke-width="4"/><path d="M107 131 64 100 8 106 47 148 106 163Z" fill="url(#inner)" stroke="var(--badge-edge)" stroke-width="3"/><path d="M105 173 50 144 21 170 71 207 105 195Z" fill="url(#outer)" stroke="var(--badge-edge)" stroke-width="3"/><path d="m57 37 20 46 16-24 20 65-46-39-43-20 42 61-49-12" fill="none" stroke="var(--badge-hi)" stroke-width="4" opacity=".75"/>'
    }[key];
    return '<g>'+left+'</g><g transform="translate(320 0) scale(-1 1)">'+left+'</g>';
  }
  function center(key){
    switch(key){
      case "rookie":return '<path d="m160 128 28 21-28 33-28-33Z" fill="url(#gem)" stroke="var(--badge-hi)" stroke-width="3"/><path d="M135 197 160 213 185 197" stroke="var(--badge-hi)" stroke-width="8" fill="none"/>';
      case "veteran":return '<path d="m160 105 26 24-26 41-26-41Z" fill="url(#gem)" stroke="var(--badge-hi)" stroke-width="4"/><path d="m119 192 41 23 41-23m-71 15 30 18 30-18" stroke="var(--badge-hi)" stroke-width="7" fill="none"/>';
      case "elite":return '<path d="m160 105 39 42-39 44-39-44Z" fill="url(#gem)" stroke="var(--badge-hi)" stroke-width="4"/><path d="m164 117-26 34h22l-11 31 37-43h-24Z" fill="var(--badge-hi)"/>';
      case "pro":return '<path d="M160 111 197 142 186 184 160 197 134 184 123 142Z" fill="url(#gem)" stroke="var(--badge-hi)" stroke-width="4"/><path d="m160 119 9 20 22 3-16 16 4 22-19-10-19 10 4-22-16-16 22-3Z" fill="var(--badge-hi)"/>';
      case "master":return '<path d="m160 105 51 47-22 54-58 0-22-54Z" fill="url(#gem)" stroke="var(--badge-hi)" stroke-width="4"/><path d="m160 119 11 24 26 3-19 18 6 28-24-13-24 13 6-28-19-18 26-3Z" fill="var(--badge-hi)"/>';
      case "grandmaster":return '<path d="m160 100 52 48-17 59-35 21-35-21-17-59Z" fill="url(#gem)" stroke="var(--badge-hi)" stroke-width="5"/><path d="m160 109 12 28 31 4-23 21 7 30-27-16-27 16 7-30-23-21 31-4Z" fill="var(--badge-hi)"/><path d="m153 188 7 10 7-10" fill="none" stroke="var(--badge-hi)" stroke-width="5"/>';
      case "legendary":return '<path d="m160 99 55 49-17 62-38 28-38-28-17-62Z" fill="url(#gem)" stroke="var(--badge-hi)" stroke-width="5"/><path d="M125 139 131 110 151 130 160 104 174 132 193 110 194 143 160 165Z" fill="var(--badge-hi)" stroke="var(--badge-edge)" stroke-width="3"/><path d="m160 151 12 21-12 27-12-27Z" fill="#ff603d"/>';
      default:return '';
    }
  }
  function render(name){
    const tier=resolve(name),t=tier||{key:"unranked",label:"Unranked",base:"#77838f",hi:"#f0f4fc",edge:"#9aa8bd",dark:"#303b46",glow:"#c5d0da"};
    const key=t.key==="unranked"?"rookie":t.key;
    const numeral=roman(name);
    const crown=(key==="legendary"||key==="grandmaster")?'<path d="M131 66 149 82 160 61 172 82 190 66 187 93 133 93Z" fill="var(--badge-hi)" stroke="var(--badge-edge)" stroke-width="3"/>':"";
    const symbol= numeral ? '<text x="160" y="269" font-family="system-ui,sans-serif" font-size="31" font-weight="950" letter-spacing="-2" text-anchor="middle" fill="var(--badge-hi)" stroke="var(--badge-dark)" stroke-width="1.2" paint-order="stroke">'+numeral+'</text>' :
      '<path d="m149 254 11 14 11-14-11-15Z" fill="var(--badge-hi)"/>';
    const prefix="tier-"+t.key+"-";
    const glyphWings=wings(key).replaceAll("url(#outer)","url(#"+prefix+"outer)").replaceAll("url(#inner)","url(#"+prefix+"inner)");
    const glyphCenter=center(key).replaceAll("url(#gem)","url(#"+prefix+"gem)");
    return '<svg class="hd-rank-svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 320" role="img" aria-label="'+t.label+' Rank Command fan-made HD vector insignia" style="--badge-base:'+t.base+';--badge-hi:'+t.hi+';--badge-edge:'+t.edge+';--badge-dark:'+t.dark+';--badge-glow:'+t.glow+'">'+
      '<defs><linearGradient id="'+prefix+'outer" x1="0" y1="0" x2="0.8" y2="1"><stop stop-color="'+t.hi+'"/><stop offset=".45" stop-color="'+t.base+'"/><stop offset="1" stop-color="'+t.dark+'"/></linearGradient>'+
      '<linearGradient id="'+prefix+'inner" x1=".9" y1=".1" x2=".1" y2=".9"><stop stop-color="'+t.dark+'"/><stop offset=".5" stop-color="'+t.base+'"/><stop offset="1" stop-color="'+t.hi+'"/></linearGradient>'+
      '<radialGradient id="'+prefix+'gem"><stop stop-color="'+t.hi+'"/><stop offset=".42" stop-color="'+t.base+'"/><stop offset="1" stop-color="'+t.dark+'"/></radialGradient></defs>'+
      '<g fill="none" stroke="'+t.edge+'" stroke-width="1.8" opacity=".55"><ellipse cx="160" cy="170" rx="111" ry="113"/><path d="M160 45V30 M160 295V286 M40 160H55 M265 160H281"/></g>'+
      glyphWings+
      '<path d="M160 48 218 84 222 166 206 225 160 271 114 225 98 166 102 84Z" fill="url(#'+prefix+'outer)" stroke="var(--badge-hi)" stroke-width="5"/>'+
      '<path d="M160 64 205 92 207 164 195 217 160 253 125 217 113 164 115 92Z" fill="var(--badge-dark)" stroke="var(--badge-edge)" stroke-width="4"/>'+
      '<path d="M160 78 197 101 197 164 186 205 160 232 134 205 123 164 123 101Z" fill="url(#'+prefix+'inner)" stroke="var(--badge-hi)" stroke-width="2" opacity=".85"/>'+
      crown+glyphCenter+
      '<path d="M125 240 160 249 195 240 186 276 160 294 134 276Z" fill="url(#outer)" stroke="var(--badge-hi)" stroke-width="4"/>'+
      symbol+
      '<path d="m134 115 15-16m27 0 12 16" stroke="var(--badge-hi)" stroke-width="2" opacity=".75"/>'+
      '</svg>';
  }
  window.RankArt=Object.freeze({resolve,roman,render,tiers:TIERS.map(t=>Object.freeze({...t}))});
})();