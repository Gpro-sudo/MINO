"""MINO — generate an editable animated starter character in Blender.

Run: blender --background --factory-startup --python build_mino.py
Requires Blender 4.5+ only: no external packages or downloaded model.
This creates a blockout (.blend) and an animation-ready .glb.
The controls are parent pivots, NOT a production deformation armature.
"""
from pathlib import Path
from math import sin, cos, pi, exp, sqrt, radians
import bpy
from mathutils import Vector

HERE = Path(__file__).resolve().parent
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)

GREY = (.37,.33,.33,1)
FACE = (.48,.44,.44,1)
DARK = (.14,.12,.14,1)
CREAM = (.76,.72,.66,1)
PINK = (.73,.34,.39,1)
EAR = (.59,.28,.33,1)
WHITE = (.95,.94,.89,1)
GREEN = (.15,.51,.24,1)
GREEN_DARK = (.04,.22,.12,1)
BLACK = (.012,.023,.025,1)

def world_point(p):
    # Coordinates here are (horizontal, vertical, front).
    # Blender expects (horizontal, depth, vertical).
    return (p[0], -p[2], p[1])

def mat(name, color, rough=.85):
    m = bpy.data.materials.new(name)
    m.diffuse_color = color
    m.use_nodes = True
    shader = m.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = color
    shader.inputs['Roughness'].default_value = rough
    return m

coat=mat('MINO • Pelage gris', GREY)
face=mat('MINO • Pelage visage', FACE)
cream=mat('MINO • Mufle crème', CREAM)
dark=mat('MINO • Sourcils et sourire', DARK)
pink=mat('MINO • Nez rose', PINK,.55)
inner=mat('MINO • Oreille rose', EAR)
white=mat('MINO • Blanc des yeux', WHITE,.25)
iris=mat('MINO • Iris vert', GREEN,.28)
iris2=mat('MINO • Anneau iris', GREEN_DARK)
pupil=mat('MINO • Pupille', BLACK,.17)
highlight=mat('MINO • Reflet', (1,1,1,1),.12)

def vertex_mat(name, fallback):
    m=mat(name, fallback)
    bs=m.node_tree.nodes.get('Principled BSDF')
    a=m.node_tree.nodes.new('ShaderNodeAttribute')
    a.attribute_name='Pelage'
    m.node_tree.links.new(a.outputs['Color'],bs.inputs['Base Color'])
    return m

body_mat=vertex_mat('MINO • Dégradé du ventre', GREY)
head_mat=vertex_mat('MINO • Dégradé du museau', FACE)

def mesh(name, verts, faces, material, colors=None):
    geometry=bpy.data.meshes.new(name+'_mesh')
    geometry.from_pydata([world_point(p) for p in verts], [], faces)
    geometry.update()
    ob=bpy.data.objects.new(name,geometry)
    bpy.context.collection.objects.link(ob)
    ob.data.materials.append(material)
    for p in geometry.polygons: p.use_smooth=True
    if colors:
        ca=geometry.color_attributes.new(name='Pelage',type='FLOAT_COLOR',domain='CORNER')
        # vertex_colors uses one color per loop
        for polygon in geometry.polygons:
            for li in polygon.loop_indices:
                vi=geometry.loops[li].vertex_index
                ca.data[li].color=colors[vi]
    return ob

def ellipsoid(name, center, size, material, warp=None, rows=26, segments=36, colors=None):
    verts=[]; faces=[]
    for i in range(rows+1):
        phi=pi*i/rows
        for j in range(segments):
            theta=2*pi*j/segments
            x=sin(phi)*cos(theta)
            y=cos(phi)
            z=sin(phi)*sin(theta)
            if warp: x,y,z=warp(x,y,z)
            verts.append((center[0]+x*size[0],
                          center[1]+y*size[1],
                          center[2]+z*size[2]))
    for i in range(rows):
        for j in range(segments):
            a=i*segments+j; b=i*segments+(j+1)%segments
            c=(i+1)*segments+j; d=(i+1)*segments+(j+1)%segments
            faces.append((a,b,c))
            faces.append((b,d,c))
    col=[colors(*v) for v in verts] if colors else None
    return mesh(name,verts,faces,material,col)

