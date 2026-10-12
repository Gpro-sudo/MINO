// MINO — original stylised cat model. Built from smooth, animated 3D surfaces,
// rather than a stack of detached spheres. Reference: early talking-pet games.
export function createMino(THREE, renderer, scene) {
  const root = new THREE.Group();
  scene.add(root);

  // Fine, deterministic fibres break up the plastic look without downloading textures.
  const textureCanvas = document.createElement('canvas');
  textureCanvas.width = textureCanvas.height = 512;
  const ctx = textureCanvas.getContext('2d');
  ctx.fillStyle = '#f5f1ef';
  ctx.fillRect(0, 0, 512, 512);
  let seed = 8741;
  const random = () => { seed = (1664525 * seed + 1013904223) >>> 0; return seed / 4294967296; };
  for (let i = 0; i < 85000; i++) {
    const x = random() * 512, y = random() * 512;
    const value = 145 + (random() * 105 | 0);
    ctx.strokeStyle = `rgba(${value},${value - 2},${value - 3},${.055 + random() * .13})`;
    ctx.lineWidth = .3 + random() * .5;
    ctx.beginPath();
    ctx.moveTo(x, y);
    ctx.quadraticCurveTo(x - .7, y + 2, x + random() * 2 - 1, y + 3 + random() * 4);
    ctx.stroke();
  }
  const furMap = new THREE.CanvasTexture(textureCanvas);
  furMap.colorSpace = THREE.SRGBColorSpace;
  furMap.wrapS = furMap.wrapT = THREE.RepeatWrapping;
  furMap.anisotropy = Math.min(renderer.capabilities.getMaxAnisotropy(), 8);
  const fur = (color, sheen = '#aea6a4') => new THREE.MeshPhysicalMaterial({
    color, map: furMap, roughness: .98, metalness: 0,
    sheen: .72, sheenColor: sheen, sheenRoughness: .95
  });
  const coat = fur('#837d7e');
  const faceCoat = fur('#8c8586');
  const shadowCoat = fur('#746f71');
  const softCoat = fur('#a49b99');
  const muzzleCoat = fur('#bcb0aa');
  const bellyCoat = fur('#b6aba5');
  const earPink = new THREE.MeshStandardMaterial({color:'#b9787d',roughness: .96,side: THREE.DoubleSide});
  const earShadow = new THREE.MeshStandardMaterial({color:'#91676c',roughness: .94});
  const nosePink = new THREE.MeshPhysicalMaterial({color:'#d78e94',roughness:.4,clearcoat:.22,clearcoatRoughness:.5});
  const nostril = new THREE.MeshStandardMaterial({color:'#965e68',roughness:.89});
  const ink = new THREE.MeshStandardMaterial({color:'#372f35',roughness:.9});
  const crease = new THREE.MeshStandardMaterial({color:'#5c5355',roughness:1});
  const eyeOutline = new THREE.MeshStandardMaterial({color:'#4c464b',roughness:1});
  const eyeWhite = new THREE.MeshPhysicalMaterial({color:'#fff9f2',roughness:.24,clearcoat:.42});
  const irisMaterial = new THREE.MeshPhysicalMaterial({color:'#398a46',roughness:.28,clearcoat:.55});
  const irisOuter = new THREE.MeshStandardMaterial({color:'#1b5130',roughness:.6});
  const irisInner = new THREE.MeshStandardMaterial({color:'#71c64c',roughness:.35});
  const pupilMaterial = new THREE.MeshPhysicalMaterial({color:'#121b17',roughness:.13,clearcoat:1});
  const catchlight = new THREE.MeshBasicMaterial({color:'#ffffff'});
  const lipMaterial = new THREE.MeshStandardMaterial({color:'#463239',roughness:.92});
  const tongueMaterial = new THREE.MeshStandardMaterial({color:'#d6818e',roughness:.7});
  const whiskerMaterial = new THREE.MeshBasicMaterial({color:'#e9deda',transparent:true,opacity:.84});

  const unitSphere = new THREE.SphereGeometry(1, 48, 32);
  function blob(parent, mat, position, scale, castShadow = true) {
    const mesh = new THREE.Mesh(unitSphere, mat);
    mesh.position.set(...position);mesh.scale.set(...scale);
    mesh.castShadow = castShadow;mesh.receiveShadow = castShadow;
    parent.add(mesh);
    return mesh;
  }
  function line(parent, vertices, radius, mat, segments = 24) {
    const curve = new THREE.CatmullRomCurve3(vertices.map(p => new THREE.Vector3(...p)));
    const mesh = new THREE.Mesh(new THREE.TubeGeometry(curve, segments, radius, 6, false), mat);
    mesh.castShadow = false;parent.add(mesh);return mesh;
  }
  // A curved limb / tail with variable radius has no visible ball-joint seams.
  function skinTube(parent, vertices, radii, mat, sides = 20, steps = 48) {
    const curve = new THREE.CatmullRomCurve3(vertices.map(p => new THREE.Vector3(...p)));
    const frames = curve.computeFrenetFrames(steps, false);
    const positions = [], uvs = [], indices = [];
    for (let i = 0; i <= steps; i++) {
      const t = i / steps;
      const point = curve.getPoint(t);
      const section = Math.min(radii.length - 2, Math.floor(t * (radii.length - 1)));
      const fraction = THREE.MathUtils.smoothstep(t * (radii.length - 1) - section, 0, 1);
      const radius = THREE.MathUtils.lerp(radii[section], radii[section + 1], fraction);
      for (let j = 0; j <= sides; j++) {
        const angle = j / sides * Math.PI * 2;
        const offset = frames.normals[i].clone().multiplyScalar(Math.cos(angle) * radius)
          .addScaledVector(frames.binormals[i], Math.sin(angle) * radius);
        positions.push(point.x + offset.x, point.y + offset.y, point.z + offset.z);
        uvs.push(j / sides, t);
        if (i < steps && j < sides) {
          const a = i * (sides + 1) + j, b = a + sides + 1;
          // Match the Frenet frame handedness so the outside is front-facing.
          indices.push(a, a + 1, b, b, a + 1, b + 1);
        }
      }
    }
    const geo = new THREE.BufferGeometry();
    geo.setAttribute('position', new THREE.Float32BufferAttribute(positions, 3));
    geo.setAttribute('uv', new THREE.Float32BufferAttribute(uvs, 2));
    geo.setIndex(indices);geo.computeVertexNormals();
    const mesh = new THREE.Mesh(geo, mat);
    mesh.castShadow = true;mesh.receiveShadow = true;parent.add(mesh);
    return mesh;
  }

  const torso = new THREE.Group();root.add(torso);
  const bodyOutline = new THREE.SplineCurve([
    new THREE.Vector2(.0,.48),new THREE.Vector2(.34,.50),
    new THREE.Vector2(.54,.70),new THREE.Vector2(.62,1.00),
    new THREE.Vector2(.59,1.36),new THREE.Vector2(.49,1.70),
    new THREE.Vector2(.39,1.96),new THREE.Vector2(.26,2.13),
    new THREE.Vector2(.0,2.20)
  ]);
  const body = new THREE.Mesh(new THREE.LatheGeometry(bodyOutline.getPoints(100), 56), coat);
  body.scale.z = .86;body.castShadow=true;body.receiveShadow=true;torso.add(body);
  // Small, soft chest marking — part of the coat, not a giant white plastic plate.
  blob(torso, bellyCoat, [0,1.35,.49], [.34,.61,.048], false);
  blob(torso, muzzleCoat, [0,1.91,.35], [.23,.26,.06], false);

  for (const s of [-1, 1]) {
    const leg = new THREE.Group();leg.position.set(s * .34,.87,-.03);root.add(leg);
    skinTube(leg, [[0,.13,-.03],[s*.025,-.14,.00],[s*.01,-.39,.13],[-s*.01,-.61,.23]],
      [.235,.26,.22,.095],coat);
    const foot = blob(leg,coat,[-s*.008,-.64,.37],[.255,.16,.33]);
    foot.rotation.x = -.10;
    // Short engraved toe creases; no detached marshmallow toes or big claws.
    for (const x of [-.085,.085]) {
      line(leg, [[x,-.70,.667],[x,-.642,.687],[x,-.599,.667]], .007, crease, 12);
    }
    blob(leg, softCoat, [0,-.733,.61],[.07,.014,.04],false);
  }

  const arms=[];
  for (const s of [-1,1]) {
    const arm=new THREE.Group();arm.position.set(s*.49,1.91,-.09);root.add(arm);
    skinTube(arm, [[0,.15,0],[s*.16,-.17,-.035],[s*.29,-.50,.045],[s*.26,-.85,.14]],
      [.15,.255,.235,.13],faceCoat);
    const paw=blob(arm,faceCoat,[s*.26,-.83,.145],[.225,.17,.23]);
    paw.rotation.z=-s*.22;
    for(const x of [-.065,.065]){
      line(arm,[[s*.26+x,-.937,.315],[s*.26+x,-.885,.355],[s*.26+x,-.843,.356]],.006,crease,10);
    }
    arms.push(arm);
  }

  // Broad feline head with integrated jowls, set lower than the old cone ears.
  const head=new THREE.Group();head.position.set(0,2.39,.09);root.add(head);
  blob(head,faceCoat,[0,.06,0],[.82,.69,.65]);
  for(const s of [-1,1]){
    blob(head,faceCoat,[s*.55,-.20,.18],[.36,.37,.43]);
  }
  blob(head,faceCoat,[0,-.39,.20],[.58,.30,.43]);

  // Ears lean sideways as in classic 2010-style silhouettes.
  function ear(side){
    const earGroup=new THREE.Group();earGroup.position.set(side*.63,.42,-.15);
    earGroup.scale.x=side;head.add(earGroup);
    const outline=new THREE.Shape();
    outline.moveTo(-.21,-.07);
    outline.bezierCurveTo(-.26,.13,-.27,.41,-.19,.49);
    outline.bezierCurveTo(-.09,.58,.41,.78,.48,.65);
    outline.bezierCurveTo(.55,.55,.38,.03,.20,-.11);
    outline.quadraticCurveTo(-.04,-.17,-.21,-.07);
    const shell=new THREE.Mesh(new THREE.ExtrudeGeometry(outline,{
      depth:.15,bevelEnabled:true,bevelThickness:.055,bevelSize:.047,
      bevelSegments:3,steps:1,curveSegments:18
    }),shadowCoat);
    shell.castShadow=true;earGroup.add(shell);
    const inset=new THREE.Shape();
    inset.moveTo(-.13,.04);inset.quadraticCurveTo(-.17,.36,-.09,.42);
    inset.quadraticCurveTo(.07,.54,.36,.60);
    inset.quadraticCurveTo(.37,.38,.18,.03);
    inset.quadraticCurveTo(.05,-.015,-.13,.04);
    const pink=new THREE.Mesh(new THREE.ShapeGeometry(inset,18),earPink);
    pink.position.z=.213;earGroup.add(pink);
    const innerShadow=blob(earGroup,earShadow,[.08,.21,.205],[.12,.19,.003],false);
    innerShadow.visible=false; // reserved for ear reactions
    return earGroup;
  }
  const leftEar=ear(-1),rightEar=ear(1);

  for(const s of [-1,1]){
    const eye=new THREE.Group();eye.position.set(s*.328,.135,.578);eye.rotation.z=-s*.06;head.add(eye);
    blob(eye,eyeOutline,[0,0,-.005],[.235,.276,.09],false);
    blob(eye,eyeWhite,[0,0,.012],[.216,.251,.094],false);
    blob(eye,irisOuter,[-s*.012,-.018,.108],[.153,.172,.028],false);
    blob(eye,irisMaterial,[-s*.012,-.018,.134],[.137,.158,.024],false);
    blob(eye,irisInner,[-s*.012,-.018,.151],[.095,.120,.014],false);
    blob(eye,pupilMaterial,[-s*.006,-.022,.165],[.067,.106,.02],false);
    blob(eye,catchlight,[-.055,.075,.180],[.048,.054,.009],false);
    blob(eye,catchlight,[.060,-.088,.176],[.020,.022,.008],false);
    if(s===-1)head.userData.leftEye=eye;else head.userData.rightEye=eye;
    line(head,[[s*.11,.405,.625],[s*.33,.455,.619],[s*.55,.383,.525]],.025,shadowCoat,18);

    // The two small cream pads sit within broad grey cheeks.
    blob(head,muzzleCoat,[s*.197,-.315,.60],[.28,.17,.158],false);
    for (const [x,y] of [[.31,-.29],[.40,-.34],[.29,-.38]]){
      blob(head,crease,[s*x,y,.722-Math.abs(x-.29)*.4],[.008,.008,.005],false);
    }
    for (let j=-1;j<=1;j++){
      const y=-.303+j*.055;
      line(head,[[s*.45,y,.675],[s*.73,y+j*.044,.65],[s*1.11,y+j*.093,.56]],.0037,whiskerMaterial,18);
    }
  }

  const noseShape=new THREE.Shape();
  noseShape.moveTo(-.16,.035);
  noseShape.bezierCurveTo(-.15,.102,-.055,.112,0,.091);
  noseShape.bezierCurveTo(.055,.112,.15,.102,.16,.035);
  noseShape.bezierCurveTo(.14,-.017,.045,-.112,0,-.122);
  noseShape.bezierCurveTo(-.045,-.112,-.14,-.017,-.16,.035);
  const nose=new THREE.Mesh(new THREE.ExtrudeGeometry(noseShape,{
    depth:.047,bevelEnabled:true,bevelThickness:.026,bevelSize:.015,
    bevelSegments:4,curveSegments:20
  }),nosePink);
  nose.position.set(0,-.195,.759);nose.castShadow=true;head.add(nose);
  blob(head,nostril,[-.087,-.17,.827],[.025,.015,.006],false);
  blob(head,nostril,[.087,-.17,.827],[.025,.015,.006],false);
  line(head,[[0,-.323,.790],[0,-.397,.782]],.011,lipMaterial,12);
  line(head,[[-.217,-.404,.705],[-.12,-.451,.746],[0,-.416,.78],[.12,-.451,.746],[.217,-.404,.705]],.013,lipMaterial);
  const mouth=blob(head,lipMaterial,[0,-.445,.747],[.12,.012,.024],false);
  const tongue=blob(head,tongueMaterial,[0,-.491,.778],[.063,.014,.012],false);

  // A few very soft forehead stripes make MINO a tabby without "stick-on" blocks.
  for(const x of [-.20,0,.20]){
    const s=Math.sign(x);
    line(head,[[x*.67,.612,.22],[x*.77,.548,.34],[x*.95,.49,.44]],.011,shadowCoat,12);
  }

  const tailBase=new THREE.Group();tailBase.position.set(-.48,.90,-.29);root.add(tailBase);
  skinTube(tailBase,[[0,0,0],[-.26,-.09,-.06],[-.51,-.06,-.03],[-.66,.14,.005]],
    [.20,.195,.17,.15],coat,16,40);
  const tailTip=new THREE.Group();tailTip.position.set(-.66,.14,.005);tailBase.add(tailTip);
  skinTube(tailTip,[[0,0,0],[-.10,.23,.005],[-.02,.46,.012],[.17,.49,.03]],
    [.154,.14,.135,.015],coat,16,36);

  const hits=[];
  const hitMat=new THREE.MeshBasicMaterial({transparent:true,opacity:0,depthWrite:false,colorWrite:false});
  function hit(action,position,scale,parent=root){
    const mesh=blob(parent,hitMat,position,scale,false);mesh.userData.action=action;hits.push(mesh);
  }
  hit('head',[0,2.54,.18],[.99,.76,.77]);
  hit('belly',[0,1.28,.40],[.67,.77,.46]);
  hit('paws',[0,.24,.39],[.81,.25,.48]);
  hit('tail',[-1.12,1.12,-.34],[.36,.52,.39]);

  return {root,torso,body,head,arms,tailBase,tailTip,mouth,tongue,hits,leftEar,rightEar};
}
