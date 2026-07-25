"use strict";
/* ================= SCREENS / UI ================= */
function showScreen(id){
  document.querySelectorAll(".screen").forEach(s=>s.classList.remove("active"));
  $(id).classList.add("active");
  $("badges").hidden = (id==="screen-start" || id==="screen-end");
}
function renderBadges(){
  $("b-money").textContent=S.money;
  $("b-potions").textContent=S.potions;
  $("b-balls").textContent=S.balls+(S.goldballs>0?" +"+S.goldballs+"🟡":"");
  $("b-trainers").textContent=S.beaten.length+"/3";
}
function renderHud(){
  $("hud").innerHTML = S.team.map(m=>{
    const pct = m.hp/m.maxHp*100;
    const cls = pct<=25?"low":pct<=55?"mid":"";
    return `<div class="chip"><span class="e">${m.emoji}</span><div><div class="lv">ур.${m.level}</div><div class="bar"><i class="${cls}" style="width:${pct}%"></i></div></div></div>`;
  }).join("");
}
let msgTimer=null;
function showMsg(text, ms=2400){
  const el=$("msg");
  el.textContent=text; el.classList.add("on");
  clearTimeout(msgTimer);
  msgTimer=setTimeout(()=>el.classList.remove("on"), ms);
}
/* team modal */
function openModal(){
  uiLock=true; held=[];
  $("modal-title").textContent="👥 Ваша команда";
  $("modal-list").innerHTML = S.team.map((m,i)=>{
    const pct=m.hp/m.maxHp*100;
    return `<div class="mon-row">
      <span class="e">${monSvg(m.sid)}</span>
      <div class="info">
        <div class="nm">${m.name} <span style="color:var(--text2);font-weight:400">ур. ${m.level}</span></div>
        <div class="st">${TYPES[m.type].label} · ${Math.max(0,m.hp)}/${m.maxHp} ОЗ · опыт ${m.exp}/${expNeed(m.level)} · атк ${m.atk} · защ ${m.def} · скр ${m.spd}</div>
        <div class="minibar"><i style="width:${pct}%"></i></div>
      </div>
      <button data-first="${i}" ${i===0?"disabled":""}>${i===0?"Лидер":"Первым"}</button>
    </div>`;
  }).join("");
  $("modal").hidden=false;
}
$("modal-list").addEventListener("click",e=>{
  const buy=e.target.closest("button[data-buy]");
  if(buy){ doBuy(buy.dataset.buy); return; }
  const b=e.target.closest("button[data-first]");
  if(!b) return;
  const i=+b.dataset.first;
  const [m]=S.team.splice(i,1); S.team.unshift(m);
  openModal(); renderHud(); saveGame();
});
$("modal-close").addEventListener("click",()=>{$("modal").hidden=true; uiLock=false;});
$("btn-team").addEventListener("click",()=>{ if(!inBattle) openModal(); });
const SHOP_ITEMS=[
  {id:"potion", ic:"🧪", nm:"Зелье", d:"+60% ОЗ в бою", price:60, cap:9, get:()=>S.potions, add:()=>S.potions++},
  {id:"ball", ic:"⚪", nm:"Монстробол", d:"ловит диких монстров", price:50, cap:9, get:()=>S.balls, add:()=>S.balls++},
  {id:"gold", ic:"🟡", nm:"Золотой бол", d:"поимка гарантирована", price:250, cap:3, get:()=>S.goldballs, add:()=>S.goldballs++},
];
function openShop(){
  uiLock=true; held=[];
  $("modal-title").textContent="🛒 Лавка Тоши";
  $("modal-list").innerHTML =
    `<div style="margin:0 0 10px;color:var(--text2);font-size:14px">Тоша: «Лучшие товары долины! У тебя 🪙 ${S.money}»</div>`+
    SHOP_ITEMS.map(it=>{
      const full=it.get()>=it.cap, poor=S.money<it.price;
      return `<div class="shop-row">
        <span class="ic">${it.ic}</span>
        <div class="inf"><div class="nm">${it.nm} — 🪙 ${it.price}</div><div class="d">${it.d} · у вас ${it.get()}/${it.cap}</div></div>
        <button data-buy="${it.id}" ${(full||poor)?"disabled":""}>${full?"Максимум":poor?"Дорого":"Купить"}</button>
      </div>`;
    }).join("");
  $("modal").hidden=false;
}
function doBuy(id){
  const it=SHOP_ITEMS.find(s=>s.id===id);
  if(!it||S.money<it.price||it.get()>=it.cap) return;
  S.money-=it.price; it.add();
  SFX.pickup(); renderBadges(); saveGame();
  openShop();
}
function openDex(){
  uiLock=true; held=[];
  $("modal-title").textContent=`📖 Нексопедия — ${S.seen.length}/${DEX_ORDER.length}`;
  $("modal-list").innerHTML = `<div class="dex-grid">`+DEX_ORDER.map(sid=>{
    const sp=SPECIES[sid], seen=S.seen.includes(sid), caught=S.caught.includes(sid);
    const stars="★".repeat(MONART[sid].r);
    return `<div class="dex-cell">
      <div class="dex-icon ${seen?"":"unseen"}">${monSvg(sid)}</div>
      <div class="r">${stars}</div>
      <div class="nm">${seen?sp.name:"???"}</div>
      <div class="cg">${seen?TYPES[sp.type].label:"не встречен"}${caught?" · ✓":""}</div>
    </div>`;
  }).join("")+`</div>`;
  $("modal").hidden=false;
}
$("btn-dex").addEventListener("click",()=>{ if(!inBattle&&S) openDex(); });

