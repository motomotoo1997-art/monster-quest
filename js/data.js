"use strict";
/* ================= HELPERS ================= */
const $ = id => document.getElementById(id);
const sleep = ms => new Promise(r=>setTimeout(r,ms));
const rand = (a,b) => a + Math.random()*(b-a);
const randInt = (a,b) => Math.floor(rand(a,b+1));
const clamp = (v,a,b) => Math.max(a,Math.min(b,v));
const choice = arr => arr[Math.floor(Math.random()*arr.length)];

/* ================= DATA ================= */
const TYPES = {
  fire:{label:"🔥 Огонь",cls:"fire"}, water:{label:"💧 Вода",cls:"water"},
  grass:{label:"🌿 Трава",cls:"grass"}, electric:{label:"⚡ Электро",cls:"electric"},
  rock:{label:"🪨 Камень",cls:"rock"}, normal:{label:"⭐ Обычный",cls:"normal"},
};
const EFF = {
  fire:{fire:.5,water:.5,grass:2,electric:1,rock:.5,normal:1},
  water:{fire:2,water:.5,grass:.5,electric:1,rock:2,normal:1},
  grass:{fire:.5,water:2,grass:.5,electric:1,rock:2,normal:1},
  electric:{fire:1,water:2,grass:.5,electric:.5,rock:.5,normal:1},
  rock:{fire:2,water:1,grass:.5,electric:2,rock:1,normal:1},
  normal:{fire:1,water:1,grass:1,electric:1,rock:.5,normal:1},
};
const MOVES = {
  tackle:{name:"Наскок",type:"normal",power:38}, scratch:{name:"Царапки",type:"normal",power:40},
  slam:{name:"Мощный удар",type:"normal",power:52}, gust:{name:"Порыв ветра",type:"normal",power:44},
  bite:{name:"Укус",type:"normal",power:50},
  ember:{name:"Уголёк",type:"fire",power:42}, firespin:{name:"Огненный вихрь",type:"fire",power:56},
  dragonfl:{name:"Пламя дракона",type:"fire",power:66},
  splash:{name:"Брызги",type:"water",power:42}, watergun:{name:"Водяная пушка",type:"water",power:56},
  tsunami:{name:"Цунами",type:"water",power:66},
  leaf:{name:"Острый лист",type:"grass",power:42}, vine:{name:"Лиановый хлыст",type:"grass",power:56},
  sunbeam:{name:"Солнечный луч",type:"grass",power:66},
  spark:{name:"Искра",type:"electric",power:42}, discharge:{name:"Разряд",type:"electric",power:56},
  thunder:{name:"Гром",type:"electric",power:66},
  rockfall:{name:"Камнепад",type:"rock",power:52}, avalanche:{name:"Лавина",type:"rock",power:62},
  venom:{name:"Ядовитые шипы",type:"grass",power:36,st:{k:"psn",ch:0.4}},
  stunspark:{name:"Парализующая искра",type:"electric",power:38,st:{k:"par",ch:0.35}},
  dreamdust:{name:"Сонная пыльца",type:"grass",power:30,st:{k:"slp",ch:0.35}},
  nova:{name:"Сверхновая",type:"electric",power:74},
};
const SPECIES = {
  flamis:  {name:"Фламис",  emoji:"🦊", type:"fire",     hp:46,atk:12,def:9, spd:11, moves:["tackle","ember"],    learn:{6:"firespin"}, evolve:{lvl:10,to:"pyrvolk"}, desc:"Хитрый огненный лис"},
  pyrvolk: {name:"Пирволк", emoji:"🐺", type:"fire",     hp:56,atk:15,def:11,spd:13, moves:["tackle","firespin"], learn:{12:"dragonfl"}},
  aquarik: {name:"Акварик", emoji:"🐢", type:"water",    hp:50,atk:10,def:12,spd:8,  moves:["tackle","splash"],   learn:{6:"watergun"}, evolve:{lvl:10,to:"gidrodon"}, desc:"Невозмутимая черепаха"},
  gidrodon:{name:"Гидродон",emoji:"🐊", type:"water",    hp:62,atk:13,def:14,spd:9,  moves:["slam","watergun"],   learn:{12:"tsunami"}},
  listvik: {name:"Листвик", emoji:"🦎", type:"grass",    hp:48,atk:11,def:11,spd:9,  moves:["scratch","leaf"],    learn:{6:"vine"}, evolve:{lvl:10,to:"drakolist"}, desc:"Шустрый травяной ящер"},
  drakolist:{name:"Драколист",emoji:"🐲",type:"grass",   hp:58,atk:14,def:12,spd:11, moves:["slam","vine"],       learn:{12:"sunbeam"}},
  iskrik:  {name:"Искрик",  emoji:"🐇", type:"electric", hp:42,atk:11,def:8, spd:14, moves:["tackle","spark"],    learn:{5:"stunspark",7:"discharge",12:"thunder"}},
  vetryash:{name:"Ветряш",  emoji:"🐦", type:"normal",   hp:40,atk:10,def:8, spd:12, moves:["gust","tackle"],     learn:{8:"slam"}},
  murash:  {name:"Мураш",   emoji:"🐛", type:"grass",    hp:44,atk:10,def:9, spd:8,  moves:["tackle","leaf"],     learn:{5:"venom",8:"vine"}},
  sovun:   {name:"Совун",   emoji:"🦉", type:"normal",   hp:48,atk:12,def:10,spd:10, moves:["gust","scratch"],    learn:{9:"slam"}},
  gribbi:  {name:"Грибби",  emoji:"🍄", type:"grass",    hp:46,atk:11,def:12,spd:6,  moves:["leaf","tackle"],     learn:{6:"dreamdust",9:"vine"}},
  kwakun:  {name:"Квакун",  emoji:"🐸", type:"water",    hp:45,atk:11,def:9, spd:11, moves:["splash","tackle"],   learn:{8:"watergun"}},
  utkan:   {name:"Уткан",   emoji:"🦆", type:"water",    hp:47,atk:11,def:10,spd:10, moves:["splash","gust"],     learn:{9:"watergun"}},
  meduzzi: {name:"Медуззи", emoji:"🪼", type:"water",    hp:45,atk:11,def:10,spd:9,  moves:["splash","watergun"], learn:{7:"venom",10:"tsunami"}},
  valun:   {name:"Валунчик",emoji:"🦔", type:"rock",     hp:54,atk:12,def:14,spd:5,  moves:["tackle","rockfall"], learn:{10:"avalanche"}},
  skorp:   {name:"Скорпи",  emoji:"🦂", type:"rock",     hp:50,atk:13,def:12,spd:8,  moves:["scratch","rockfall"],learn:{8:"venom",11:"avalanche"}},
  letun:   {name:"Летун",   emoji:"🦇", type:"normal",   hp:42,atk:11,def:8, spd:13, moves:["gust","bite"],       learn:{}},
  murzilla:{name:"Мурзилла",emoji:"🐱", type:"normal",   hp:52,atk:13,def:10,spd:10, moves:["scratch","slam"],    learn:{}},
  dragnis: {name:"Драгнис", emoji:"🐉", type:"fire",     hp:60,atk:14,def:12,spd:12, moves:["dragonfl","firespin","slam"], learn:{}},
  svetlyach:{name:"Светляч",emoji:"🪲", type:"electric", hp:40,atk:10,def:8, spd:13, moves:["tackle","spark"],    learn:{7:"stunspark"}},
  plavnik: {name:"Плавник", emoji:"🐟", type:"water",    hp:44,atk:12,def:9, spd:12, moves:["splash","tackle"],   learn:{9:"watergun"}},
  ognevka: {name:"Огнёвка", emoji:"🦋", type:"fire",     hp:44,atk:12,def:8, spd:12, moves:["ember","gust"],      learn:{10:"firespin"}},
  gornyak: {name:"Горняк",  emoji:"🗿", type:"rock",     hp:58,atk:13,def:15,spd:4,  moves:["tackle","rockfall"], learn:{11:"avalanche"}},
  nexolar: {name:"Нексолар", emoji:"🌟", type:"electric", hp:70,atk:16,def:13,spd:15, moves:["nova","thunder","stunspark","slam"], learn:{}},
};
const ENCOUNTERS = {
  meadow:  {lv:[3,5],  mons:["iskrik","vetryash","murash","svetlyach"],  title:"Луг"},
  forest:  {lv:[5,8],  mons:["sovun","gribbi","murash","svetlyach"],     title:"Лес"},
  lake:    {lv:[7,10], mons:["kwakun","utkan","meduzzi","plavnik"],    title:"Озеро"},
  mountain:{lv:[9,12], mons:["valun","skorp","letun","gornyak","ognevka"], title:"Горы"},
};
const TRAINERS = {
  asya:{name:"Тренер Ася", x:13,y:20, pal:{cap:"#DF84A8",body:"#BF8EDA"}, team:[["murzilla",6],["vetryash",5]], reward:{potions:2,money:150},
    intro:"«Мой Мурзилла никому не проигрывал!»", beatenMsg:"Ася: «Ты действительно силён! Удачи в горах»"},
  borya:{name:"Тренер Боря", x:8,y:7, pal:{cap:"#72BC8F",body:"#4FB9C9"}, team:[["gribbi",8],["sovun",9]], reward:{balls:2,money:200},
    intro:"«Лесные монстры — самые выносливые. Докажи обратное!»", beatenMsg:"Боря: «Лес признаёт тебя своим»"},
  maks:{name:"Чемпион Макс", x:29,y:4, pal:{cap:"#EAC26B",body:"#DE9255"}, team:[["skorp",12],["dragnis",14]], champion:true, reward:{money:500},
    intro:"«Ты добрался до арены?! Тогда покажи всё, на что способен!»", beatenMsg:"Макс: «Титул чемпиона теперь твой!»"},
};
const WORLD_ITEMS = [
  {id:"i1",x:3,y:3,kind:"ball"},   {id:"i2",x:16,y:2,kind:"potion"},
  {id:"i3",x:36,y:2,kind:"potion"},{id:"i4",x:22,y:12,kind:"ball"},
  {id:"i5",x:2,y:24,kind:"potion"},{id:"i6",x:36,y:29,kind:"ball"},
  {id:"i7",x:22,y:26,kind:"potion"},
];
const FOUNTAIN = {x:7,y:24};
const START_POS = {x:5,y:26};
const NPCS = {
  shop:{name:"Торговец Тоша", x:3,y:23, pal:{cap:"#8A5A2B",body:"#C9A15A"}},
  zina:{name:"Бабушка Зина",  x:16,y:18, pal:{cap:"#C9C9C9",body:"#A66BB5"}},
};
const LEGEND = {x:35,y:2};
const STATUS = {
  psn:{tag:"ЯД",   msg:"отравлен! ☠️"},
  par:{tag:"ПРЛЧ", msg:"парализован! ⚡"},
  slp:{tag:"СОН",  msg:"засыпает! 💤"},
};
const STRUGGLE = {key:"struggle",name:"Отчаянный рывок",type:"normal",power:35};
const ppFor = mv => mv.power>=66?5:mv.power>=52?10:15;
const mkMove = k => { const mv={key:k,...MOVES[k]}; mv.maxPp=ppFor(mv); mv.pp=mv.maxPp; return mv; };
const effSpd = m => (m.status&&m.status.k==="par") ? m.spd*0.5 : m.spd;
const DEX_ORDER = ["flamis","pyrvolk","aquarik","gidrodon","listvik","drakolist","iskrik","svetlyach","vetryash","murash","sovun","gribbi","kwakun","utkan","meduzzi","plavnik","valun","skorp","letun","gornyak","ognevka","murzilla","dragnis","nexolar"];

