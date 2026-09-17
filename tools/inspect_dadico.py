import bpy, json
from collections import Counter
for o in bpy.context.scene.objects:
    print('OBJECT', o.name, o.type, 'matrix', [list(r) for r in o.matrix_world])
    if o.type == 'MESH':
        print('MESH',len(o.data.vertices),len(o.data.polygons),'bounds',list(map(list,o.bound_box)),'slots',[(s.name) for s in o.material_slots], 'faces',dict(Counter(p.material_index for p in o.data.polygons)), 'UV', [u.name for u in o.data.uv_layers])
        print('MODIFIERS',[(m.name,m.type) for m in o.modifiers])
for m in bpy.data.materials:
    print('MATERIAL',m.name, list(m.diffuse_color))
    if m.use_nodes:
        for n in m.node_tree.nodes:
            print('NODE', n.name,n.type,[(i.name,str(i.default_value)) for i in n.inputs if not i.is_linked and hasattr(i,'default_value')])
