import * as THREE from './vendor/three.module.min.js';

// MINO 3D — first real-time 3D milestone. All geometry is original and created at runtime.
const canvas = document.querySelector('#scene');
const viewport = document.querySelector('#viewport');
const status = document.querySelector('#status');
const emoji = document.querySelector('#emoji');
const recordButton = document.querySelector('#record');
const recordLabel = document.querySelector('#record-label');

const scene = new THREE.Scene();
scene.background = new THREE.Color('#937764');
scene.fog = new THREE.Fog('#987a69', 9, 24);

const camera = new THREE.PerspectiveCamera(35, 1, .1, 70);
camera.position.set(0, 2.30, 7.6);
camera.lookAt(0, 1.78, 0);

let renderer;
try {
  renderer = new THREE.WebGLRenderer({canvas, antialias:true, powerPreference:'high-performance'});
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.35;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
} catch (error) {
  document.querySelector('#fallback').style.display = 'block';
  throw error;
}

scene.add(new THREE.HemisphereLight('#fff4dd', '#5a6572', 2.2));
const sunlight = new THREE.DirectionalLight('#fff1d8', 3.6);
sunlight.position.set(-3.5, 7, 5);
sunlight.castShadow = true;
sunlight.shadow.mapSize.set(1024,1024);
sunlight.shadow.camera.left = -5;
sunlight.shadow.camera.right = 5;
sunlight.shadow.camera.top = 7;
sunlight.shadow.camera.bottom = -5;
sunlight.shadow.camera.near = .1;
sunlight.shadow.camera.far = 20;
sunlight.shadow.bias = -.0007;
scene.add(sunlight);
const rim = new THREE.DirectionalLight('#90b9d4', 1.3);
rim.position.set(3, 5, -2);
scene.add(rim);

// Seeded variations keep the street identical on every load.
let seed = 7351;
function random() { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; }

function makeStreet() {
  const wall = new THREE.Mesh(new THREE.PlaneGeometry(30, 15),new THREE.MeshStandardMaterial({color:'#a16e52',roughness:1}));
  wall.position.set(0,4,-2.9);
  wall.receiveShadow = true;
  scene.add(wall);

  const wallBrickGeometry = new THREE.BoxGeometry(.68,.245,.17);
  const wallBrickMaterial = new THREE.MeshStandardMaterial({color:'#ffffff',roughness:1});
  const wallBricks = new THREE.InstancedMesh(wallBrickGeometry,wallBrickMaterial,24*24);
  const d = new THREE.Object3D();
  const shades = ['#965b44','#b47357','#935945','#aa684c','#a36b56','#82523e','#b27759'];
  let n=0;
  for(let row=0;row<24;row++)for(let col=0;col<24;col++) {
    d.position.set((col-11.5)*.73+(row%2)*.36,(row+.5)*.27,-2.8+random()*.035);
    d.rotation.set(0,0,(random()-.5)*.012);
    d.scale.set(.98+random()*.07,.94+random()*.08,1);
    d.updateMatrix();wallBricks.setMatrixAt(n,d.matrix);
    wallBricks.setColorAt(n,new THREE.Color(shades[Math.floor(random()*shades.length)]));n++;
  }
  wallBricks.castShadow=false;wallBricks.receiveShadow=true;scene.add(wallBricks);

  const ground = new THREE.Mesh(new THREE.PlaneGeometry(45,45),new THREE.MeshStandardMaterial({color:'#76695d',roughness:1}));
  ground.rotation.x=-Math.PI/2;ground.position.y=-.12;ground.receiveShadow=true;scene.add(ground);
  const tileGeo = new THREE.BoxGeometry(.83,.085,.75);
  const tileMat = new THREE.MeshStandardMaterial({color:'#ffffff',roughness:1});
  const tiles = new THREE.InstancedMesh(tileGeo,tileMat,14*15);
  const stones=['#968b79','#867d71','#aea08a','#7c786f','#9f8b72','#8c837a'];n=0;
  for(let row=0;row<15;row++)for(let col=0;col<14;col++) {
    d.position.set((col-6.5)*.9+(row%2)*.43, -.045+(random()-.5)*.012, 4.8-row*.82);
    d.rotation.set(0,(random()-.5)*.04,0);
    d.scale.set(.95+random()*.07,1,.94+random()*.07);
    d.updateMatrix();tiles.setMatrixAt(n,d.matrix);
    tiles.setColorAt(n,new THREE.Color(stones[Math.floor(random()*stones.length)]));n++;
  }
  tiles.receiveShadow=true;scene.add(tiles);

  const metal=new THREE.MeshStandardMaterial({color:'#404649',metalness:.62,roughness:.52});
  const pipe=new THREE.Mesh(new THREE.CylinderGeometry(.09,.09,6.3,14),metal);
  pipe.position.set(-2.6,3.05,-2.50);scene.add(pipe);
  for(const y of [1.1,3.1,5.2]){
    const ring=new THREE.Mesh(new THREE.TorusGeometry(.1,.027,8,20),metal);
    ring.rotation.x=Math.PI/2;ring.position.set(-2.6,y,-2.5);scene.add(ring);
  }
}
makeStreet();