/* ================= MONSTER SVG ART ================= */
const MONART = {
  flamis:   {b:"round",c1:"#F0913F",c2:"#C9661F",be:"#FFE3BE",ears:"fox",tail:"fluff",ex:"flame",r:3},
  pyrvolk:  {b:"tall", c1:"#D65A24",c2:"#9E3D12",be:"#F3BE8F",ears:"fox",tail:"fluff",ex:"flame",r:3},
  aquarik:  {b:"round",c1:"#59B7E8",c2:"#2F7FB8",be:"#D8F1FF",ears:"none",tail:"fin",ex:"drop",r:3},
  gidrodon: {b:"tall", c1:"#3E9ED6",c2:"#22699C",be:"#CFECFA",ears:"horn",tail:"fin",ex:"drop",r:3},
  listvik:  {b:"round",c1:"#7CC15B",c2:"#559A38",be:"#E2F5CF",ears:"tuft",tail:"leaf",ex:"leaf",r:3},
  drakolist:{b:"tall", c1:"#5DA943",c2:"#3D7F28",be:"#D8EFC2",ears:"horn",tail:"leaf",ex:"leaf",r:3},
  iskrik:   {b:"round",c1:"#F2CE4B",c2:"#D2A31E",be:"#FFF3CB",ears:"rabbit",tail:"bolt",ex:"spark",r:1},
  svetlyach:{b:"bug",  c1:"#7FD0C2",c2:"#3F9E8E",be:"#E0FAF4",ears:"ant",tail:"none",ex:"spark",r:1},
  vetryash: {b:"bird", c1:"#9DB6D8",c2:"#6B87AE",be:"#EAF1FA",ears:"none",tail:"none",ex:"none",r:1},
  murash:   {b:"bug",  c1:"#8FCB62",c2:"#5E9C38",be:"#E6F6D4",ears:"ant",tail:"none",ex:"none",r:1},
  sovun:    {b:"bird", c1:"#B58A5C",c2:"#8A6238",be:"#F0DFC8",ears:"tuft",tail:"none",ex:"none",r:1},
  gribbi:   {b:"shroom",c1:"#E06A5A",c2:"#B4483A",be:"#FBEFDC",ears:"none",tail:"none",ex:"none",r:1},
  kwakun:   {b:"round",c1:"#6EC66A",c2:"#3F9A3E",be:"#E0F6D8",ears:"round",tail:"none",ex:"drop",r:1},
  utkan:    {b:"bird", c1:"#EFD063",c2:"#C9A32E",be:"#FCF3D2",ears:"none",tail:"none",ex:"drop",r:1},
  meduzzi:  {b:"dome", c1:"#C08BE0",c2:"#8E6BC9",be:"#F0E6FB",ears:"none",tail:"none",ex:"none",r:2},
  plavnik:  {b:"round",c1:"#F09A55",c2:"#C76F2A",be:"#FDE8CD",ears:"fin",tail:"fin",ex:"drop",r:1},
  valun:    {b:"boulder",c1:"#A8B08E",c2:"#7C8464",be:"#E4E8D6",ears:"none",tail:"none",ex:"rock",r:2},
  skorp:    {b:"bug",  c1:"#D8B36A",c2:"#A9843E",be:"#F6E8C8",ears:"ant",tail:"sting",ex:"rock",r:2},
  letun:    {b:"round",c1:"#9B7FC0",c2:"#6F5596",be:"#E9E0F6",ears:"fox",tail:"none",ex:"wings",r:2},
  gornyak:  {b:"boulder",c1:"#9A948A",c2:"#6D675D",be:"#DEDAD2",ears:"none",tail:"none",ex:"rock",r:2},
  ognevka:  {b:"bug",  c1:"#EF7A4E",c2:"#C24E22",be:"#FDE0CC",ears:"ant",tail:"none",ex:"wings",r:3},
  murzilla: {b:"round",c1:"#B9B4C4",c2:"#8B8598",be:"#F0EEF4",ears:"fox",tail:"fluff",ex:"none",r:2},
  dragnis:  {b:"tall", c1:"#D95050",c2:"#A32E2E",be:"#F6C9A8",ears:"horn",tail:"sting",ex:"wings",r:3},
  nexolar:  {b:"tall", c1:"#F5D465",c2:"#D0A32B",be:"#FFF6D8",ears:"horn",tail:"bolt",ex:"shine",r:4},
};
function monSvg(sid){
  const a = MONART[sid] || {b:"round",c1:"#9AA0A6",c2:"#70767C",be:"#E8EAED",ears:"none",tail:"none",ex:"none",r:1};
  const gid = "g_"+sid;
  const P = [];
  P.push(`<ellipse cx="60" cy="107" rx="30" ry="6" fill="rgba(0,0,0,.16)"/>`);
  if(a.tail==="fluff") P.push(`<path d="M86 76 Q112 68 106 44 Q98 60 84 64 Z" fill="${a.c2}"/>`);
  if(a.tail==="fin")   P.push(`<path d="M84 80 Q108 78 108 58 Q94 66 82 68 Z" fill="${a.c2}"/>`);
  if(a.tail==="bolt")  P.push(`<polygon points="84,72 102,60 95,60 108,46 90,56 97,56" fill="#FFD54F" stroke="${a.c2}" stroke-width="2"/>`);
  if(a.tail==="leaf")  P.push(`<path d="M84 74 Q108 68 112 46 Q90 52 80 66 Z" fill="#57B85C"/><path d="M84 72 Q100 62 108 50" fill="none" stroke="#3F8F3D" stroke-width="2"/>`);
  if(a.tail==="sting") P.push(`<path d="M84 76 Q104 74 102 56 L110 44 L96 52 Q90 62 80 66 Z" fill="${a.c2}"/>`);
  if(a.ex==="wings") P.push(`<path d="M32 62 Q8 50 12 30 Q30 38 42 52 Z" fill="${a.c2}" opacity=".9"/><path d="M88 62 Q112 50 108 30 Q90 38 78 52 Z" fill="${a.c2}" opacity=".9"/>`);
  if(a.ex==="shine") P.push(`<circle cx="60" cy="62" r="46" fill="none" stroke="#FFD54F" stroke-width="2" stroke-dasharray="4 7" opacity=".85"/>`);
  let eyeY = 62;
  if(a.b==="round"){ P.push(`<ellipse cx="60" cy="72" rx="33" ry="31" fill="url(#${gid})"/>`); }
  else if(a.b==="tall"){ P.push(`<path d="M60 26 C86 28 88 52 84 74 C82 96 74 104 60 104 C46 104 38 96 36 74 C32 52 34 28 60 26 Z" fill="url(#${gid})"/>`); eyeY=56; }
  else if(a.b==="bug"){ P.push(`<ellipse cx="60" cy="84" rx="26" ry="19" fill="${a.c2}"/><circle cx="60" cy="56" r="23" fill="url(#${gid})"/>`); eyeY=54; }
  else if(a.b==="bird"){ P.push(`<ellipse cx="60" cy="72" rx="30" ry="31" fill="url(#${gid})"/><path d="M32 70 Q20 82 30 94 Q38 86 42 76 Z" fill="${a.c2}"/><path d="M88 70 Q100 82 90 94 Q82 86 78 76 Z" fill="${a.c2}"/>`); }
  else if(a.b==="dome"){ P.push(`<path d="M28 76 Q28 40 60 40 Q92 40 92 76 Q92 86 84 86 L36 86 Q28 86 28 76 Z" fill="url(#${gid})"/>`);
    P.push(`<path d="M40 86 Q38 98 42 106" fill="none" stroke="${a.c2}" stroke-width="5" stroke-linecap="round" opacity=".8"/><path d="M54 86 Q52 100 58 108" fill="none" stroke="${a.c2}" stroke-width="5" stroke-linecap="round" opacity=".8"/><path d="M68 86 Q70 100 64 108" fill="none" stroke="${a.c2}" stroke-width="5" stroke-linecap="round" opacity=".8"/><path d="M80 86 Q84 98 78 106" fill="none" stroke="${a.c2}" stroke-width="5" stroke-linecap="round" opacity=".8"/>`); eyeY=64; }
  else if(a.b==="boulder"){ P.push(`<polygon points="60,34 88,48 94,76 78,100 42,100 26,76 32,48" fill="url(#${gid})"/><path d="M46 58 L54 66 M72 52 L66 62" stroke="${a.c2}" stroke-width="2.5" stroke-linecap="round"/>`); eyeY=68; }
  else if(a.b==="shroom"){ P.push(`<rect x="46" y="58" width="28" height="42" rx="13" fill="${a.be}"/><path d="M24 62 Q26 26 60 26 Q94 26 96 62 Q60 76 24 62 Z" fill="url(#${gid})"/><circle cx="44" cy="44" r="5" fill="${a.be}" opacity=".9"/><circle cx="68" cy="38" r="4" fill="${a.be}" opacity=".9"/><circle cx="80" cy="52" r="4.5" fill="${a.be}" opacity=".9"/>`); eyeY=82; }
  if(a.b==="round"||a.b==="tall"||a.b==="bird") P.push(`<ellipse cx="60" cy="86" rx="17" ry="13" fill="${a.be}" opacity=".92"/>`);
  if(a.ears==="fox") P.push(`<path d="M38 44 L30 14 L56 34 Z" fill="${a.c2}"/><path d="M40 38 L36 22 L49 32 Z" fill="${a.be}" opacity=".85"/><path d="M82 44 L90 14 L64 34 Z" fill="${a.c2}"/><path d="M80 38 L84 22 L71 32 Z" fill="${a.be}" opacity=".85"/>`);
  if(a.ears==="rabbit") P.push(`<ellipse cx="44" cy="26" rx="8" ry="20" fill="${a.c2}" transform="rotate(-14 44 26)"/><ellipse cx="44" cy="28" rx="4" ry="13" fill="${a.be}" transform="rotate(-14 44 26)"/><ellipse cx="76" cy="26" rx="8" ry="20" fill="${a.c2}" transform="rotate(14 76 26)"/><ellipse cx="76" cy="28" rx="4" ry="13" fill="${a.be}" transform="rotate(14 76 26)"/>`);
  if(a.ears==="round") P.push(`<circle cx="38" cy="44" r="11" fill="${a.c2}"/><circle cx="38" cy="44" r="5" fill="${a.be}"/><circle cx="82" cy="44" r="11" fill="${a.c2}"/><circle cx="82" cy="44" r="5" fill="${a.be}"/>`);
  if(a.ears==="horn") P.push(`<path d="M44 34 L38 12 L54 28 Z" fill="#EFE6D0" stroke="${a.c2}" stroke-width="1.5"/><path d="M76 34 L82 12 L66 28 Z" fill="#EFE6D0" stroke="${a.c2}" stroke-width="1.5"/>`);
  if(a.ears==="tuft") P.push(`<path d="M46 38 L40 18 L56 30 Z" fill="${a.c2}"/><path d="M74 38 L80 18 L64 30 Z" fill="${a.c2}"/>`);
  if(a.ears==="ant") P.push(`<path d="M52 36 Q46 20 38 14" fill="none" stroke="${a.c2}" stroke-width="3" stroke-linecap="round"/><circle cx="38" cy="14" r="4" fill="#FFD54F"/><path d="M68 36 Q74 20 82 14" fill="none" stroke="${a.c2}" stroke-width="3" stroke-linecap="round"/><circle cx="82" cy="14" r="4" fill="#FFD54F"/>`);
  if(a.ears==="fin") P.push(`<path d="M42 42 Q30 26 46 20 Q50 32 54 38 Z" fill="${a.c2}"/><path d="M78 42 Q90 26 74 20 Q70 32 66 38 Z" fill="${a.c2}"/>`);
  if(a.ex==="flame") P.push(`<path d="M60 32 Q50 20 58 6 Q60 15 69 10 Q68 24 60 32 Z" fill="#F5A623"/><path d="M60 30 Q56 22 60 14 Q62 20 65 18 Q64 26 60 30 Z" fill="#FFD54F"/>`);
  if(a.ex==="leaf") P.push(`<path d="M60 36 Q60 26 55 19" fill="none" stroke="#3F8F3D" stroke-width="3" stroke-linecap="round"/><ellipse cx="51" cy="16" rx="9" ry="5" fill="#57B85C" transform="rotate(-28 51 16)"/><ellipse cx="62" cy="14" rx="8" ry="4.5" fill="#6FCB72" transform="rotate(18 62 14)"/>`);
  if(a.ex==="drop") P.push(`<path d="M86 20 Q93 32 86 38 Q79 32 86 20 Z" fill="#9AD6F5" stroke="#4A9FD8" stroke-width="1.5"/>`);
  if(a.ex==="spark") P.push(`<polygon points="28,28 34,26 32,18 40,28 34,30 36,38" fill="#FFD54F"/><polygon points="92,22 86,24 88,16 80,26 86,28 84,36" fill="#FFD54F"/>`);
  if(a.ex==="rock") P.push(`<polygon points="42,42 50,26 58,42" fill="#8E8A7E"/><polygon points="58,40 66,24 74,40" fill="#A5A093"/>`);
  if(a.ex==="shine") P.push(`<polygon points="60,2 62,8 68,10 62,12 60,18 58,12 52,10 58,8" fill="#FFD54F"/><polygon points="20,50 21,54 25,55 21,56 20,60 19,56 15,55 19,54" fill="#FFD54F"/><polygon points="100,50 101,54 105,55 101,56 100,60 99,56 95,55 99,54" fill="#FFD54F"/>`);
  const ex1=47, ex2=73;
  if(a.r===4) P.push(`<path d="M${ex1-8} ${eyeY-11} L${ex1+6} ${eyeY-6}" stroke="#333" stroke-width="3" stroke-linecap="round"/><path d="M${ex2+8} ${eyeY-11} L${ex2-6} ${eyeY-6}" stroke="#333" stroke-width="3" stroke-linecap="round"/>`);
  P.push(`<ellipse cx="${ex1}" cy="${eyeY}" rx="7" ry="8" fill="#fff"/><ellipse cx="${ex2}" cy="${eyeY}" rx="7" ry="8" fill="#fff"/>`);
  P.push(`<circle cx="${ex1+1.5}" cy="${eyeY+1}" r="3.4" fill="#2C2C2B"/><circle cx="${ex2+1.5}" cy="${eyeY+1}" r="3.4" fill="#2C2C2B"/>`);
  P.push(`<circle cx="${ex1+3}" cy="${eyeY-1.5}" r="1.2" fill="#fff"/><circle cx="${ex2+3}" cy="${eyeY-1.5}" r="1.2" fill="#fff"/>`);
  P.push(`<circle cx="${ex1-9}" cy="${eyeY+9}" r="4" fill="#F08080" opacity=".3"/><circle cx="${ex2+9}" cy="${eyeY+9}" r="4" fill="#F08080" opacity=".3"/>`);
  if(a.b==="bird") P.push(`<polygon points="54,${eyeY+8} 66,${eyeY+8} 60,${eyeY+16}" fill="#F2A93B"/>`);
  else P.push(`<path d="M54 ${eyeY+11} Q60 ${eyeY+16} 66 ${eyeY+11}" fill="none" stroke="#2C2C2B" stroke-width="2.2" stroke-linecap="round"/>`);
  return `<svg viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg" role="img"><defs><radialGradient id="${gid}" cx="40%" cy="35%" r="85%"><stop offset="0%" stop-color="${a.c1}"/><stop offset="100%" stop-color="${a.c2}"/></radialGradient></defs>${P.join("")}</svg>`;
}