def lerp(a,b,t):return a+(b-a)*t
def mix(a,b,k):return tuple(lerp(a[i],b[i],max(0,min(1,k))) for i in range(4))
def smooth(a,b,x):
    t=max(0,min(1,(x-a)/(b-a)))
    return t*t*(3-2*t)

def body_color(x,y,z):
    radius=max(.03,sqrt(x*x+z*z))
    front=smooth(.22,.41,z/radius)
    blend=.85*front*smooth(.57,.96,y)*(1-smooth(1.65,1.96,y))
    return mix(GREY,CREAM,blend)

sections=[(.46,.22,.28,0),(.57,.34,.35,-.005),(.77,.46,.39,-.005),
    (.98,.54,.42,0),(1.2,.57,.44,0),(1.44,.51,.43,-.005),
    (1.7,.42,.38,-.005),(1.91,.34,.32,-.01),
    (2.11,.25,.24,-.015),(2.16,.10,.10,-.01)]
vs=[];fs=[]
for h,rx,rz,zc in sections:
    for j in range(48):
        a=2*pi*j/48
        vs.append((rx*sin(a),h,zc+rz*cos(a)))
for i in range(len(sections)-1):
    for j in range(48):
        a=i*48+j;b=i*48+(j+1)%48;c=(i+1)*48+j;d=(i+1)*48+(j+1)%48
        fs.extend([(a,b,c),(b,d,c)])
body=mesh('Corps_Pelage',vs,fs,body_mat,[body_color(*v) for v in vs])

def catmull(points, steps=8):
    out=[]
    for n in range(len(points)-1):
        p0=Vector(points[max(0,n-1)])
        p1=Vector(points[n]); p2=Vector(points[n+1])
        p3=Vector(points[min(len(points)-1,n+2)])
        for j in range(steps):
            t=j/steps
            out.append(.5*((2*p1)+(-p0+p2)*t+
                 (2*p0-5*p1+4*p2-p3)*t*t+
                 (-p0+3*p1-3*p2+p3)*t*t*t))
    out.append(Vector(points[-1]))
    return out

def tube(name, points, r0, r1, material, sides=12):
    path=catmull(points,5)
    vs=[];fs=[]
    for i,p in enumerate(path):
        tangent=path[min(len(path)-1,i+1)]-path[max(0,i-1)]
        tangent.normalize()
        helper=Vector((0,0,1)) if abs(tangent.z)<.95 else Vector((1,0,0))
        binormal=tangent.cross(helper).normalized()
        normal=binormal.cross(tangent).normalized()
        t=i/max(1,len(path)-1)
        radius=lerp(r0,r1,t)
        for j in range(sides):
            ang=2*pi*j/sides
            v=p+radius*(normal*cos(ang)+binormal*sin(ang))
            vs.append(tuple(v))
        if i:
            for j in range(sides):
                a=(i-1)*sides+j;b=(i-1)*sides+(j+1)%sides
                c=i*sides+j;d=i*sides+(j+1)%sides
                fs.extend([(a,c,b),(b,c,d)])
    return mesh(name,vs,fs,material)

def line(name, points, radius, material):
    return tube(name,points,radius,radius,material,8)

for side,label in [(-1,'G'),(1,'D')]:
    tube('Jambe_'+label,[(side*.32,.87,-.03),
          (side*.34,.66,.02),(side*.35,.39,.13),(side*.36,.23,.29)],
          .205,.15,coat)
    ellipsoid('Pied_'+label,(side*.36,.17,.38),(.245,.17,.31),coat)
    for offset in (-.075,.075):
        line('Sillon_Orteil_'+label+str(offset),[
          (side*.36+offset,.13,.659),(side*.36+offset,.17,.681),
          (side*.36+offset,.21,.651)],.0035,dark)
    tube('Bras_'+label,[(side*.43,1.9,-.02),(side*.58,1.73,-.01),
          (side*.69,1.49,.07),(side*.68,1.24,.21),(side*.60,1.08,.27)],
          .19,.12,face)
    ellipsoid('Patte_'+label,(side*.60,1.08,.29),(.18,.147,.193),face)

def warp_head(x,y,z):
    cheek=exp(-((y+.20)/.34)**2)
    jaw=exp(-((y+.50)/.25)**2)
    x=x*(1+.21*cheek-.075*jaw)
    z=z*(1+.14*cheek)+.08*max(0,z)*cheek
    y=y-.07*jaw
    return x,y,z