/* ================= WORLD RENDER ================= */
const cv = $("world"), g = cv.getContext("2d");
const VIEW_W = cv.width, VIEW_H = cv.height;
const GRASS = {meadow:["#7EC850","#78C24B","#83CD57"], forest:["#5FAE4C","#59A847","#65B452"],
               lake:["#7EC850","#79C24C","#86CE5B"], mountain:["#9DB183","#97AB7D","#A3B789"]};
function roundRect(ctx,x,y,w,h,r){ctx.beginPath(); ctx.roundRect(x,y,w,h,r); }
function drawGround(x,y,sx,sy,t){
  const ch=tileAt(x,y), r=region(x,y);
  const pal=GRASS[r]||GRASS.meadow;
  g.fillStyle = pal[(x*7+y*13)%3];
  g.fillRect(sx,sy,TILE,TILE);
  const gh=(x*31+y*17)%9;
  if(ch==="."){
    if(gh===0){ g.fillStyle="rgba(255,255,255,.09)"; g.beginPath(); g.arc(sx+9,sy+9,2,0,7); g.fill(); }
    else if(gh===4){ g.strokeStyle="rgba(20,80,25,.18)"; g.lineWidth=1.5; g.beginPath(); g.moveTo(sx+20,sy+25); g.lineTo(sx+18,sy+18); g.moveTo(sx+25,sy+25); g.lineTo(sx+26,sy+19); g.stroke(); }
  }
  if(ch===","){
    const cols=["#FF8AB5","#FFD54F","#FFFFFF"];
    g.fillStyle=cols[(x*3+y)%3]; g.beginPath(); g.arc(sx+10,sy+12,3,0,7); g.fill();
    g.fillStyle=cols[(x+y*5+1)%3]; g.beginPath(); g.arc(sx+24,sy+24,3,0,7); g.fill();
    g.fillStyle="rgba(255,255,255,.7)"; g.beginPath(); g.arc(sx+27,sy+9,2,0,7); g.fill();
  }
  if(ch==="-"){
    g.fillStyle="#E8D29A"; g.fillRect(sx,sy,TILE,TILE);
    g.fillStyle="rgba(0,0,0,.07)";
    if(tileAt(x,y-1)!=="-") g.fillRect(sx,sy,TILE,3);
    if(tileAt(x,y+1)!=="-") g.fillRect(sx,sy+TILE-3,TILE,3);
    if(tileAt(x-1,y)!=="-") g.fillRect(sx,sy,3,TILE);
    if(tileAt(x+1,y)!=="-") g.fillRect(sx+TILE-3,sy,3,TILE);
    if((x*11+y*7)%5===0){g.fillStyle="rgba(0,0,0,.08)"; g.beginPath(); g.arc(sx+20,sy+18,2.5,0,7); g.fill();}
  }
  if(ch==="~"){
    g.fillStyle=(x+y)%2===0 ? "#3B93D6" : "#4AA8E8";
    g.fillRect(sx,sy,TILE,TILE);
    const ph=Math.sin(t*2+(x*13+y*7));
    g.strokeStyle="rgba(255,255,255,"+(0.22+0.14*ph).toFixed(2)+")";
    g.lineWidth=2; g.beginPath();
    g.arc(sx+TILE/2, sy+TILE/2+ph*2, 7, Math.PI*0.15, Math.PI*0.85); g.stroke();
    g.fillStyle="rgba(255,255,255,.35)";
    if(tileAt(x,y-1)!=="~") g.fillRect(sx,sy,TILE,3);
    if(tileAt(x,y+1)!=="~") g.fillRect(sx,sy+TILE-3,TILE,3);
    if(tileAt(x-1,y)!=="~") g.fillRect(sx,sy,3,TILE);
    if(tileAt(x+1,y)!=="~") g.fillRect(sx+TILE-3,sy,3,TILE);
  }
  if(ch==="*"){
    const wob = S && ((!S.moving && S.x===x && S.y===y) || (S.moving && S.tx===x && S.ty===y));
    const k = wob ? 1+0.08*Math.sin(t*18) : 1;
    g.fillStyle="#2F8F3B";
    g.beginPath(); g.ellipse(sx+12,sy+23,9*k,8*k,0,0,7); g.fill();
    g.beginPath(); g.ellipse(sx+24,sy+23,9*k,8*k,0,0,7); g.fill();
    g.fillStyle="#3EA94A";
    g.beginPath(); g.ellipse(sx+18,sy+16,10*k,9*k,0,0,7); g.fill();
    g.fillStyle="#5BC763";
    g.beginPath(); g.ellipse(sx+15,sy+13,4,3,0,0,7); g.fill();
  }
  if(ch==="o"){
    g.fillStyle="rgba(0,0,0,.12)"; g.beginPath(); g.ellipse(sx+18,sy+26,10,4,0,0,7); g.fill();
    g.fillStyle="#9AA0A6"; g.beginPath(); g.ellipse(sx+18,sy+19,10,8,0,0,7); g.fill();
    g.fillStyle="#B7BCC2"; g.beginPath(); g.ellipse(sx+15,sy+16,4,3,0,0,7); g.fill();
  }
  if(ch==="F"){
    g.fillStyle="#8D9299"; g.beginPath(); g.arc(sx+18,sy+18,15,0,7); g.fill();
    g.fillStyle="#B7BCC2"; g.beginPath(); g.arc(sx+18,sy+18,12,0,7); g.fill();
    g.fillStyle="#4AA8E8"; g.beginPath(); g.arc(sx+18,sy+18,9,0,7); g.fill();
    const rp=(t*8)%9;
    g.strokeStyle="rgba(255,255,255,.7)"; g.lineWidth=1.5;
    g.beginPath(); g.arc(sx+18,sy+18,rp,0,7); g.stroke();
  }
}
function drawTree(sx,sy,x,y,t){
  const cx=sx+TILE/2;
  g.fillStyle="rgba(0,0,0,.18)"; g.beginPath(); g.ellipse(cx,sy+TILE-4,12,4,0,0,7); g.fill();
  g.fillStyle="#8A5A33"; g.fillRect(cx-4,sy+12,8,18);
  const sway=Math.sin(t+(x*3+y))*1.2;
  g.fillStyle="#2E7D32"; g.beginPath(); g.arc(cx+sway,sy+2,15,0,7); g.fill();
  g.fillStyle="#3CA23F";
  g.beginPath(); g.arc(cx-7+sway,sy+8,10,0,7); g.fill();
  g.beginPath(); g.arc(cx+7+sway,sy+8,10,0,7); g.fill();
  g.fillStyle="#57BB58"; g.beginPath(); g.arc(cx-3+sway,sy-2,6,0,7); g.fill();
}
function drawChar(sx,sy,dir,walking,t,pal){
  const cx=sx+TILE/2;
  const bob = walking ? Math.sin(t*12)*1.5 : 0;
  g.fillStyle="rgba(0,0,0,.25)"; g.beginPath(); g.ellipse(cx,sy+TILE-4,9,3.5,0,0,7); g.fill();
  const lo = walking ? Math.sin(t*12)*3 : 0;
  g.fillStyle="#3E5C76";
  g.fillRect(cx-6, sy+22+bob+(lo>0?1:0), 5, 8-(lo>0?1:0));
  g.fillRect(cx+1, sy+22+bob+(lo<0?1:0), 5, 8-(lo<0?1:0));
  g.fillStyle=pal.body; roundRect(g,cx-8,sy+12+bob,16,13,4); g.fill();
  g.fillStyle="#F2C79B"; g.beginPath(); g.arc(cx,sy+7+bob,8,0,7); g.fill();
  g.fillStyle=pal.cap;
  g.beginPath(); g.arc(cx,sy+5+bob,8,Math.PI,0); g.fill();
  if(dir!=="up"){
    const vx = dir==="left"?-9:dir==="right"?2:-3.5;
    roundRect(g,cx+vx,sy+3+bob,7,3,2); g.fill();
    g.fillStyle="#2C2C2B";
    const eo = dir==="left"?-3:dir==="right"?3:0;
    g.beginPath(); g.arc(cx-3+eo,sy+9+bob,1.3,0,7); g.fill();
    g.beginPath(); g.arc(cx+3+eo,sy+9+bob,1.3,0,7); g.fill();
  }
}
function drawItem(it,t){
  const sx=it.x*TILE, sy=it.y*TILE;
  const bob=Math.sin(t*3+it.x)*2;
  g.fillStyle="rgba(255,255,255,.4)"; g.beginPath(); g.arc(sx+18,sy+18+bob,11,0,7); g.fill();
  g.font="16px serif"; g.textAlign="center"; g.textBaseline="middle";
  g.fillText(it.kind==="potion"?"🧪":"⚪", sx+18, sy+17+bob);
}
function drawMark(sx,sy,t){
  const bob=Math.sin(t*5)*2;
  g.fillStyle="#fff"; g.beginPath(); g.arc(sx+TILE/2,sy-10+bob,7,0,7); g.fill();
  g.fillStyle="#E56458"; g.font="bold 11px sans-serif"; g.textAlign="center"; g.textBaseline="middle";
  g.fillText("!", sx+TILE/2, sy-10+bob);
}
function npcAt(x,y){
  for(const id in TRAINERS){const tr=TRAINERS[id]; if(tr.x===x&&tr.y===y) return id;}
  for(const id in NPCS){const n=NPCS[id]; if(n.x===x&&n.y===y) return id;}
  if(S && S.champDone && !S.legendDone && LEGEND.x===x && LEGEND.y===y) return "legend";
  return null;
}
function draw(t){
  const px=S.rx*TILE, py=S.ry*TILE;
  const camX=clamp(px+TILE/2-VIEW_W/2, 0, MAP_W*TILE-VIEW_W);
  const camY=clamp(py+TILE/2-VIEW_H/2, 0, MAP_H*TILE-VIEW_H);
  const x0=Math.floor(camX/TILE), y0=Math.floor(camY/TILE);
  const x1=Math.min(MAP_W-1, Math.ceil((camX+VIEW_W)/TILE));
  const y1=Math.min(MAP_H-1, Math.ceil((camY+VIEW_H)/TILE));
  g.save(); g.translate(-camX,-camY);
  for(let y=y0;y<=y1;y++)for(let x=x0;x<=x1;x++) drawGround(x,y,x*TILE,y*TILE,t);
  for(const it of WORLD_ITEMS){
    if(S.picked.includes(it.id)) continue;
    if(it.x<x0-1||it.x>x1+1||it.y<y0-1||it.y>y1+1) continue;
    drawItem(it,t);
  }
  if(S.champDone && !S.legendDone && LEGEND.x>=x0-1&&LEGEND.x<=x1+1&&LEGEND.y>=y0-1&&LEGEND.y<=y1+1){
    const lb=Math.sin(t*4)*3;
    g.fillStyle="rgba(255,213,79,.35)"; g.beginPath(); g.arc(LEGEND.x*TILE+18,LEGEND.y*TILE+18+lb,13,0,7); g.fill();
    g.font="20px serif"; g.textAlign="center"; g.textBaseline="middle";
    g.fillText("🌟", LEGEND.x*TILE+18, LEGEND.y*TILE+17+lb);
  }
  const prow=Math.floor(S.ry+0.5);
  for(let y=y0;y<=Math.min(MAP_H-1,y1+1);y++){
    for(let x=x0;x<=x1;x++) if(tileAt(x,y)==="#") drawTree(x*TILE,y*TILE,x,y,t);
    for(const id in TRAINERS){
      const tr=TRAINERS[id];
      if(tr.y!==y || tr.x<x0-1||tr.x>x1+1) continue;
      drawChar(tr.x*TILE,tr.y*TILE,"down",false,0,tr.pal);
      if(!S.beaten.includes(id)) drawMark(tr.x*TILE,tr.y*TILE,t);
    }
    for(const id in NPCS){
      const n=NPCS[id];
      if(n.y!==y || n.x<x0-1||n.x>x1+1) continue;
      drawChar(n.x*TILE,n.y*TILE,"down",false,0,n.pal);
    }
    if(prow===y) drawChar(px,py,S.dir,S.moving,t,{cap:"#E56458",body:"#2783DE"});
  }
  g.restore();
  if(!draw.vg){
    const v=g.createRadialGradient(VIEW_W/2,VIEW_H/2,VIEW_H/2.4,VIEW_W/2,VIEW_H/2,VIEW_W/1.05);
    v.addColorStop(0,"rgba(0,0,0,0)"); v.addColorStop(1,"rgba(10,30,12,.28)");
    const s=g.createLinearGradient(0,0,0,VIEW_H*0.5);
    s.addColorStop(0,"rgba(255,244,200,.10)"); s.addColorStop(1,"rgba(255,244,200,0)");
    draw.vg=v; draw.sun=s;
  }
  g.fillStyle=draw.sun; g.fillRect(0,0,VIEW_W,VIEW_H*0.5);
  g.fillStyle=draw.vg; g.fillRect(0,0,VIEW_W,VIEW_H);
}