/* ================= MAP GEN ================= */
const MAP_W=40, MAP_H=32, TILE=36;
const grid = Array.from({length:MAP_H},()=>Array(MAP_W).fill("."));
function inRect(x,y,x1,y1,x2,y2){return x>=x1&&x<=x2&&y>=y1&&y<=y2;}
function region(x,y){
  if(y<15) return x<19 ? "forest" : "mountain";
  return x<19 ? "meadow" : "lake";
}
(function buildMap(){
  const h=(x,y)=>((x*73+y*151)^(x*31))>>>0;
  for(let y=1;y<MAP_H-1;y++)for(let x=1;x<MAP_W-1;x++){
    const r=region(x,y), v=h(x,y);
    if(v%13===0) grid[y][x]=",";
    if(r==="forest" && v%9===0) grid[y][x]="#";
    if(r==="meadow" && v%23===0) grid[y][x]="#";
    if(r==="lake" && v%19===0) grid[y][x]="#";
    if(r==="mountain"){ if(v%19===0) grid[y][x]="#"; else if(v%11===0) grid[y][x]="o"; }
  }
  const bush=(x1,y1,x2,y2)=>{for(let y=y1;y<=y2;y++)for(let x=x1;x<=x2;x++) grid[y][x]="*";};
  bush(8,22,12,25); bush(2,18,4,21); bush(13,27,16,29);            // meadow
  bush(2,4,5,7); bush(11,3,14,5); bush(7,10,10,12); bush(14,11,17,13); // forest
  bush(21,17,23,19); bush(35,17,37,20); bush(22,28,26,29); bush(35,25,37,27); // lake
  bush(21,8,24,10); bush(34,8,37,10); bush(22,2,25,3); bush(35,4,37,6);       // mountain
  for(let y=20;y<=27;y++)for(let x=24;x<=34;x++){                  // pond
    if((x===24||x===34)&&(y===20||y===27)) continue;
    grid[y][x]="~";
  }
  for(let x=2;x<38;x++) grid[15][x]="-";                           // roads
  for(let y=3;y<=15;y++) grid[y][19]="-";
  for(let y=15;y<=26;y++) grid[y][5]="-";
  for(let y=7;y<=15;y++) grid[y][29]="-";
  for(let x=26;x<=32;x++){grid[3][x]="#"; grid[6][x]="#";}         // arena
  for(let y=3;y<=6;y++){grid[y][26]="#"; grid[y][32]="#";}
  for(let y=4;y<=5;y++)for(let x=27;x<=31;x++) grid[y][x]=".";
  grid[6][29]="-";
  grid[FOUNTAIN.y][FOUNTAIN.x]="F";
  const clear=(cx,cy)=>{for(let y=cy-1;y<=cy+1;y++)for(let x=cx-1;x<=cx+1;x++){
    if(x<1||y<1||x>=MAP_W-1||y>=MAP_H-1) continue;
    if(inRect(x,y,26,3,32,6)) continue;
    if("#o~".includes(grid[y][x])) grid[y][x]=".";
  }};
  clear(START_POS.x,START_POS.y);
  Object.values(TRAINERS).forEach(t=>{ if(!t.champion) clear(t.x,t.y); });
  Object.values(NPCS).forEach(n=>clear(n.x,n.y));
  clear(LEGEND.x,LEGEND.y);
  WORLD_ITEMS.forEach(i=>{ clear(i.x,i.y); if(grid[i.y][i.x]!=="-") grid[i.y][i.x]="."; });
  for(let x=0;x<MAP_W;x++){grid[0][x]="#"; grid[MAP_H-1][x]="#";}
  for(let y=0;y<MAP_H;y++){grid[y][0]="#"; grid[y][MAP_W-1]="#";}
})();
const tileAt=(x,y)=> (x<0||y<0||x>=MAP_W||y>=MAP_H) ? "#" : grid[y][x];

