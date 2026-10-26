extends SceneTree

func _init() -> void:
	call_deferred(&"_ejecutar")

func _ejecutar() -> void:
	var escena: PackedScene = load("res://assets/characters/knight3d/dadico.glb")
	var nodo: Node = escena.instantiate()
	_imprimir(nodo, 0)
	quit(0)

func _imprimir(n: Node, nivel: int) -> void:
	var t: String = ""
	if n is Node3D:
		t = " pos=%s rot=%s scale=%s" % [n.position, n.rotation_degrees, n.scale]
	print("  ".repeat(nivel) + "- " + n.name + " (" + n.get_class() + ")" + t)
	for c in n.get_children():
		_imprimir(c, nivel + 1)