function furTexture() {
  const c=document.createElement('canvas');c.width=c.height=256;
  const x=c.getContext('2d');x.fillStyle='#efefef';x.fillRect(0,0,256,256);
  let state=5107;
  function rnd(){state=(state*1664525+1013904223)>>>0;return state/4294967296;}
  for(let i=0;i<32000;i++) {
    const a=Math.floor(210+rnd()*45);
    x.strokeStyle=`rgba(${a},${a},${a},${.06+rnd()*.18})`;
    x.lineWidth=.4+rnd()*.5;
    const px=rnd()*256,py=rnd()*256;
    x.beginPath();x.moveTo(px,py);x.lineTo(px+(rnd()-.5)*2,py+2+rnd()*7);x.stroke();
  }
  const t=new THREE.CanvasTexture(c);t.colorSpace=THREE.SRGBColorSpace;
  t.wrapS=t.wrapT=THREE.RepeatWrapping;
  t.anisotropy=Math.min(renderer.capabilities.getMaxAnisotropy(),4);
  return t;
}
const furMap=furTexture();
const material=(color,roughness=.92)=>new THREE.MeshStandardMaterial({color,roughness});
const coat=new THREE.MeshStandardMaterial({color:'#a7aaa9',map:furMap,roughness:.99});
const faceCoat=new THREE.MeshStandardMaterial({color:'#b9bcbb',map:furMap,roughness:.97});
const darkFur=material('#666d72');
const pale=material('#ddd9cf');
const muzzleMat=material('#e7e5db');
const blush=material('#bb8586');
const black=material('#272e30',.45);
const eyeWhite=material('#f8f7e9',.25);
const irisMat=material('#66bb43',.36);
const shine=new THREE.MeshBasicMaterial({color:'#ffffff'});
const mouthMat=material('#482632',.5);
const tongueMat=material('#e47f96',.5);
const sphere=new THREE.SphereGeometry(1,36,24);

