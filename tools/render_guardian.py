import bpy
from mathutils import Vector
from math import sqrt
from bpy_extras.object_utils import world_to_camera_view
from pathlib import Path

root = Path(bpy.data.filepath).parent if bpy.data.filepath else Path.cwd()
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(root / 'assets/characters/knight3d/polloModelo.glb'))
meshes = [obj for obj in bpy.context.scene.objects if obj.type == 'MESH']
points = [obj.matrix_world @ Vector(corner) for obj in meshes for corner in obj.bound_box]
minimum = Vector(tuple(min(p[i] for p in points) for i in range(3)))
maximum = Vector(tuple(max(p[i] for p in points) for i in range(3)))
center = (minimum + maximum) / 2
size = max(maximum - minimum)
# Mantener el apoyo en el mismo píxel al girar, aunque la cola desplace el encuadre.
vertices = [obj.matrix_world @ vertex.co for obj in meshes for vertex in obj.data.vertices]
ground = [point for point in vertices if point.z < minimum.z + (maximum.z - minimum.z) * 0.02]
for axis in (0, 1):
    center[axis] = (min(point[axis] for point in ground) + max(point[axis] for point in ground)) / 2
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 32
frame_size = 256
scene.render.resolution_x = frame_size
scene.render.resolution_y = frame_size
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.world.color = (0.35, 0.35, 0.35)
scene.view_settings.view_transform = 'Standard'
bpy.ops.object.light_add(type='AREA', location=center + Vector((size, -size, size * 2)))
light = bpy.context.object
light.data.energy = 400 * size * size
light.data.shape = 'DISK'
light.data.size = size * 3
light.rotation_euler = (center - light.location).to_track_quat('-Z', 'Y').to_euler()
bpy.ops.object.camera_add()
camera = bpy.context.object
camera.data.type = 'ORTHO'
camera.data.ortho_scale = size * 1.55
scene.camera = camera
output = root / 'assets/characters/npcs/guardian/sprites'
output.mkdir(parents=True, exist_ok=True)
frames = []
ground_shifts = []
# Orden calibrado en juego: abajo derecha, abajo izquierda, arriba izquierda, arriba derecha.
for index, direction in enumerate([(-1, 1), (-1, -1), (1, -1), (1, 1)]):
    camera.location = center + Vector((direction[0] * size * 2, direction[1] * size * 2, size * sqrt(2)))
    camera.rotation_euler = (center - camera.location).to_track_quat('-Z', 'Y').to_euler()
    scene.render.filepath = str(output / ('vista_%d.png' % index))
    bpy.ops.render.render(write_still=True)
    frames.append(bpy.data.images.load(scene.render.filepath, check_existing=False))
    # Apoyo común en (128, 192), compatible con offset_sprite_mapa=(0, -64).
    ground_view = world_to_camera_view(scene, camera, Vector((center.x, center.y, minimum.z)))
    ground_shifts.append((round(frame_size / 2 - ground_view.x * frame_size), round(frame_size / 4 - ground_view.y * frame_size)))
atlas_size = frame_size * 2
atlas = bpy.data.images.new('guardian_4_direcciones', width=atlas_size, height=atlas_size, alpha=True)
pixels = [0.0] * (atlas_size * atlas_size * 4)
for index, frame in enumerate(frames):
    src = list(frame.pixels)
    x0, y0 = (index % 2) * frame_size, (1 - index // 2) * frame_size
    dx, dy = ground_shifts[index]
    for y in range(frame_size):
        source_y = y - dy
        left, right = max(0, dx), min(frame_size, frame_size + dx)
        if not 0 <= source_y < frame_size or left >= right:
            continue
        start = ((y + y0) * atlas_size + x0 + left) * 4
        source_start = (source_y * frame_size + left - dx) * 4
        count = (right - left) * 4
        pixels[start:start + count] = src[source_start:source_start + count]
atlas.pixels = pixels
atlas.filepath_raw = str(output / 'guardian_4_direcciones.png')
atlas.file_format = 'PNG'
atlas.save()
for index in range(4):
    (output / ('vista_%d.png' % index)).unlink()