/* ================= STATE ================= */
let S = null; // game state
let held = [];          // direction stack
let uiLock = false;     // modal / battle lock
let inBattle = false;
let lastBump = 0;
let stepsSinceBattle = 99;
let rafId = null;
const SAVE_KEY = "monsterquest3";

function defaultState(sid){
  return {team:[newMon(sid,5)], potions:3, balls:5, money:120, goldballs:0, x:START_POS.x, y:START_POS.y,
    rx:START_POS.x, ry:START_POS.y, tx:START_POS.x, ty:START_POS.y, dir:"down", moving:false, moveT:0,
    picked:[], beaten:[], champDone:false, seen:[sid], caught:[sid], legendDone:false, zinaDone:false};
}
function saveGame(){
  if(!S) return;
  try{
    localStorage.setItem(SAVE_KEY, JSON.stringify({
      team:S.team.map(m=>({sid:m.sid,level:m.level,exp:m.exp,hp:m.hp,mv:m.moves.map(v=>({k:v.key,pp:v.pp}))})),
      potions:S.potions, balls:S.balls, money:S.money, goldballs:S.goldballs, x:S.x, y:S.y,
      picked:S.picked, beaten:S.beaten, champDone:S.champDone,
      seen:S.seen, caught:S.caught, legendDone:S.legendDone, zinaDone:S.zinaDone,
    }));
  }catch(e){}
}
function loadGame(){
  try{
    const raw = localStorage.getItem(SAVE_KEY);
    if(!raw) return null;
    const d = JSON.parse(raw);
    const st = defaultState("flamis");
    st.team = d.team.map(t=>{
      const m=newMon(t.sid,t.level); m.exp=t.exp||0; m.hp=Math.min(t.hp,m.maxHp);
      if(t.mv&&t.mv.length){ m.moves=t.mv.filter(o=>MOVES[o.k]).map(o=>{const w=mkMove(o.k); w.pp=Math.max(0,Math.min(o.pp==null?w.maxPp:o.pp,w.maxPp)); return w;}); }
      return m;
    });
    st.potions=d.potions; st.balls=d.balls; st.money=d.money==null?120:d.money; st.goldballs=d.goldballs||0;
    st.x=st.rx=st.tx=d.x; st.y=st.ry=st.ty=d.y;
    st.picked=d.picked||[]; st.beaten=d.beaten||[]; st.champDone=!!d.champDone;
    st.seen=d.seen||st.team.map(m=>m.sid); st.caught=d.caught||st.team.map(m=>m.sid);
    st.legendDone=!!d.legendDone; st.zinaDone=!!d.zinaDone;
    return st;
  }catch(e){ return null; }
}

