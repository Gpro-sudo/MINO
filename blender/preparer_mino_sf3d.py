"""MINO — etape 1 : creer une base Blender modifiable depuis le GLB SF3D.

Usage Windows: Blender --background --factory-startup --python blender/preparer_mino_sf3d.py
Source : local3d/output/mino/0/mesh.glb
Sortie : blender/mino_sf3d_base.blend (ou suffixe incrementiel, sans ecrasement).
Aucune armature n'est fabriquee ici ; aucune modification du jeu ou du GLB original.
"""
from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Quaternion, Vector

ROOT = Path(__file__).resolve().parent.parent
SOURCE = ROOT / "local3d" / "output" / "mino" / "0" / "mesh.glb"
TARGET_FIRST = ROOT / "blender" / "mino_sf3d_base.blend"


def next_available_path(path: Path) -> Path:
    if not path.exists():
        return path
    for num in range(2, 100):
        candidate = path.with_name(f"{path.stem}_{num:02d}{path.suffix}")
        if not candidate.exists():
            return candidate
    raise RuntimeError("Trop de fichiers de travail existants. Rien n'a ete ecrase.")


def main() -> None:
    if not SOURCE.is_file():
        raise FileNotFoundError(
            f"Modele SF3D absent : {SOURCE}\n"
            "Execute d'abord local3d/generer_sf3d.cmd avec l'image de MINO."
        )

    target = next_available_path(TARGET_FIRST)
    print("[MINO] Lecture du modele SF3D :", SOURCE, flush=True)

    # Blender est lance avec --factory-startup, mais nous evitons tout objet demo.
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)

    bpy.ops.import_scene.gltf(filepath=str(SOURCE))
    imported = list(bpy.context.scene.objects)
    meshes = [obj for obj in imported if obj.type == "MESH"]
    if not meshes:
        raise RuntimeError("Le GLB ne contient aucun maillage Blender.")

    collection = bpy.data.collections.new("MINO_SF3D_BASE")
    bpy.context.scene.collection.children.link(collection)
    for obj in imported:
        for old in list(obj.users_collection):
            old.objects.unlink(obj)
        collection.objects.link(obj)

    mesh = max(meshes, key=lambda obj: len(obj.data.vertices))
    mesh.name = "MINO_SF3D_CORPS"
    mesh.data.name = "MINO_SF3D_MAILLAGE"
    for face in mesh.data.polygons:
        face.use_smooth = True

    # Garder les images originales importees dans le projet .blend.
    bpy.ops.file.pack_all()
    count_packed = sum(1 for img in bpy.data.images if img.packed_file is not None)

    # Tous les objets importes restent visibles ; aucun remodelage automatique.
    bpy.ops.object.select_all(action="DESELECT")
    mesh.select_set(True)
    bpy.context.view_layer.objects.active = mesh

    corners = [
        obj.matrix_world @ Vector(corner)
        for obj in meshes
        for corner in obj.bound_box
    ]
    minimum = [min(p[i] for p in corners) for i in range(3)]
    maximum = [max(p[i] for p in corners) for i in range(3)]
    centre = Vector([(minimum[i] + maximum[i]) / 2 for i in range(3)])
    height = max(maximum[i] - minimum[i] for i in range(3))
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type != "VIEW_3D":
                continue
            space = area.spaces.active
            space.shading.type = "MATERIAL"
            space.region_3d.view_perspective = "ORTHO"
            space.region_3d.view_rotation = Quaternion((1, 0, 0), math.radians(90))
            space.region_3d.view_location = centre
            space.region_3d.view_distance = max(2.1, 2.0 * height)
            space.overlay.show_floor = False

    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.context.scene.render.resolution_x = 1024
    bpy.context.scene.render.resolution_y = 1024

    bpy.ops.wm.save_as_mainfile(filepath=str(target))
    if not target.is_file():
        raise RuntimeError("Blender n'a pas cree le projet .blend.")

    print("[MINO] Preparation du modele terminee.", flush=True)
    print("[MINO] Maillages :", len(meshes), flush=True)
    print("[MINO] Sommets :", sum(len(obj.data.vertices) for obj in meshes), flush=True)
    print("[MINO] Triangles :", sum(len(obj.data.loop_triangles) for obj in meshes), flush=True)
    print("[MINO] Images integrees au .blend :", count_packed, flush=True)
    print("[MINO] Aucune armature ou animation creee a cette etape.", flush=True)
    print("[MINO] PROJET BLENDER :", target, flush=True)
    print("[MINO] Ouvre le .blend et verifie le visage et le profil en Material Preview.", flush=True)


if __name__ == "__main__":
    main()