/* ================= WORLD LOGIC ================= */
const DIRS={up:[0,-1],down:[0,1],left:[-1,0],right:[1,0]};
function isBlocked(x,y){
  const ch=tileAt(x,y);
  return "#~F".includes(ch) || !!npcAt(x,y);
}
function attempt(dir){
  S.dir=dir;
  const [dx,dy]=DIRS[dir];
  const nx=S.x+dx, ny=S.y+dy;
  const npc=npcAt(nx,ny);
  const now=performance.now();
  if(npc){ if(now-lastBump>700){lastBump=now; bumpNpc(npc);} return; }
  if(tileAt(nx,ny)==="F"){ if(now-lastBump>1200){lastBump=now; fountainHeal();} return; }
  if(isBlocked(nx,ny)) return;
  S.moving=true; S.tx=nx; S.ty=ny; S.moveT=0;
}
function update(dt){
  if(S.moving){
    S.moveT+=dt*5.5;
    if(S.moveT>=1){S.x=S.tx; S.y=S.ty; S.rx=S.x; S.ry=S.y; S.moving=false; onArrive();}
    else {S.rx=S.x+(S.tx-S.x)*S.moveT; S.ry=S.y+(S.ty-S.y)*S.moveT;}
  }
  if(!S.moving && !uiLock && !inBattle && held.length) attempt(held[held.length-1]);
}
function onArrive(){
  stepsSinceBattle++;
  const it=WORLD_ITEMS.find(i=>i.x===S.x&&i.y===S.y&&!S.picked.includes(i.id));
  if(it){
    S.picked.push(it.id);
    SFX.pickup();
    if(it.kind==="potion"){S.potions=Math.min(9,S.potions+2); showMsg("Найдены зелья! 🧪 +2");}
    else {S.balls=Math.min(9,S.balls+2); showMsg("Найдены монстроболы! ⚪ +2");}
    renderBadges(); saveGame();
  }
  if(tileAt(S.x,S.y)==="*" && stepsSinceBattle>=2 && Math.random()<0.16){
    stepsSinceBattle=0; uiLock=true; held=[];
    $("flash").classList.add("on");
    setTimeout(()=>{
      $("flash").classList.remove("on");
      beginBattle("wild", region(S.x,S.y));
    },520);
  }
}
function fountainHeal(){
  S.team.forEach(m=>{m.hp=m.maxHp; delete m.status; m.moves.forEach(v=>{if(v.maxPp)v.pp=v.maxPp;});});
  renderHud(); saveGame();
  SFX.heal();
  showMsg("⛲ Фонтан исцеляет команду: ОЗ, PP и статусы восстановлены!");
}
function bumpNpc(id){
  if(id==="shop"){ openShop(); return; }
  if(id==="zina"){
    if(S.zinaDone){ showMsg("Зина: «Спасибо ещё раз, заходи в гости!»"); return; }
    if(S.team.some(m=>m.type==="water")){
      S.zinaDone=true; S.money+=300; S.potions=Math.min(9,S.potions+2);
      renderBadges(); saveGame(); SFX.victory();
      showMsg("Зина: «Водный монстр! Мечта всей жизни! Держи 300 монет и зелья!»", 3800);
    } else {
      showMsg("Зина: «Всю жизнь мечтаю увидеть водного монстра… Поймаешь — покажи, награжу!»", 3400);
    }
    return;
  }
  if(id==="legend"){
    uiLock=true; held=[];
    showMsg("🌟 Легендарный Нексолар пробуждается!", 1500);
    $("flash").classList.add("on");
    setTimeout(()=>{ $("flash").classList.remove("on"); beginBattle("legend","mountain"); }, 700);
    return;
  }
  const tr=TRAINERS[id];
  if(S.beaten.includes(id)){ showMsg(tr.beatenMsg); return; }
  showMsg(tr.intro, 1600);
  uiLock=true; held=[];
  setTimeout(()=>beginBattle("trainer", id==="maks"?"mountain":(id==="borya"?"forest":"meadow"), id), 1400);
}

/* ================= INPUT ================= */
const KEYMAP={ArrowUp:"up",ArrowDown:"down",ArrowLeft:"left",ArrowRight:"right",
  w:"up",s:"down",a:"left",d:"right",ц:"up",ы:"down",ф:"left",в:"right",
  W:"up",S:"down",A:"left",D:"right"};
window.addEventListener("keydown",e=>{
  const dir=KEYMAP[e.key];
  if(!dir) return;
  e.preventDefault();
  if(!held.includes(dir)) held.push(dir);
});
window.addEventListener("keyup",e=>{
  const dir=KEYMAP[e.key];
  if(!dir) return;
  held=held.filter(d=>d!==dir);
});
window.addEventListener("blur",()=>{held=[];});
$("dpad").querySelectorAll("button[data-dir]").forEach(b=>{
  const dir=b.dataset.dir;
  const on=e=>{e.preventDefault(); if(!held.includes(dir)) held.push(dir);};
  const off=()=>{held=held.filter(d=>d!==dir);};
  b.addEventListener("pointerdown",on);
  b.addEventListener("pointerup",off);
  b.addEventListener("pointercancel",off);
  b.addEventListener("pointerleave",off);
});
