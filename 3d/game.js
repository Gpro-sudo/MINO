import * as THREE from './vendor/three.module.min.js';
import {createMino} from './mino-model.js';

// MINO 3D — an original animated, procedural feline in real-time 3D.
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
camera.position.set(0, 2.18, 8.2);
camera.lookAt(0, 1.71, 0);

let renderer;
try {
  renderer = new THREE.WebGLRenderer({canvas, antialias:true, powerPreference:'high-performance'});
  renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 1.20;
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
  const shades = ['#8c6253','#a8755e','#866052','#a16c58','#9c715f','#79594e','#a67962'];
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

  // A quiet little easter egg on the alley wall: MINO's own graffiti.
  const signCanvas=document.createElement('canvas');signCanvas.width=512;signCanvas.height=250;
  const signContext=signCanvas.getContext('2d');
  signContext.font='italic 900 155px system-ui';signContext.textAlign='center';
  signContext.lineJoin='round';signContext.lineWidth=19;signContext.strokeStyle='#245542';
  signContext.strokeText('MINO',255,170);
  signContext.fillStyle='#4f9b64';signContext.fillText('MINO',255,170);
  const signTexture=new THREE.CanvasTexture(signCanvas);signTexture.colorSpace=THREE.SRGBColorSpace;
  const sign=new THREE.Mesh(new THREE.PlaneGeometry(1.85,.9),new THREE.MeshBasicMaterial({map:signTexture,transparent:true,opacity:.68,depthWrite:false}));
  sign.position.set(-1.87,2.80,-2.67);sign.rotation.z=-.13;scene.add(sign);

  // The old alley has a small metal bin on the right, behind the character.
  const bin=new THREE.Group();bin.position.set(2.23,.66,-2.23);scene.add(bin);
  const binMat=new THREE.MeshStandardMaterial({color:'#535a58',metalness:.47,roughness:.83});
  const binBody=new THREE.Mesh(new THREE.CylinderGeometry(.37,.31,1.27,24),binMat);
  binBody.castShadow=true;binBody.receiveShadow=true;bin.add(binBody);
  const rim=new THREE.Mesh(new THREE.TorusGeometry(.382,.046,10,32),binMat);
  rim.rotation.x=Math.PI/2;rim.position.y=.62;bin.add(rim);
  const lid=new THREE.Mesh(new THREE.CylinderGeometry(.40,.40,.075,24),metal);
  lid.position.y=.66;lid.castShadow=true;bin.add(lid);
  for(let k=0;k<14;k++){
    const a=k*Math.PI*2/14;
    const rib=new THREE.Mesh(new THREE.CylinderGeometry(.012,.012,1.12,6),metal);
    rib.position.set(Math.sin(a)*.342,-.02,Math.cos(a)*.342);
    bin.add(rib);
  }
}
makeStreet();

const cat=createMino(THREE,renderer,scene);

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
  cat.leftEar.rotation.z=Math.sin(t*1.5)*.023;
  cat.rightEar.rotation.z=-Math.sin(t*1.5+.4)*.023;
  cat.head.userData.leftEye.rotation.y=Math.sin(t*.7)*.018;
  cat.head.userData.rightEye.rotation.y=Math.sin(t*.7)*.018;
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
    if(kind==='head'){
      cat.head.rotation.z+=Math.sin(p*Math.PI*2)*.16*env;
      cat.head.userData.leftEye.scale.y*=.75;cat.head.userData.rightEye.scale.y*=.75;
      cat.leftEar.rotation.z-=.15*env;cat.rightEar.rotation.z+=.15*env;
    }
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
