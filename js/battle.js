"use strict";
/* ================= BATTLE ================= */
let enemy=null, enemyTeam=[], enemyIdx=0, battleKind="wild", battleZone="meadow";
let curTrainerId=null, activeIdx=0, busy=false, logLines=[];
const curTrainer=()=>curTrainerId?TRAINERS[curTrainerId]:null;

function setTypeChip(el,type){ el.textContent=TYPES[type].label; el.className="type "+TYPES[type].cls; }
function renderMon(side,m){
  $(side+"-sprite").innerHTML=monSvg(m.sid);
  $(side+"-name").textContent=m.name;
  renderStatus(side,m);
  setTypeChip($(side+"-type"),m.type);
  renderHpBar(side,m);
}
function renderStatus(side,m){
  $(side+"-lvl").innerHTML="ур. "+m.level+(m.status?` <span class="status-tag status-${m.status.k}">${STATUS[m.status.k].tag}</span>`:"");
}
function renderHpBar(side,m){
  const pct=Math.max(0,m.hp/m.maxHp*100);
  const fill=$(side+"-hp");
  fill.style.width=pct+"%";
  fill.className="fill"+(pct<=25?" low":pct<=55?" mid":"");
  $(side+"-hptext").textContent=Math.max(0,m.hp)+" / "+m.maxHp+" ОЗ";
}
function renderExp(){
  const m=S.team[activeIdx];
  $("player-exp").style.width=Math.min(100,m.exp/expNeed(m.level)*100)+"%";
}
function renderDots(){
  $("enemy-dots").textContent = battleKind==="trainer"
    ? enemyTeam.map((m,i)=> (i<enemyIdx||m.hp<=0)?"○":"●").join("")
    : "";
}
function blog(msg){
  logLines.push(msg);
  const last3=logLines.slice(-3);
  $("log").innerHTML=last3.map((l,i)=>`<div class="${i===last3.length-1?"last":""}">${l}</div>`).join("");
}
function floatDmg(side,text,color){
  const holder=$(side+"-sprite");
  const el=document.createElement("span");
  el.className="float-dmg"; el.textContent=text; el.style.color=color;
  el.style.left=(holder.offsetLeft+20)+"px";
  el.style.top=(holder.offsetTop-10)+"px";
  $("arena").appendChild(el);
  setTimeout(()=>el.remove(),900);
}
async function animate(el,cls){
  el.classList.remove(cls); void el.offsetWidth;
  el.classList.add(cls);
  await sleep(400);
  el.classList.remove(cls);
}
function controlsHTML(html){ $("controls").innerHTML=html; }
function mainMenu(){
  if(!enemy) return;
  const wild=battleKind==="wild"||battleKind==="legend";
  const canGold=wild&&S.goldballs>0&&S.team.length<6;
  const canSwitch=S.team.some((m,i)=>i!==activeIdx&&m.hp>0);
  const canCatch=wild&&S.balls>0&&S.team.length<6;
  const catchMeta=!wild?"только дикие монстры":S.team.length>=6?"команда полна":S.balls<=0?"нет монстроболов":`шанс выше при низких ОЗ · ⚪ ${S.balls}`;
  controlsHTML(`
    <div class="btn-grid">
      <button class="btn primary wide" data-act="attack">⚔️ Атака<span class="meta">выбрать приём</span></button>
      <button class="btn" data-act="catch" ${canCatch?"":"disabled"}>⚪ Поймать<span class="meta">${catchMeta}</span></button>
      ${canGold?`<button class="btn" data-act="gold">🟡 Золотой бол<span class="meta">поимка гарантирована · осталось ${S.goldballs}`+`</span></button>`:""}
      <button class="btn" data-act="potion" ${S.potions>0?"":"disabled"}>🧪 Зелье<span class="meta">+60% ОЗ · осталось ${S.potions}</span></button>
      <button class="btn" data-act="switch" ${canSwitch?"":"disabled"}>🔄 Смена<span class="meta">другой монстр</span></button>
      <button class="btn" data-act="run" ${wild?"":"disabled"}>🏃 Побег<span class="meta">${wild?"шанс зависит от скорости":"от тренера не сбежать"}</span></button>
    </div>`);
}
function moveMenu(){
  const p=S.team[activeIdx];
  const noPp=p.moves.every(mv=>mv.maxPp&&mv.pp<=0);
  controlsHTML(`
    <div class="btn-grid">
      ${p.moves.map((mv,i)=>{
        const eff=EFF[mv.type][enemy.type];
        const hint=eff>1?"суперэффективно!":eff<1?"не очень эффективно":"обычный урон";
        const out=mv.maxPp&&mv.pp<=0;
        return `<button class="btn" data-move="${i}" ${out?"disabled":""}>${TYPES[mv.type].label.split(" ")[0]} ${mv.name}<span class="meta">сила ${mv.power} · PP ${mv.pp}/${mv.maxPp} · ${hint}</span></button>`;
      }).join("")}
      ${noPp?`<button class="btn" data-move="s">💢 ${STRUGGLE.name}<span class="meta">когда PP закончились</span></button>`:""}
      <button class="btn back" data-act="back">← Назад</button>
    </div>`);
}
function switchMenu(forced){
  controlsHTML(`
    <div class="btn-grid">
      ${S.team.map((m,i)=>{
        const dis=i===activeIdx||m.hp<=0;
        return `<button class="btn" data-switch="${i}" ${dis?"disabled":""}>${m.emoji} ${m.name}<span class="meta">ур. ${m.level} · ${Math.max(0,m.hp)}/${m.maxHp} ОЗ${i===activeIdx?" · в бою":""}</span></button>`;
      }).join("")}
      ${forced?"":'<button class="btn back" data-act="back">← Назад</button>'}
    </div>`);
  if(forced) $("controls").dataset.forced="1";
  else delete $("controls").dataset.forced;
}
$("controls").addEventListener("click",e=>{
  const btn=e.target.closest("button");
  if(!btn||btn.disabled||busy) return;
  SFX.click();
  const forced=$("controls").dataset.forced==="1";
  if(btn.dataset.act==="attack") moveMenu();
  else if(btn.dataset.act==="switch") switchMenu(false);
  else if(btn.dataset.act==="back") mainMenu();
  else if(btn.dataset.act==="potion") playerTurn({type:"potion"});
  else if(btn.dataset.act==="catch") playerTurn({type:"catch"});
  else if(btn.dataset.act==="run") playerTurn({type:"run"});
  else if(btn.dataset.act==="gold") playerTurn({type:"gold"});
  else if(btn.dataset.move!==undefined) playerTurn({type:"move",idx:btn.dataset.move});
  else if(btn.dataset.switch!==undefined){
    if(forced) doForcedSwitch(+btn.dataset.switch);
    else playerTurn({type:"switch",idx:+btn.dataset.switch});
  }
  else if(btn.dataset.next!==undefined){ /* handled elsewhere */ }
});

