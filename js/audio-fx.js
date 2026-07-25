"use strict";
/* ================= AUDIO ================= */
let auCtx=null, auMaster=null, auMusic=null, auMuted=false, auTrack=null, auTimer=null, auStep=0;
const NOTE=m=>440*Math.pow(2,(m-69)/12);
function auEnsure(){
  if(auCtx) return true;
  try{ auCtx=new (window.AudioContext||window.webkitAudioContext)(); }catch(e){ return false; }
  auMaster=auCtx.createGain(); auMaster.gain.value=0.5; auMaster.connect(auCtx.destination);
  auMusic=auCtx.createGain(); auMusic.gain.value=0.3; auMusic.connect(auMaster);
  return true;
}
function tone(o){
  if(!auCtx||auMuted) return;
  const {f=440,t=0,dur=0.15,type="square",vol=0.3,slide=0,dest=auMaster}=o;
  const st=auCtx.currentTime+t;
  const osc=auCtx.createOscillator(), gn=auCtx.createGain();
  osc.type=type; osc.frequency.setValueAtTime(f,st);
  if(slide) osc.frequency.exponentialRampToValueAtTime(Math.max(30,f+slide),st+dur);
  gn.gain.setValueAtTime(0.0001,st);
  gn.gain.exponentialRampToValueAtTime(vol,st+0.012);
  gn.gain.exponentialRampToValueAtTime(0.0001,st+dur);
  osc.connect(gn); gn.connect(dest);
  osc.start(st); osc.stop(st+dur+0.05);
}
function noiseHit(o){
  if(!auCtx||auMuted) return;
  const {t=0,dur=0.18,vol=0.3,freq=1000,dest=auMaster}=o||{};
  const st=auCtx.currentTime+t;
  const buf=auCtx.createBuffer(1,Math.max(1,(auCtx.sampleRate*dur)|0),auCtx.sampleRate);
  const d=buf.getChannelData(0);
  for(let i=0;i<d.length;i++) d[i]=Math.random()*2-1;
  const src=auCtx.createBufferSource(); src.buffer=buf;
  const flt=auCtx.createBiquadFilter(); flt.type="lowpass"; flt.frequency.value=freq;
  const gn=auCtx.createGain();
  gn.gain.setValueAtTime(vol,st); gn.gain.exponentialRampToValueAtTime(0.0001,st+dur);
  src.connect(flt); flt.connect(gn); gn.connect(dest);
  src.start(st);
}
const THEMES={
  world:{bpm:104,steps:16,bassType:"triangle",bassVol:.30,melType:"triangle",melVol:.22,hat:false,
    bass:[48,0,0,55, 53,0,0,55, 45,0,0,52, 50,0,55,0],
    mel: [72,0,76,79, 0,76,0,74, 72,0,69,0, 67,69,72,0]},
  battle:{bpm:148,steps:16,bassType:"sawtooth",bassVol:.24,melType:"square",melVol:.13,hat:true,
    bass:[45,45,0,45, 48,0,45,0, 43,43,0,43, 50,0,48,47],
    mel: [69,0,72,69, 74,0,72,69, 67,0,70,67, 74,72,70,67]},
  final:{bpm:158,steps:16,bassType:"sawtooth",bassVol:.26,melType:"square",melVol:.14,hat:true,
    bass:[40,40,0,47, 45,0,43,0, 48,48,0,45, 43,45,47,0],
    mel: [76,0,79,76, 81,0,79,76, 74,0,77,74, 79,77,76,72]}
};
function playMusic(name){
  auTrack=name;
  if(auTimer){ clearInterval(auTimer); auTimer=null; }
  if(!name||!auCtx||auMuted) return;
  const th=THEMES[name], dur=60/th.bpm/2;
  auStep=0;
  auTimer=setInterval(()=>{
    if(document.hidden) return;
    const i=auStep%th.steps;
    if(th.bass[i]) tone({f:NOTE(th.bass[i]),dur:dur*0.9,type:th.bassType,vol:th.bassVol,dest:auMusic});
    if(th.mel[i]) tone({f:NOTE(th.mel[i]),dur:dur*0.95,type:th.melType,vol:th.melVol,dest:auMusic});
    if(th.hat&&i%2===0) noiseHit({dur:0.03,vol:0.07,freq:6000,dest:auMusic});
    auStep++;
  },dur*1000);
}
const SFX={
  click(){ tone({f:700,dur:.05,type:"square",vol:.12}); },
  pickup(){ tone({f:784,dur:.08,type:"square",vol:.2}); tone({f:1175,t:.09,dur:.14,type:"square",vol:.2}); },
  heal(){ [523,659,784].forEach((f,i)=>tone({f,t:i*.1,dur:.16,type:"triangle",vol:.25})); },
  hit(){ noiseHit({dur:.14,vol:.35,freq:900}); tone({f:170,dur:.12,type:"square",vol:.28,slide:-90}); },
  superhit(){ noiseHit({dur:.24,vol:.5,freq:1500}); tone({f:130,dur:.2,type:"square",vol:.35,slide:-70}); tone({f:95,t:.06,dur:.22,type:"sawtooth",vol:.3,slide:-50}); },
  weakhit(){ noiseHit({dur:.08,vol:.18,freq:600}); },
  skill(type){
    if(type==="fire"){ noiseHit({dur:.3,vol:.22,freq:2500}); tone({f:220,dur:.3,type:"sawtooth",vol:.16,slide:300}); }
    else if(type==="water"){ [420,530,640].forEach((f,i)=>tone({f,t:i*.06,dur:.09,type:"sine",vol:.22,slide:80})); }
    else if(type==="grass"){ tone({f:330,dur:.18,type:"triangle",vol:.2,slide:180}); tone({f:495,t:.09,dur:.16,type:"triangle",vol:.18,slide:120}); }
    else if(type==="electric"){ for(let i=0;i<5;i++) tone({f:1400+((i%2)*500),t:i*.045,dur:.04,type:"square",vol:.15}); }
    else if(type==="rock"){ tone({f:90,dur:.22,type:"sawtooth",vol:.3,slide:-40}); noiseHit({dur:.2,vol:.25,freq:400}); }
    else { tone({f:500,dur:.12,type:"square",vol:.18,slide:200}); }
  },
  throwBall(){ tone({f:340,dur:.3,type:"sine",vol:.25,slide:420}); },
  wobble(){ tone({f:260,dur:.1,type:"square",vol:.18,slide:-60}); },
  catchOk(){ [523,659,784,1046].forEach((f,i)=>tone({f,t:i*.11,dur:.18,type:"square",vol:.2})); },
  catchFail(){ tone({f:230,dur:.3,type:"sawtooth",vol:.26,slide:-130}); },
  levelup(){ [659,784,988,1319].forEach((f,i)=>tone({f,t:i*.09,dur:.14,type:"square",vol:.2})); },
  evolve(){ [523,622,740,880,1047,1245].forEach((f,i)=>tone({f,t:i*.12,dur:.2,type:"triangle",vol:.24})); },
  encounter(){ tone({f:990,dur:.35,type:"square",vol:.18,slide:-660}); noiseHit({dur:.3,vol:.15,freq:2000}); },
  faint(){ tone({f:420,dur:.45,type:"triangle",vol:.28,slide:-330}); },
  run(){ [500,400,320].forEach((f,i)=>tone({f,t:i*.07,dur:.08,type:"square",vol:.16})); },
  victory(){ [523,523,523,659,784,1046].forEach((f,i)=>tone({f,t:i*.13,dur:i===5?.5:.12,type:"square",vol:.22})); }
};
function auUnlock(){
  if(!auEnsure()) return;
  if(auCtx.state==="suspended") auCtx.resume();
  if(auTrack&&!auTimer&&!auMuted) playMusic(auTrack);
}
window.addEventListener("pointerdown",auUnlock);
window.addEventListener("keydown",auUnlock);
$("btn-sound").addEventListener("click",()=>{
  auMuted=!auMuted;
  $("btn-sound").textContent=auMuted?"🔇":"🔊";
  if(auMuted){ if(auTimer){clearInterval(auTimer); auTimer=null;} }
  else { auUnlock(); playMusic(auTrack); }
});