def face_color(x,y,z):
    creamness=exp(-((y-2.29)/.27)**2)*smooth(.30,.58,z)
    return mix(FACE,CREAM,.72*creamness)

head=ellipsoid('Tete_Sculptee',(0,2.55,.09),(.81,.67,.63),
               head_mat,warp=warp_head,rows=44,segments=64,colors=face_color)

# Compact pointed ears in a soft silhouette; unlike the earlier rabbit ears.
for side,label in [(-1,'G'),(1,'D')]:
    ring=[(.49,2.91),(.67,3.12),(.94,3.40),(1.09,3.43),
          (1.14,3.32),(1.07,3.09),(.83,2.85)]
    vs=[(side*x,y,z) for z in (-.035,.10) for x,y in ring]
    fs=[]
    N=len(ring)
    for j in range(1,N-1):fs.extend([(0,j,j+1),(N,N+j+1,N+j)])
    for j in range(N):
        k=(j+1)%N
        fs.extend([(j,k,N+j),(k,N+k,N+j)])
    mesh('Oreille_'+label,vs,fs,face)
    pts=[(.68,3.03),(.80,3.19),(1.04,3.35),(1.04,3.16),(.85,2.98)]
    v=[(side*x,y,.114) for x,y in pts]
    mesh('Oreille_'+label+'_Rose',v,[(0,1,2),(0,2,3),(0,3,4)],inner)
    # Large green eyes
    for name,pos,rad,m in [
        ('Blanc',(side*.327,2.65,.656),(.223,.25,.115),white),
        ('Iris',(side*.307,2.642,.769),(.135,.165,.042),iris),
        ('Bord',(side*.307,2.642,.799),(.113,.140,.021),iris2),
        ('Pupille',(side*.307,2.628,.818),(.081,.122,.023),pupil),
        ('Reflet',(side*.348,2.723,.836),(.037,.040,.012),highlight)]:
        ellipsoid('Oeil_'+label+'_'+name,pos,rad,m,rows=20,segments=28)
    line('Sourcil_'+label,[(side*.13,2.96,.59),
         (side*.31,2.99,.60),(side*.51,2.94,.54)],.012,dark)
    for j in (-1,0,1):
        line('Moustache_'+label+'_'+str(j),[(side*.51,2.27+j*.055,.59),
         (side*.76,2.26+j*.08,.62),(side*1.04,2.30+j*.115,.58)],.003,cream)

ellipsoid('Nez_Rose',(0,2.318,.743),(.135,.09,.063),pink)
line('Bouche_Relief',[(0,2.234,.79),(0,2.16,.79)],.009,dark)
line('Bouche_Sourire',[(-.18,2.153,.69),(-.09,2.11,.74),
   (0,2.118,.78),(.09,2.11,.74),(.18,2.153,.69)],.009,dark)
ellipsoid('Bouche_Parole',(0,2.108,.79),(.095,.018,.012),dark)
tube('Queue_Enroulee',[(-.48,.82,-.19),(-.73,.70,-.27),
    (-.99,.74,-.32),(-1.14,.93,-.29),(-1.10,1.19,-.25),
    (-.95,1.24,-.21)],.18,.09,coat,18)

# The mesh objects remain individually editable. Controllers enable simple
# motion now; a later milestone should add an actual deformable bone skeleton.
model_meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
def ctrl(name, xyz, parent=None):
    ob=bpy.data.objects.new(name,None)
    bpy.context.collection.objects.link(ob)
    ob.empty_display_type='SPHERE'
    ob.empty_display_size=.12
    ob.location=world_point(xyz)
    if parent: parent_keep(ob,parent)
    return ob
def parent_keep(ob,parent):
    world=ob.matrix_world.copy()
    ob.parent=parent
    ob.matrix_world=world

root=ctrl('CTRL_MINO',(0,0,0))
headctrl=ctrl('CTRL_TETE',(0,2.52,.09),root)
left=ctrl('CTRL_BRAS_G',(-.43,1.91,-.02),root)
right=ctrl('CTRL_BRAS_D',(.43,1.91,-.02),root)
tail=ctrl('CTRL_QUEUE',(-.48,.82,-.19),root)
for ob in model_meshes:
    parent_keep(ob,root)
    name=ob.name
    if name.startswith(('Tete','Oreille','Oeil','Nez','Bouche','Sourcil','Moustache')):
        parent_keep(ob,headctrl)
    elif name.startswith(('Bras_G','Patte_G')):
        parent_keep(ob,left)
    elif name.startswith(('Bras_D','Patte_D')):
        parent_keep(ob,right)
    elif name.startswith('Queue'):
        parent_keep(ob,tail)

