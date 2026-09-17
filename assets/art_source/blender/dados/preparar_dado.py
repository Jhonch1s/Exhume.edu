"""Importa el dado original en un documento Blender editable independiente."""
from pathlib import Path
import bpy

destino = Path(__file__).resolve().parent
proyecto = destino.parents[3]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(proyecto / "assets/characters/knight3d/dadico.glb"))
for objeto in bpy.context.scene.objects:
    if objeto.type == "MESH":
        print("DADO:", objeto.name, "dimensiones:", tuple(objeto.dimensions),
              "materiales:", [m.name if m else None for m in objeto.data.materials])
bpy.ops.wm.save_as_mainfile(filepath=str(destino / "dadico_trabajo.blend"))
