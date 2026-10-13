"""Prepare the Blender-generated MINO for Three.js. No dependencies.
Run: py blender/prepare_game_asset.py
Input: blender/mino_anim.glb; output: 3d/assets/mino_anim.glb
Repairs controller pivots without changing mesh or animation binary data.
"""
from pathlib import Path
import json
import struct

ROOT=Path(__file__).resolve().parent.parent
SOURCE=ROOT/'blender'/'mino_anim.glb'
OUTPUT=ROOT/'3d'/'assets'/'mino_anim.glb'

def prepare(src=SOURCE, dest=OUTPUT):
    raw=src.read_bytes()
    magic,version,length=struct.unpack_from('<4sII',raw)
    if magic!=b'glTF' or version!=2 or length!=len(raw):
        raise ValueError('Fichier glTF binaire invalide')
    chunks=[]
    off=12
    while off<len(raw):
        length,tag=struct.unpack_from('<I4s',raw,off)
        off+=8
        chunks.append((tag,raw[off:off+length]))
        off+=length
    if off!=len(raw):raise ValueError('Fichier GLB incomplet')
    meta=json.loads(next(blob for typ,blob in chunks if typ==b'JSON'))
    nodes=meta['nodes']
    lookup={n['name']:i for i,n in enumerate(nodes)}
    pivots={'CTRL_MINO':(0,0,0),'CTRL_TETE':(0,2.52,.09),
            'CTRL_BRAS_G':(-.43,1.91,-.02),'CTRL_BRAS_D':(.43,1.91,-.02),
            'CTRL_QUEUE':(-.48,.82,-.19),
            'CTRL_OEIL_G':(-.327,2.65,.656),
            'CTRL_OEIL_D':(.327,2.65,.656)}
    if any(name not in lookup for name in (*pivots,'Bouche_Parole')):
        raise ValueError('Ce modele ne contient pas les controleurs MINO attendus')
    dest.parent.mkdir(parents=True,exist_ok=True)
    if 'Bouche_Parole_Geometry' in lookup:
        dest.write_bytes(raw)
        print('Modele deja corrige :',dest)
        return
    delta=lambda x,y:[round(x[j]-y[j],6) for j in range(3)]
    mouth=(0,2.108,.79)
    def fix_controller(name,parent):
        pivot=pivots[name]
        obj=nodes[lookup[name]]
        obj['translation']=delta(pivot,parent)
        for ix in obj.get('children',[]):
            child=nodes[ix]
            cname=child['name']
            if cname in pivots:
                fix_controller(cname,pivot)
            elif cname=='Bouche_Parole':
                child['translation']=delta(mouth,pivot)
                idx=len(nodes)
                nodes.append({'name':'Bouche_Parole_Geometry',
                    'mesh':child.pop('mesh'),'translation':delta((0,0,0),mouth)})
                child['children']=[idx]
            else:
                child['translation']=delta((0,0,0),pivot)
    fix_controller('CTRL_MINO',(0,0,0))
    blob=json.dumps(meta,ensure_ascii=False,separators=(',',':')).encode('utf8')
    blob+=b' '*((-len(blob))%4)
    chunks=[(b'JSON',blob)]+[(typ,part) for typ,part in chunks if typ!=b'JSON']
    packed=bytearray(b'glTF'+struct.pack('<II',2,12+sum(8+len(p) for _,p in chunks)))
    for typ,part in chunks:
        packed.extend(struct.pack('<I4s',len(part),typ))
        packed.extend(part)
    dest.write_bytes(packed)
    print('MINO Blender prepare :',dest)
    print('Taille :',len(packed),'octets')

if __name__=='__main__':
    if not SOURCE.is_file():
        raise SystemExit('Modele absent : '+str(SOURCE)+'\\nExecute blender/creer_mino.bat d abord.')
    prepare()