function beginBattle(kind, zone, trainerId){
  inBattle=true; busy=false; held=[]; uiLock=false;
  SFX.encounter(); playMusic((kind==="legend"||(trainerId&&TRAINERS[trainerId].champion))?"final":"battle");
  battleKind=kind; battleZone=zone; curTrainerId=trainerId||null;
  logLines=[]; enemyIdx=0;
  $("arena").className="arena zone-"+zone;
  if(kind==="wild"){
    const e=ENCOUNTERS[zone];
    enemyTeam=[newMon(choice(e.mons), randInt(e.lv[0],e.lv[1]))];
  } else if(kind==="legend"){
    enemyTeam=[newMon("nexolar",16)];
  } else {
    enemyTeam=curTrainer().team.map(([s,l])=>newMon(s,l));
  }
  activeIdx=Math.max(0,S.team.findIndex(m=>m.hp>0));
  showScreen("screen-battle");
  $("player-sprite").classList.remove("faint");
  renderMon("player",S.team[activeIdx]); renderExp();
  sendEnemy(true);
  blog(kind==="wild"
    ? `Дикий ${enemy.name} выпрыгивает из кустов! (${ENCOUNTERS[zone].title})`
    : kind==="legend"
    ? `🌟 Легендарный ${enemy.name} принимает бой!`
    : `${curTrainer().name} выпускает ${enemy.name}!`);
  blog(`Вперёд, ${S.team[activeIdx].name}!`);
  mainMenu();
}
function sendEnemy(silent){
  enemy=enemyTeam[enemyIdx];
  if(!S.seen.includes(enemy.sid)) S.seen.push(enemy.sid);
  $("enemy-sprite").classList.remove("faint");
  renderMon("enemy",enemy);
  renderDots();
  if(!silent) blog(`${curTrainer().name} выпускает ${enemy.name}!`);
}
async function useMove(att,def,move,attSide){
  const defSide=attSide==="player"?"enemy":"player";
  const who=attSide==="player"?att.name:"Вражеский "+att.name;
  blog(`${who} использует «${move.name}»!`);
  if(move.maxPp) move.pp=Math.max(0,move.pp-1);
  SFX.skill(move.type);
  const srcPos=arenaPos($(attSide+"-sprite"));
  fxParticles(srcPos.x,srcPos.y,move.type,8);
  const lunge=animate($(attSide+"-sprite"),attSide==="player"?"lungeL":"lungeR");
  await sleep(120);
  await fxProjectile(attSide,defSide,move.type);
  const {dmg,eff}=calcDamage(att,def,move);
  def.hp=Math.max(0,def.hp-dmg);
  const tgtPos=arenaPos($(defSide+"-sprite"));
  fxBurst(tgtPos.x,tgtPos.y,move.type);
  fxParticles(tgtPos.x,tgtPos.y,move.type,16);
  fxHitFlash(defSide);
  if(eff>1) SFX.superhit(); else if(eff<1) SFX.weakhit(); else SFX.hit();
  if(eff>=1) fxShake();
  await lunge;
  await animate($(defSide+"-sprite"),"shake");
  floatDmg(defSide,"-"+dmg, eff>1?"#C2402F":eff<1?"#57544E":"#2C2C2B");
  renderHpBar(defSide,def);
  if(eff>1) blog("Это суперэффективно! 💥");
  if(eff<1) blog("Не очень эффективно…");
  if(move.st && def.hp>0 && !def.status && Math.random()<move.st.ch){
    def.status={k:move.st.k, t:move.st.k==="slp"?randInt(2,3):99};
    blog(`${def.name} ${STATUS[move.st.k].msg}`);
    renderStatus(defSide,def);
    await sleep(500);
  }
  await sleep(500);
}
function pickMove(p,idx){ return idx==="s"?{...STRUGGLE}:p.moves[+idx]; }
async function canAct(m,side){
  if(!m.status) return true;
  if(m.status.k==="slp"){
    m.status.t--;
    if(m.status.t<=0){ delete m.status; renderStatus(side,m); blog(`${m.name} просыпается!`); await sleep(500); return true; }
    blog(`${m.name} крепко спит… 💤`); await sleep(600); return false;
  }
  if(m.status.k==="par" && Math.random()<0.25){ blog(`${m.name} парализован и не может двигаться! ⚡`); await sleep(600); return false; }
  return true;
}
async function statusTick(m,side){
  if(!m.status||m.status.k!=="psn"||m.hp<=0) return;
  const d=Math.ceil(m.maxHp/8);
  m.hp=Math.max(0,m.hp-d);
  const pp=arenaPos($(side+"-sprite"));
  fxParticles(pp.x,pp.y,"grass",8);
  floatDmg(side,"-"+d,"#7B3FA0");
  blog(`${m.name} страдает от яда! ☠️`);
  renderHpBar(side,m);
  await sleep(500);
}
async function playerTurn(action){
  busy=true;
  controlsHTML('<div style="padding:8px 2px;color:var(--text2);font-size:14px">…</div>');
  const p=S.team[activeIdx];
  let playerFirst=true;

  if(action.type==="move"){
    playerFirst=effSpd(p)>=effSpd(enemy);
  } else if(action.type==="potion"){
    S.potions--;
    const heal=Math.ceil(p.maxHp*0.6);
    p.hp=Math.min(p.maxHp,p.hp+heal);
    renderHpBar("player",p); renderBadges();
    SFX.heal();
    const hpPos=arenaPos($("player-sprite"));
    fxParticles(hpPos.x,hpPos.y,"heal",14);
    floatDmg("player","+"+heal,"#2E7D4F");
    blog(`Вы использовали зелье — ${p.name} восстанавливает силы!`);
    await sleep(600);
  } else if(action.type==="switch"){
    activeIdx=action.idx;
    $("player-sprite").classList.remove("faint");
    renderMon("player",S.team[activeIdx]); renderExp();
    blog(`Вы выпускаете ${S.team[activeIdx].name}!`);
    await sleep(600);
  } else if(action.type==="catch"||action.type==="gold"){
    const gold=action.type==="gold";
    if(gold) S.goldballs--; else S.balls--;
    renderBadges();
    blog(gold?"Вы бросаете ЗОЛОТОЙ монстробол… 🟡":"Вы бросаете монстробол… ⚪");
    SFX.throwBall();
    await fxProjectile("player","enemy","normal",gold?"🟡":"⚪");
    for(let w=0;w<2;w++){ SFX.wobble(); await animate($("enemy-sprite"),"shake"); await sleep(120); }
    let chance=0.15+0.75*(1-enemy.hp/enemy.maxHp);
    if(enemy.sid==="nexolar") chance*=0.35;
    if(gold) chance=1;
    if(Math.random()<chance){
      SFX.catchOk();
      const cp=arenaPos($("enemy-sprite"));
      fxBurst(cp.x,cp.y,"gold"); fxParticles(cp.x,cp.y,"gold",20);
      blog(`Есть! ${enemy.name} пойман и вступает в команду! 🎉`);
      $("enemy-sprite").classList.add("faint");
      const caught=enemy;
      caught.hp=Math.max(1,Math.ceil(caught.maxHp*0.5));
      delete caught.status;
      S.team.push(caught);
      if(!S.caught.includes(caught.sid)) S.caught.push(caught.sid);
      if(!S.seen.includes(caught.sid)) S.seen.push(caught.sid);
      if(caught.sid==="nexolar") S.legendDone=true;
      await sleep(1200);
      busy=false;
      return finishBattle("catch");
    } else {
      SFX.catchFail();
      blog(`${enemy.name} вырвался из шара!`);
      await sleep(600);
    }
  } else if(action.type==="run"){
    const chance=clamp(0.55+(p.spd-enemy.spd)*0.04,0.35,0.95);
    if(Math.random()<chance){
      SFX.run();
      blog("Вы успешно сбежали! 🏃");
      await sleep(800);
      busy=false;
      return finishBattle("run");
    }
    blog("Сбежать не удалось!");
    await sleep(500);
  }

  const doPlayerMove=async()=>{
    const me=S.team[activeIdx];
    if(await canAct(me,"player")){
      await useMove(me,enemy,pickMove(me,action.idx),"player");
    }
    await statusTick(me,"player");
  };
  if(action.type==="move" && playerFirst){
    await doPlayerMove();
    if(enemy.hp<=0){busy=false; return enemyFainted();}
    if(S.team[activeIdx].hp<=0){busy=false; return playerFainted();}
  }
  if(enemy.hp>0){
    await enemyMove();
    if(S.team[activeIdx].hp<=0){busy=false; return playerFainted();}
    if(enemy.hp<=0){busy=false; return enemyFainted();}
  }
  if(action.type==="move" && !playerFirst && enemy.hp>0){
    await doPlayerMove();
    if(enemy.hp<=0){busy=false; return enemyFainted();}
    if(S.team[activeIdx].hp<=0){busy=false; return playerFainted();}
  }
  busy=false;
  mainMenu();
}
async function enemyMove(){
  const p=S.team[activeIdx];
  if(await canAct(enemy,"enemy")){
    const avail=enemy.moves.filter(mv=>!mv.maxPp||mv.pp>0);
    let move;
    if(!avail.length) move={...STRUGGLE};
    else if(Math.random()<0.7){
      move=avail.reduce((best,mv)=>
        mv.power*EFF[mv.type][p.type]>best.power*EFF[best.type][p.type]?mv:best);
    } else move=choice(avail);
    await useMove(enemy,p,move,"enemy");
  }
  await statusTick(enemy,"enemy");
}
async function giveExp(mon,lvl){
  const gain=12+lvl*7;
  blog(`${mon.name} получает ${gain} опыта!`);
  mon.exp+=gain;
  renderExp();
  await sleep(600);
  while(mon.exp>=expNeed(mon.level) && mon.level<20){
    mon.exp-=expNeed(mon.level);
    mon.level++;
    applyLevel(mon);
    SFX.levelup();
    const lvPos=arenaPos($("player-sprite"));
    fxBurst(lvPos.x,lvPos.y,"gold"); fxParticles(lvPos.x,lvPos.y,"gold",16);
    blog(`⬆️ ${mon.name} достигает уровня ${mon.level}!`);
    renderMon("player",mon); renderExp();
    await sleep(650);
    const learnKey=SPECIES[mon.sid].learn && SPECIES[mon.sid].learn[mon.level];
    if(learnKey && mon.moves.length<4 && !mon.moves.some(m=>m.key===learnKey)){
      mon.moves.push(mkMove(learnKey));
      blog(`📖 ${mon.name} выучил приём «${MOVES[learnKey].name}»!`);
      await sleep(650);
    }
    const ev=SPECIES[mon.sid].evolve;
    if(ev && mon.level>=ev.lvl){
      const old=mon.name, nb=SPECIES[ev.to];
      const pct=mon.hp/mon.maxHp;
      mon.sid=ev.to; mon.name=nb.name; mon.emoji=nb.emoji; mon.type=nb.type;
      if(!S.seen.includes(mon.sid)) S.seen.push(mon.sid);
      if(!S.caught.includes(mon.sid)) S.caught.push(mon.sid);
      const st=statsFor(mon.sid,mon.level);
      mon.maxHp=st.maxHp; mon.atk=st.atk; mon.def=st.def; mon.spd=st.spd;
      mon.hp=Math.max(1,Math.round(st.maxHp*pct));
      SFX.evolve();
      const evPos=arenaPos($("player-sprite"));
      fxBurst(evPos.x,evPos.y,"gold"); fxParticles(evPos.x,evPos.y,"gold",26); fxParticles(evPos.x,evPos.y,"electric",10);
      blog(`✨ ${old} эволюционирует в ${mon.name}!`);
      renderMon("player",mon);
      await sleep(900);
    }
  }
  renderExp();
}
async function enemyFainted(){
  SFX.faint();
  $("enemy-sprite").classList.add("faint");
  renderDots();
  blog(`${enemy.name} повержен!`);
  await sleep(700);
  await giveExp(S.team[activeIdx],enemy.level);
  if(battleKind!=="trainer"){
    const coins=10+enemy.level*3;
    S.money+=coins; renderBadges();
    blog(`🪙 Вы получаете ${coins} монет!`);
    await sleep(500);
  }
  if(battleKind==="trainer" && enemyIdx<enemyTeam.length-1){
    enemyIdx++;
    sendEnemy();
    await sleep(500);
    mainMenu();
    return;
  }
  if(battleKind==="trainer"){
    const tr=curTrainer();
    if(!S.beaten.includes(curTrainerId)) S.beaten.push(curTrainerId);
    if(tr.reward){
      if(tr.reward.potions){S.potions=Math.min(9,S.potions+tr.reward.potions); blog(`🎁 Награда: зелья ×${tr.reward.potions}!`);}
      if(tr.reward.balls){S.balls=Math.min(9,S.balls+tr.reward.balls); blog(`🎁 Награда: монстроболы ×${tr.reward.balls}!`);}
      if(tr.reward.money){S.money+=tr.reward.money; blog(`🪙 Награда: ${tr.reward.money} монет!`);}
      renderBadges();
      await sleep(900);
    }
    if(tr.champion){
      S.champDone=true;
      saveGame();
      return endGame(true);
    }
  }
  finishBattle("win");
}
async function playerFainted(){
  SFX.faint();
  $("player-sprite").classList.add("faint");
  blog(`${S.team[activeIdx].name} больше не может сражаться!`);
  await sleep(800);
  if(S.team.some(m=>m.hp>0)){
    blog("Выберите следующего монстра.");
    switchMenu(true);
  } else {
    blog("Вся команда выбыла…");
    await sleep(900);
    S.team.forEach(m=>{m.hp=m.maxHp;});
    S.x=S.tx=6; S.y=S.ty=25; S.rx=6; S.ry=25; S.moving=false;
    finishBattle("loss");
  }
}
function doForcedSwitch(i){
  activeIdx=i;
  $("player-sprite").classList.remove("faint");
  renderMon("player",S.team[activeIdx]); renderExp();
  blog(`Вперёд, ${S.team[activeIdx].name}!`);
  mainMenu();
}
function finishBattle(outcome){
  inBattle=false; enemy=null; uiLock=false; held=[];
  S.team.forEach(m=>{delete m.status;});
  playMusic("world");
  renderHud(); renderBadges(); saveGame();
  showScreen("screen-world");
  if(outcome==="loss") showMsg("Вы очнулись у фонтана. Команда здорова!");
  else if(outcome==="catch") showMsg("Новый монстр в команде! 🎉");
  else if(outcome==="run") showMsg("Вы сбежали из боя.");
  else if(battleKind==="trainer") showMsg(curTrainer().beatenMsg);
  else showMsg("Победа! ✨");
}
function endGame(victory){
  inBattle=false; uiLock=false;
  S.team.forEach(m=>{delete m.status;});
  playMusic(null);
  if(victory) SFX.victory();
  showScreen("screen-end");
  $("end-emoji").textContent=victory?"🏆":"💫";
  $("end-title").textContent=victory?"Вы — новый чемпион долины Нексо!":"Поражение…";
  $("end-text").textContent=victory
    ? "Чемпион Макс признал ваше мастерство. Можете продолжить исследовать долину, ловить монстров и прокачивать команду!"
    : "Попробуйте ещё раз!";
  $("end-team").innerHTML=S.team.map(m=>
    `<div class="team-chip"><span class="e">${m.emoji}</span><div><div>${m.name}</div><div class="d">ур. ${m.level}</div></div></div>`).join("");
}