function ellipsoid(parent,mat,pos,scale,cast=true) {
  const m=new THREE.Mesh(sphere,mat);
  m.position.set(...pos);m.scale.set(...scale);
  m.castShadow=cast;m.receiveShadow=cast;parent.add(m);return m;
}
function curve(parent,points,r,mat) {
  const path=new THREE.CatmullRomCurve3(points.map(p=>new THREE.Vector3(...p)));
  const m=new THREE.Mesh(new THREE.TubeGeometry(path,24,r,7,false),mat);
  parent.add(m);return m;
}
function addEar(parent,side) {
  const outline=new THREE.Shape();
  outline.moveTo(-.32,-.08);outline.quadraticCurveTo(-.24,.27,-.05,.72);
  outline.quadraticCurveTo(.02,.82,.11,.67);outline.quadraticCurveTo(.31,.30,.33,-.04);
  outline.quadraticCurveTo(0,-.15,-.32,-.08);
  const outer=new THREE.Mesh(new THREE.ExtrudeGeometry(outline,{depth:.12,bevelEnabled:true,bevelThickness:.09,bevelSize:.035,bevelSegments:2,curveSegments:10}),faceCoat);
  outer.position.set(side*.64,.68,-.12);outer.rotation.z=-side*.14;outer.castShadow=true;parent.add(outer);
  const inset=new THREE.Shape();inset.moveTo(-.19,.02);inset.lineTo(-.035,.58);inset.quadraticCurveTo(.01,.65,.055,.57);inset.lineTo(.19,.02);inset.closePath();
  const inner=new THREE.Mesh(new THREE.ShapeGeometry(inset,10),blush);
  inner.position.set(side*.64,.68,.075);inner.rotation.z=-side*.14;parent.add(inner);
}
function buildMino() {
  const root=new THREE.Group();scene.add(root);
  const torso=new THREE.Group();root.add(torso);
  const body=ellipsoid(torso,coat,[0,1.36,0],[.73,1.02,.62]);
  ellipsoid(torso,pale,[0,1.32,.56],[.53,.82,.15],false);
  for(const s of [-1,1]) {
    const haunch=ellipsoid(root,coat,[s*.46,.70,-.06],[.34,.59,.41]);
    ellipsoid(root,coat,[s*.39,.22,.42],[.33,.20,.47]);
    for(let i=-1;i<=1;i++)ellipsoid(root,pale,[s*.39+i*.16,.15,.80],[.072,.085,.17],false);
    for(let j=0;j<3;j++){
      const mark=ellipsoid(root,darkFur,[s*(.68-j*.045),.60+j*.27,.15],[.044,.09,.28],false);
      mark.rotation.z=s*.33;
    }
  }

  const arms=[];
  for(const s of [-1,1]) {
    const pivot=new THREE.Group();pivot.position.set(s*.66,1.99,-.04);root.add(pivot);arms.push(pivot);
    const arm=ellipsoid(pivot,coat,[s*.17,-.46,.12],[.25,.60,.27]);arm.rotation.z=-s*.15;
    ellipsoid(pivot,coat,[s*.24,-.92,.26],[.27,.25,.31]);
    for(const y of [-.27,-.48,-.70]){
      const band=ellipsoid(pivot,darkFur,[s*.2,y,.38],[.22,.065,.055],false);band.rotation.z=s*.12;
    }
  }

  const neck=ellipsoid(root,coat,[0,2.14,.02],[.51,.36,.47]);
  const head=new THREE.Group();head.position.set(0,2.48,.18);root.add(head);
  ellipsoid(head,faceCoat,[0,.12,0],[.96,.78,.79]);
  addEar(head,-1);addEar(head,1);
  for(const s of [-1,1]) {
    ellipsoid(head,pale,[s*.61,-.18,.44],[.34,.29,.28]);
    const outerEye=new THREE.Group();outerEye.position.set(s*.35,.23,.675);head.add(outerEye);
    ellipsoid(outerEye,eyeWhite,[0,0,0],[.245,.305,.15],false);
    ellipsoid(outerEye,irisMat,[-s*.018,-.015,.135],[.164,.210,.064],false);
    ellipsoid(outerEye,black,[-s*.016,-.014,.188],[.082,.131,.034],false);
    ellipsoid(outerEye,shine,[-s*.082,.078,.211],[.055,.065,.018],false);
    if(s===-1)head.userData.leftEye=outerEye;else head.userData.rightEye=outerEye;
    curve(head,[[s*.21,.59,.75],[s*.35,.65,.74],[s*.57,.58,.65]],.036,darkFur);
    ellipsoid(head,muzzleMat,[s*.18,-.245,.733],[.31,.23,.22],false);
    for(let i=0;i<3;i++)curve(head,[[s*.41,-.24+i*.035,.76],[s*.68,-.23+(i-1)*.09,.78],[s*1.09,-.16+(i-1)*.16,.68]],.006,pale);
    for(let j=0;j<2;j++){
      const stripe=ellipsoid(head,darkFur,[s*(.72+j*.09),.10-j*.23,.32],[.11,.05,.28],false);
      stripe.rotation.z=s*.35;
    }
  }
  for(const x of [-.22,0,.22]) {
    const stripe=ellipsoid(head,darkFur,[x,.69-Math.abs(x)*.30,.34],[.055,.15,.10],false);
    stripe.rotation.z=-x*.5;
  }
  const nose=new THREE.Mesh(new THREE.ConeGeometry(.12,.14,3),blush);
  nose.rotation.z=Math.PI;nose.position.set(0,-.13,.97);head.add(nose);
  curve(head,[[0,-.19,.94],[0,-.29,.93]],.015,black);
  curve(head,[[-.21,-.29,.89],[-.11,-.35,.94],[0,-.29,.93],[.11,-.35,.94],[.21,-.29,.89]],.014,black);
  const mouth=ellipsoid(head,mouthMat,[0,-.35,.92],[.135,.018,.036],false);
  const tongue=ellipsoid(head,tongueMat,[0,-.41,.962],[.073,.015,.018],false);

  const tailBase=new THREE.Group();tailBase.position.set(-.58,1.0,-.33);root.add(tailBase);
  curve(tailBase,[[0,0,0],[-.30,-.10,-.03],[-.65,.05,-.08]],.20,coat);
  const tailTip=new THREE.Group();tailTip.position.set(-.65,.05,-.08);tailBase.add(tailTip);
  curve(tailTip,[[0,0,0],[-.28,.30,0],[-.18,.67,.02],[.13,.75,.02]],.17,coat);
  ellipsoid(tailTip,darkFur,[.13,.75,.02],[.19,.18,.18]);

  const hits=[];
  const hitMat=new THREE.MeshBasicMaterial({transparent:true,opacity:0,depthWrite:false,colorWrite:false});
  function hit(action,pos,scale,parent=root) {const h=ellipsoid(parent,hitMat,pos,scale,false);h.userData.action=action;hits.push(h);}
  hit('head',[0,2.75,.23],[.94,.82,.83]);
  hit('belly',[0,1.31,.39],[.67,.85,.48]);
  hit('paws',[0,.21,.60],[.84,.30,.50]);
  hit('tail',[-1.21,1.38,-.36],[.39,.61,.37]);

  // This is actual editable 3D anatomy: torso, head, arms, legs, tail and facial parts.
  return {root,torso,body,head,arms,tailBase,tailTip,mouth,tongue,hits};
}
const cat=buildMino();

