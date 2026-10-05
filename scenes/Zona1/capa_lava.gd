extends TileMapLayer

@export var escena_capa_lava: PackedScene


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_generar_particulas_lava()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _generar_particulas_lava() -> void:
	if escena_capa_lava == null:
		return
	var celdas_lava: Array[Vector2i] = get_used_cells()
	
	for celda in celdas_lava:
		var tile_data :=  get_cell_tile_data(celda)
		
		var emisor := escena_capa_lava.instantiate() as GPUParticles2D
		add_child(emisor)
	
		emisor.position = map_to_local(celda)
		
	
		
	
	