/* ================= GAME LOOP ================= */
let lastTs=0;
function loop(ts){
  rafId=requestAnimationFrame(loop);
  const dt=Math.min(0.05,(ts-lastTs)/1000)||0;
  lastTs=ts;
  if(S && !inBattle && $("screen-world").classList.contains("active")){
    update(dt);
    draw(ts/1000);
  }
}
function enterWorld(){
  renderBadges(); renderHud();
  playMusic("world");
  showScreen("screen-world");
  draw(performance.now()/1000);
  if(!rafId) rafId=requestAnimationFrame(loop);
}

/* ================= INIT ================= */
function renderStarters(){
  const starters=["flamis","aquarik","listvik"];
  $("starters").innerHTML=starters.map(sid=>{
    const s=SPECIES[sid];
    return `<button class="starter" data-sid="${sid}">
      <span class="sprite">${monSvg(sid)}</span>
      <div class="name">${s.name}</div>
      <span class="type ${TYPES[s.type].cls}">${TYPES[s.type].label}</span>
      <div style="margin-top:8px;font-size:13px;color:var(--text2)">${s.desc}</div>
    </button>`;
  }).join("");
}
$("starters").addEventListener("click",e=>{
  const btn=e.target.closest(".starter");
  if(!btn) return;
  S=defaultState(btn.dataset.sid);
  saveGame();
  enterWorld();
  showMsg("Добро пожаловать! Ищите монстров в тёмных кустах 🌿", 3200);
});
$("btn-continue").addEventListener("click",()=>{
  const st=loadGame();
  if(st){S=st; enterWorld(); showMsg("С возвращением в долину Нексо!");}
});
$("btn-continue-world").addEventListener("click",()=>{ enterWorld(); });
$("btn-newgame").addEventListener("click",()=>{
  try{localStorage.removeItem(SAVE_KEY);}catch(e){}
  S=null;
  $("continue-row").hidden=true;
  showScreen("screen-start");
});
renderStarters();
if(loadGame()) $("continue-row").hidden=false;

/* QA hooks */
if(location.hash==="#qa"){
  S=defaultState("flamis");
  enterWorld();
} else if(location.hash==="#qabattle"){
  S=defaultState("flamis");
  enterWorld();
  beginBattle("wild","meadow");
}