const glass=new THREE.Group();cat.root.add(glass);
const glassWall=new THREE.Mesh(new THREE.CylinderGeometry(.18,.14,.40,24,1,true),new THREE.MeshPhysicalMaterial({color:'#c2e5f2',transparent:true,opacity:.44,roughness:.12,metalness:0,depthWrite:false,side:THREE.DoubleSide}));
glass.add(glassWall);
const milk=new THREE.Mesh(new THREE.CylinderGeometry(.15,.13,.25,24),new THREE.MeshStandardMaterial({color:'#fff8e9',roughness:.36}));
milk.position.y=-.065;glass.add(milk);glass.visible=false;

const raycaster=new THREE.Raycaster();
const pointer=new THREE.Vector2();
let yaw=0;
let reaction=null;
let currentVoiceAnalyser=null;
let voiceBuffer=null;
let talking=false;
let emojiTimer;
function say(text){status.textContent=text;}
function pop(text){emoji.textContent=text;emoji.classList.remove('show');void emoji.offsetWidth;emoji.classList.add('show');clearTimeout(emojiTimer);emojiTimer=setTimeout(()=>emoji.classList.remove('show'),900);}

let audioContext;
function audio() {
  const AC=window.AudioContext||window.webkitAudioContext;
  if(!AC)return null;
  if(!audioContext)audioContext=new AC();
  if(audioContext.state==='suspended')audioContext.resume().catch(()=>{});
  return audioContext;
}
function tone(kind) {
  const c=audio();if(!c)return;
  const settings={head:[490,690,.18],belly:[600,390,.30],tickle:[600,390,.30],paws:[300,640,.23],tail:[220,130,.24],milk:[540,390,.30],scratch:[220,90,.23]}[kind]||[400,500,.2];
  const o=c.createOscillator(),g=c.createGain(),t=c.currentTime;
  o.type=kind==='scratch'?'sawtooth':'sine';o.frequency.setValueAtTime(settings[0],t);o.frequency.exponentialRampToValueAtTime(settings[1],t+settings[2]);
  o.connect(g).connect(c.destination);g.gain.setValueAtTime(.0001,t);g.gain.exponentialRampToValueAtTime(.045,t+.02);g.gain.exponentialRampToValueAtTime(.0001,t+settings[2]);o.start(t);o.stop(t+settings[2]+.01);
}
function act(type) {
  if(talking)return;
  const line={head:['Oh, une caresse ! ♥','♥'],belly:['Hihihi ! Ça chatouille !','😹'],tickle:['Hihihi ! Ça chatouille !','😹'],paws:['Hop ! Attrape-moi !','✨'],tail:['Hé ! Pas ma queue !','⁉️'],milk:['Mmmh… du lait !','🥛'],scratch:['Attention aux griffes !','🐾']}[type];
  if(!line)return;
  reaction={type,start:performance.now(),duration:({head:850,belly:1200,tickle:1200,paws:1100,tail:900,milk:2100,scratch:950})[type]};
  say(line[0]);pop(line[1]);tone(type);
}
document.querySelectorAll('[data-action]').forEach(button=>button.addEventListener('click',()=>act(button.dataset.action)));