eyes=[]
for label,side in [('G',-1),('D',1)]:
    e=ctrl('CTRL_OEIL_'+label,(side*.327,2.65,.656),headctrl)
    for ob in model_meshes:
        if ob.name.startswith('Oeil_'+label):
            parent_keep(ob,e)
    eyes.append(e)

scene=bpy.context.scene
scene.frame_start=1
scene.frame_end=144
scene.render.fps=24

def keys(ob,property,frames):
    for frame,value in frames:
        setattr(ob,property,value)
        ob.keyframe_insert(data_path=property,frame=frame)

keys(root,'location',[(1,world_point((0,0,0))),(37,world_point((0,.016,0))),
     (74,world_point((0,0,0))),(112,world_point((0,.018,0))),
     (144,world_point((0,0,0)))])
keys(headctrl,'rotation_euler',[(1,(0,0,0)),(29,(0,0,radians(-4))),
     (54,(0,0,0)),(85,(0,0,radians(3))),(144,(0,0,0))])
keys(left,'rotation_euler',[(1,(0,0,0)),(40,(radians(-8),0,0)),
     (75,(0,0,0)),(144,(0,0,0))])
keys(right,'rotation_euler',[(1,(0,0,0)),(40,(radians(8),0,0)),
     (75,(0,0,0)),(144,(0,0,0))])
keys(tail,'rotation_euler',[(1,(0,0,0)),(26,(0,radians(8),0)),
     (55,(0,radians(-7),0)),(90,(0,radians(8),0)),
     (144,(0,0,0))])
for e in eyes:
    keys(e,'scale',[(1,(1,1,1)),(34,(1,1,1)),
       (37,(1,1,.09)),(41,(1,1,1)),(91,(1,1,1)),
       (94,(1,1,.09)),(98,(1,1,1)),(144,(1,1,1))])
mouth=bpy.data.objects.get('Bouche_Parole')
if mouth:
    keys(mouth,'scale',[(1,(1,1,1)),(59,(1,1,1)),
      (61,(1,1,2.5)),(70,(1,1,1.2)),
      (75,(1,1,2)),(84,(1,1,1)),(144,(1,1,1))])

# Preview camera and lighting belong to the editable Blender file.
def aim(ob, target):
    vector=Vector(target)-ob.location
    ob.rotation_euler=vector.to_track_quat('-Z','Y').to_euler()
bpy.ops.object.camera_add(location=(0,-6.4,2.2))
camera=bpy.context.object
camera.name='MINO_Camera'
camera.data.type='ORTHO'
camera.data.ortho_scale=4.25
aim(camera,(0,0,1.75))
scene.camera=camera
for name,place,watts,size in [
      ('MINO_Key',(-3,-4,6),450,5),
      ('MINO_Fill',(3,-3,3.8),245,4),
      ('MINO_Rim',(1,3,4),410,3)]:
    d=bpy.data.lights.new(name,'AREA')
    light=bpy.data.objects.new(name,d)
    scene.collection.objects.link(light)
    light.location=place;d.energy=watts;d.shape='DISK';d.size=size
    aim(light,(0,0,1.7))
world=bpy.data.worlds.new('MINO_Studio')
scene.world=world
world.use_nodes=True
background=world.node_tree.nodes.get('Background')
if background:
    background.inputs['Color'].default_value=(.14,.16,.18,1)
    background.inputs['Strength'].default_value=.7
scene.render.resolution_x=720
scene.render.resolution_y=960
scene.frame_set(1)

bpy.ops.object.select_all(action='DESELECT')
root.select_set(True)
bpy.context.view_layer.objects.active=root
blend=str(HERE/'mino_rig.blend')
bpy.ops.wm.save_as_mainfile(filepath=blend,check_existing=False)
glb=str(HERE/'mino_anim.glb')
bpy.ops.export_scene.gltf(filepath=glb,export_format='GLB',export_animations=True)
if not Path(blend).exists() or not Path(glb).exists():
    raise RuntimeError('Missing output: .blend or .glb')
print('MINO ready:',blend,glb)