/* ================= BATTLE FX ================= */
const FXCOLORS={fire:["#FFC24D","#FF7A3D","#FF4D2E"],water:["#9AD7FF","#4DA3FF","#2E7CE6"],grass:["#C6F09A","#5BC763","#2F8F3B"],electric:["#FFF7B0","#FFE24D","#FFC400"],rock:["#E4D8BE","#B7A98E","#8D8271"],normal:["#FFFFFF","#FFE9C9","#CFCFCF"],heal:["#C8F5D0","#7CE08B","#3DBD5B"],gold:["#FFF3C4","#FFD54F","#F2A93B"]};
const FXEMOJI={fire:"🔥",water:"💧",grass:"🍃",electric:"⚡",rock:"🪨",normal:"💥"};
function arenaPos(el){
  const a=$("arena").getBoundingClientRect(), r=el.getBoundingClientRect();
  return {x:r.left-a.left+r.width/2, y:r.top-a.top+r.height/2};
}
function fxParticles(x,y,type,n){
  const cols=FXCOLORS[type]||FXCOLORS.normal;
  for(let i=0;i<(n||14);i++){
    const p=document.createElement("span"); p.className="pt";
    const ang=Math.random()*6.283, d=26+Math.random()*58, s=4+Math.random()*7;
    p.style.cssText=`left:${x}px;top:${y}px;width:${s}px;height:${s}px;background:${cols[i%cols.length]};box-shadow:0 0 6px ${cols[i%cols.length]};--dx:${(Math.cos(ang)*d).toFixed(1)}px;--dy:${(Math.sin(ang)*d).toFixed(1)}px;`;
    $("fx").appendChild(p);
    setTimeout(()=>p.remove(),650);
  }
}
function fxBurst(x,y,type){
  const cols=FXCOLORS[type]||FXCOLORS.normal;
  const b=document.createElement("span"); b.className="burst";
  b.style.cssText=`left:${x}px;top:${y}px;background:radial-gradient(circle,${cols[0]} 0%,${cols[1]}88 45%,transparent 70%);`;
  const r=document.createElement("span"); r.className="ring";
  r.style.cssText=`left:${x}px;top:${y}px;border-color:${cols[1]};`;
  $("fx").append(b,r);
  setTimeout(()=>{b.remove(); r.remove();},560);
}
function fxShake(){
  const a=$("arena");
  a.classList.remove("shakeA"); void a.offsetWidth; a.classList.add("shakeA");
  setTimeout(()=>a.classList.remove("shakeA"),450);
}
function fxHitFlash(side){
  const el=$(side+"-sprite");
  el.classList.add("hitflash");
  setTimeout(()=>el.classList.remove("hitflash"),240);
}
async function fxProjectile(fromSide,toSide,type,emoji){
  const from=arenaPos($(fromSide+"-sprite")), to=arenaPos($(toSide+"-sprite"));
  const p=document.createElement("span"); p.className="proj";
  p.textContent=emoji||FXEMOJI[type]||"💥";
  $("fx").appendChild(p);
  const mx=(from.x+to.x)/2, my=Math.min(from.y,to.y)-52;
  const anim=p.animate([
    {transform:`translate(${from.x}px,${from.y}px) scale(.55) rotate(0deg)`,opacity:.85},
    {transform:`translate(${mx}px,${my}px) scale(1.3) rotate(180deg)`,opacity:1,offset:.55},
    {transform:`translate(${to.x}px,${to.y}px) scale(1) rotate(330deg)`,opacity:1}
  ],{duration:430,easing:"ease-in"});
  const trail=setInterval(()=>{
    const a=$("arena").getBoundingClientRect(), r=p.getBoundingClientRect();
    if(r.width) fxParticles(r.left-a.left+r.width/2, r.top-a.top+r.height/2, type, 1);
  },50);
  try{ await anim.finished; }catch(e){}
  clearInterval(trail);
  p.remove();
}