let drag=null;
canvas.addEventListener('pointerdown',event=>{drag={x:event.clientX,y:event.clientY,lastX:event.clientX,moved:false};canvas.setPointerCapture(event.pointerId);});
canvas.addEventListener('pointermove',event=>{
  if(!drag)return;
  if(Math.hypot(event.clientX-drag.x,event.clientY-drag.y)>8)drag.moved=true;
  if(drag.moved){yaw=Math.max(-1.13,Math.min(1.13,yaw+(event.clientX-drag.lastX)*.008));}
  drag.lastX=event.clientX;
});
canvas.addEventListener('pointerup',event=>{
  if(!drag)return;
  if(!drag.moved){
    const rect=canvas.getBoundingClientRect();
    pointer.set(((event.clientX-rect.left)/rect.width)*2-1,-((event.clientY-rect.top)/rect.height)*2+1);
    raycaster.setFromCamera(pointer,camera);
    cat.root.updateMatrixWorld(true);
    const hits=raycaster.intersectObjects(cat.hits,false);
    if(hits.length)act(hits[0].object.userData.action);
  }
  drag=null;
});
canvas.addEventListener('pointercancel',()=>drag=null);

let recorder,micStream,recording=false,recordTimeout,parts=[];
function releaseMic(){if(micStream){micStream.getTracks().forEach(track=>track.stop());micStream=null;}}
function resetMic(){recording=false;recordButton.classList.remove('recording');recordButton.disabled=false;recordLabel.textContent='Parler à Mino';clearTimeout(recordTimeout);}
async function startMic(){
  if(!navigator.mediaDevices?.getUserMedia||typeof MediaRecorder==='undefined'){say('Ce navigateur ne peut pas enregistrer la voix.');return;}
  recordButton.disabled=true;say('Autorise le microphone pour parler à Mino…');
  try{
    audio();
    micStream=await navigator.mediaDevices.getUserMedia({audio:{echoCancellation:true,noiseSuppression:true},video:false});
    parts=[];
    const mime=['audio/webm;codecs=opus','audio/mp4','audio/webm'].find(v=>MediaRecorder.isTypeSupported(v));
    recorder=mime?new MediaRecorder(micStream,{mimeType:mime}):new MediaRecorder(micStream);
    recorder.ondataavailable=event=>{if(event.data?.size)parts.push(event.data);};
    recorder.onerror=()=>{releaseMic();resetMic();say('L’enregistrement a échoué. Réessaie !');};
    recorder.onstop=async()=>{
      releaseMic();
      if(!parts.length){resetMic();say('Je n’ai rien entendu !');return;}
      recordButton.disabled=true;recordLabel.textContent='Mino répète…';
      await repeat(new Blob(parts,{type:recorder.mimeType||'audio/webm'}));
      resetMic();
    };
    recorder.start(100);recording=true;recordButton.disabled=false;recordButton.classList.add('recording');recordLabel.textContent='Terminer et écouter';say('🎙️ Je t’écoute. Parle, puis réappuie !');recordTimeout=setTimeout(stopMic,8500);
  }catch(error){releaseMic();resetMic();say(error?.name==='NotAllowedError'?'Micro refusé : autorise-le dans ton navigateur.':'Impossible de démarrer le micro.');}
}
function stopMic(){if(!recording)return;recording=false;clearTimeout(recordTimeout);recordButton.disabled=true;recordButton.classList.remove('recording');recordLabel.textContent='Un instant…';say('Mino prépare sa réponse…');if(recorder?.state!=='inactive')recorder.stop();else{releaseMic();resetMic();}}
async function repeat(blob){
  talking=true;say('🐱 Mino répète ta voix !');
  try{
    const c=audio();if(!c)throw Error('no audio context');
    const decoded=await c.decodeAudioData(await blob.arrayBuffer());
    const source=c.createBufferSource();voiceBuffer=source;source.buffer=decoded;source.playbackRate.value=1.33;
    const analyser=c.createAnalyser();analyser.fftSize=256;currentVoiceAnalyser=analyser;
    source.connect(analyser);analyser.connect(c.destination);
    await c.resume();
    await new Promise(resolve=>{source.onended=resolve;source.start();});
  }catch(error){
    try{
      const url=URL.createObjectURL(blob),element=new Audio(url);
      element.playbackRate=1.33;element.preservesPitch=false;element.mozPreservesPitch=false;element.webkitPreservesPitch=false;
      await element.play();
      await new Promise(resolve=>{element.onended=resolve;element.onerror=resolve;});
      URL.revokeObjectURL(url);
    }catch(e){say('Lecture impossible sur cet appareil. Essaie Chrome ou Edge.');}
  }finally{voiceBuffer=null;currentVoiceAnalyser=null;talking=false;if(status.textContent.includes('répète'))say('Encore ? Je suis tout ouïe ! 🎙️');}
}
recordButton.addEventListener('click',()=>{if(recording)stopMic();else if(!recordButton.disabled&&!talking)startMic();});
window.addEventListener('pagehide',()=>{releaseMic();if(voiceBuffer)try{voiceBuffer.stop();}catch(e){}});