/* ================= MONSTERS ================= */
function statsFor(sid, level){
  const b = SPECIES[sid];
  return {maxHp:b.hp+level*4, atk:b.atk+level*2, def:b.def+level*2, spd:b.spd+level};
}
function newMon(sid, level){
  const b = SPECIES[sid], st = statsFor(sid,level);
  return {sid, level, exp:0, hp:st.maxHp, maxHp:st.maxHp, atk:st.atk, def:st.def, spd:st.spd,
    name:b.name, emoji:b.emoji, type:b.type,
    moves:b.moves.map(k=>mkMove(k))};
}
const expNeed = lvl => lvl*25;
function applyLevel(m){
  const st = statsFor(m.sid, m.level);
  const diff = st.maxHp - m.maxHp;
  m.maxHp=st.maxHp; m.atk=st.atk; m.def=st.def; m.spd=st.spd;
  m.hp = Math.min(m.maxHp, m.hp + Math.max(0,diff));
}
function calcDamage(att, def, move){
  const eff = EFF[move.type][def.type];
  const stab = move.type===att.type ? 1.2 : 1;
  const base = (2*att.level/5+2) * move.power * (att.atk/def.def) / 14;
  return {dmg:Math.max(1,Math.round(base*eff*stab*rand(0.85,1))), eff};
}
