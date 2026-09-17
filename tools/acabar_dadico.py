"""Run with Blender 5.2 -b dadico_trabajo.blend --python tools/acabar_dadico.py."""
import bpy, os, shutil
from pathlib import Path

root = Path(__file__).resolve().parents[1]
source = root / 'assets/art_source/blender/dados'
out = root / 'assets/characters/knight3d'
backup = source / 'originales'
backup.mkdir(exist_ok=True)
(backup / '.gdignore').touch()
for src in [source/'dadico_trabajo.blend', out/'dadico.glb']:
    dst = backup / src.name
    if not dst.exists(): shutil.copy2(src, dst)
obj = next(o for o in bpy.context.scene.objects if o.type == 'MESH')
bpy.context.view_layer.objects.active = obj
obj.select_set(True)
# Only unwrap: positions, origin, scale and face assignments remain unchanged.
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.smart_project(angle_limit=1.15, island_margin=0.025)
bpy.ops.object.mode_set(mode='OBJECT')
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.samples = 16
scene.render.bake.margin = 12
scene.render.bake.use_clear = True
materials = list(obj.data.materials)

def linear_hex(value):
    rgb = [int(value[i:i+2], 16) / 255 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v <= .04045 else ((v + .055) / 1.055) ** 2.4 for v in rgb) + (1,)

for index, mat in enumerate(materials):
    mat.name = ['Basalto_tallado','Brasas_ranuras','Basalto_cuerpo'][index]
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    output = nt.nodes.new('ShaderNodeOutputMaterial')
    bsdf = nt.nodes.new('ShaderNodeBsdfPrincipled')
    bsdf.inputs['Roughness'].default_value = .9
    bsdf.inputs['Specular IOR Level'].default_value = .22
    nt.links.new(bsdf.outputs['BSDF'], output.inputs['Surface'])
    tex = nt.nodes.new('ShaderNodeTexNoise')
    coords = nt.nodes.new('ShaderNodeTexCoord')
    metric = nt.nodes.new('ShaderNodeVectorMath'); metric.operation = 'MULTIPLY'
    metric.inputs[1].default_value = (1, 1, 2.527)
    nt.links.new(coords.outputs['Object'], metric.inputs[0])
    nt.links.new(metric.outputs['Vector'], tex.inputs['Vector'])
    tex.inputs['Scale'].default_value = 12 if index != 1 else 32
    tex.inputs['Detail'].default_value = 4
    tex.inputs['Roughness'].default_value = .72
    ramp = nt.nodes.new('ShaderNodeValToRGB')
    # Slate blue greys sampled from walls_cave_tall.png, in linear space for PBR.
    colors = tuple(map(linear_hex, ('293038', '7a7e91') if index != 1 else ('c52632', 'ff6036')))
    ramp.color_ramp.elements[0].position = .18
    ramp.color_ramp.elements[0].color = colors[0]
    ramp.color_ramp.elements[1].position = .82
    ramp.color_ramp.elements[1].color = colors[1]
    if index != 1:
        ramp.color_ramp.elements.new(.5).color = linear_hex('505768')
    nt.links.new(tex.outputs['Fac'],ramp.inputs[0])
    nt.links.new(ramp.outputs[0],bsdf.inputs['Base Color'])
    fine = nt.nodes.new('ShaderNodeTexNoise')
    nt.links.new(metric.outputs['Vector'], fine.inputs['Vector'])
    fine.inputs['Scale'].default_value = 155
    fine.inputs['Detail'].default_value = 2
    bump = nt.nodes.new('ShaderNodeBump')
    bump.inputs['Strength'].default_value = .32 if index != 1 else .12
    bump.inputs['Distance'].default_value = .002
    nt.links.new(fine.outputs['Fac'],bump.inputs['Height'])
    nt.links.new(bump.outputs['Normal'],bsdf.inputs['Normal'])
    if index == 1:
        nt.links.new(ramp.outputs[0],bsdf.inputs['Emission Color'])
        bsdf.inputs['Emission Strength'].default_value = .95

images = {}
for kind in ['albedo','normal']:
    img = bpy.data.images.new('dadico_'+kind, width=1024,height=1024,alpha=False)
    img.colorspace_settings.name = 'Non-Color' if kind == 'normal' else 'sRGB'
    for mat in materials:
        nt=mat.node_tree
        target=nt.nodes.new('ShaderNodeTexImage'); target.image=img
        nt.nodes.active=target
    if kind == 'albedo':
        scene.render.bake.use_pass_direct=False
        scene.render.bake.use_pass_indirect=False
        scene.render.bake.use_pass_color=True
        bpy.ops.object.bake(type='DIFFUSE')
    else:
        bpy.ops.object.bake(type='NORMAL')
    img.filepath_raw=str(out/('dadico_'+kind+'.png'))
    img.file_format='PNG'; img.save(); images[kind]=img

# Export only portable PBR nodes, with baked detail shared by all surfaces.
for index, mat in enumerate(materials):
    nt=mat.node_tree
    for node in list(nt.nodes):
        if node.type not in {'BSDF_PRINCIPLED','OUTPUT_MATERIAL'}: nt.nodes.remove(node)
    bsdf=next(n for n in nt.nodes if n.type=='BSDF_PRINCIPLED')
    color=nt.nodes.new('ShaderNodeTexImage'); color.image=images['albedo']
    nt.links.new(color.outputs['Color'],bsdf.inputs['Base Color'])
    normal=nt.nodes.new('ShaderNodeTexImage'); normal.image=images['normal']
    mapping=nt.nodes.new('ShaderNodeNormalMap')
    nt.links.new(normal.outputs['Color'],mapping.inputs['Color'])
    nt.links.new(mapping.outputs['Normal'],bsdf.inputs['Normal'])
    if index==1: nt.links.new(color.outputs['Color'],bsdf.inputs['Emission Color'])
for img in images.values(): img.pack()
bpy.ops.wm.save_as_mainfile(filepath=str(source/'dadico_trabajo.blend'))
bpy.ops.export_scene.gltf(filepath=str(out/'dadico.glb'),export_format='GLB',use_selection=True,export_yup=True,export_animations=False)
print('DADICO_EXPORTED',len(obj.data.vertices),len(obj.data.polygons),list(obj.scale))