let voiceData=new Uint8Array(256);
let previous=performance.now();
function render(time){
  requestAnimationFrame(render);
  const dt=Math.min((time-previous)/1000,.05);previous=time;
  const t=time*.001;
  cat.root.rotation.y+=(yaw-cat.root.rotation.y)*Math.min(1,dt*6);
  cat.root.position.y=0;cat.root.rotation.z=0;
  cat.torso.scale.set(1,1+Math.sin(t*2.3)*.012,1);
  cat.head.rotation.set(Math.sin(t*1.2)*.02,Math.sin(t*.83)*.045,Math.sin(t*1.5)*.025);
  cat.arms[0].rotation.z=Math.sin(t*1.7)*.032;
  cat.arms[1].rotation.z=-Math.sin(t*1.7)*.032;
  cat.tailBase.rotation.z=Math.sin(t*2)*.12;
  cat.tailTip.rotation.y=Math.sin(t*2.3)*.21;
  const blink=((time+700)%5800)<160;
  const eyeScale=blink?.07:1;
  cat.head.userData.leftEye.scale.y=eyeScale;
  cat.head.userData.rightEye.scale.y=eyeScale;
  glass.visible=false;
  let mouthOpen=0;

  if(reaction){
    const p=Math.min(1,(time-reaction.start)/reaction.duration);
    const env=Math.sin(Math.PI*p);
    const kind=reaction.type;
    if(kind==='head'){cat.head.rotation.z+=Math.sin(p*Math.PI*2)*.16*env;cat.head.userData.leftEye.scale.y*=.75;cat.head.userData.rightEye.scale.y*=.75;}
    if(kind==='belly'||kind==='tickle'){cat.root.rotation.z=Math.sin(p*28)*.085*env;cat.arms[0].rotation.z=-.72*env;cat.arms[1].rotation.z=.72*env;cat.head.rotation.z+=Math.sin(p*18)*.12*env;mouthOpen=.27*env;}
    if(kind==='paws'){cat.root.position.y=Math.max(0,Math.sin(Math.PI*p))*.7;cat.arms[0].rotation.z=-.42*env;cat.arms[1].rotation.z=.42*env;}
    if(kind==='tail'){cat.tailBase.rotation.z+=Math.sin(p*38)*.65*env;cat.tailTip.rotation.y+=Math.sin(p*33)*.47*env;}
    if(kind==='scratch'){cat.arms[1].rotation.z=-1.25*env;cat.arms[1].rotation.x=-.65*env+Math.sin(p*55)*.35*env;cat.head.rotation.z-=.08*env;}
    if(kind==='milk'){
      glass.visible=true;
      const move=Math.min(1,p*3);
      glass.position.set(.95-move*.70,.42+move*1.72,1.12);
      glass.rotation.z=-move*.48;
      cat.head.rotation.x+=Math.sin(p*28)*.08*env;
    }
    if(p>=1)reaction=null;
  }
  cat.arms[0].rotation.x=0;
  if(!reaction||reaction.type!=='scratch')cat.arms[1].rotation.x=0;

  if(talking){
    if(currentVoiceAnalyser){
      currentVoiceAnalyser.getByteTimeDomainData(voiceData);
      let power=0;for(let i=0;i<voiceData.length;i++){const v=(voiceData[i]-128)/128;power+=v*v;}
      const rms=Math.sqrt(power/voiceData.length);
      mouthOpen=Math.max(.1,Math.min(1,(rms-.013)*7));
    }else mouthOpen=.25+.35*Math.abs(Math.sin(t*13));
    cat.head.rotation.z+=Math.sin(t*10)*.035;
  }
  cat.mouth.scale.y=.018+mouthOpen*.18;
  cat.mouth.scale.x=.135+mouthOpen*.035;
  cat.tongue.scale.y=.015+mouthOpen*.018;
  renderer.render(scene,camera);
}

function resize(){
  const width=viewport.clientWidth,height=viewport.clientHeight;
  if(width<1||height<1)return;
  renderer.setSize(width,height,false);
  camera.aspect=width/height;
  camera.updateProjectionMatrix();
}
new ResizeObserver(resize).observe(viewport);
window.addEventListener('resize',resize);
resize();requestAnimationFrame(render);
