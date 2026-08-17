class_name ResaltadorOutline2D
extends Node2D

const CODIGO_SHADER := """
shader_type canvas_item;
render_mode unshaded;

uniform vec4 color_outline : source_color = vec4(1.0);
uniform float grosor : hint_range(1.0, 4.0, 1.0) = 1.0;
uniform vec2 uv_min = vec2(0.0);
uniform vec2 uv_max = vec2(1.0);
uniform vec2 tamano_region_px = vec2(1.0);
uniform vec2 centro_local = vec2(0.0);

void vertex() {
	VERTEX.x += VERTEX.x < centro_local.x ? -grosor : grosor;
	VERTEX.y += VERTEX.y < centro_local.y ? -grosor : grosor;
}

void fragment() {
	vec2 rango_uv = uv_max - uv_min;
	vec2 posicion_expandida = (UV - uv_min) / rango_uv;
	vec2 tamano_expandido = tamano_region_px + vec2(grosor * 2.0);
	vec2 posicion_fuente_px = posicion_expandida * tamano_expandido - vec2(grosor);
	float alpha_centro = 0.0;
	float alpha_vecino = 0.0;

	for (int y = -4; y <= 4; y++) {
		for (int x = -4; x <= 4; x++) {
			vec2 desplazamiento = vec2(float(x), float(y));
			if (length(desplazamiento) > grosor + 0.1) {
				continue;
			}
			vec2 muestra_px = posicion_fuente_px + desplazamiento;
			if (
				muestra_px.x < 0.0
				|| muestra_px.y < 0.0
				|| muestra_px.x >= tamano_region_px.x
				|| muestra_px.y >= tamano_region_px.y
			) {
				continue;
			}
			vec2 uv_muestra = uv_min + ((muestra_px + vec2(0.5)) / tamano_region_px) * rango_uv;
			float alpha_muestra = texture(TEXTURE, uv_muestra).a;
			alpha_vecino = max(alpha_vecino, alpha_muestra);
			if (x == 0 && y == 0) {
				alpha_centro = alpha_muestra;
			}
		}
	}

	float alpha_outline = alpha_vecino * (1.0 - alpha_centro);
	COLOR = vec4(color_outline.rgb, color_outline.a * alpha_outline);
}
"""

var color_outline: Color = Color.WHITE
var grosor: float = 1.0
var _fuente: Sprite2D
var _copia_outline: Sprite2D
var _material_outline: ShaderMaterial
var _activo: bool = false


func configurar(
	fuente: Sprite2D,
	color_inicial: Color = Color.WHITE,
	grosor_inicial: float = 1.0
) -> void:
	_fuente = fuente
	color_outline = color_inicial
	grosor = clampf(grosor_inicial, 1.0, 4.0)
	_asegurar_recursos()
	_sincronizar()


func establecer_activo(activo: bool) -> void:
	_activo = activo
	_asegurar_recursos()
	_sincronizar()
	set_process(_activo)


func esta_activo() -> bool:
	return _activo


func _process(_delta: float) -> void:
	_sincronizar()


func _asegurar_recursos() -> void:
	if is_instance_valid(_copia_outline):
		return
	_copia_outline = Sprite2D.new()
	_copia_outline.name = "OutlineProgramatico"
	var shader := Shader.new()
	shader.code = CODIGO_SHADER
	_material_outline = ShaderMaterial.new()
	_material_outline.shader = shader
	_copia_outline.material = _material_outline
	add_child(_copia_outline)


func _sincronizar() -> void:
	if not is_instance_valid(_copia_outline):
		return
	if not is_instance_valid(_fuente) or _fuente.texture == null:
		_copia_outline.visible = false
		return

	_copia_outline.visible = _activo and _fuente.visible
	if not _copia_outline.visible:
		return

	_copia_outline.texture = _fuente.texture
	_copia_outline.position = _fuente.position
	_copia_outline.rotation = _fuente.rotation
	_copia_outline.scale = _fuente.scale
	_copia_outline.skew = _fuente.skew
	_copia_outline.centered = _fuente.centered
	_copia_outline.offset = _fuente.offset
	_copia_outline.flip_h = _fuente.flip_h
	_copia_outline.flip_v = _fuente.flip_v
	_copia_outline.region_enabled = _fuente.region_enabled
	_copia_outline.region_rect = _fuente.region_rect
	_copia_outline.hframes = _fuente.hframes
	_copia_outline.vframes = _fuente.vframes
	_copia_outline.frame = _fuente.frame
	_copia_outline.texture_filter = _fuente.texture_filter
	_copia_outline.z_as_relative = _fuente.z_as_relative
	_copia_outline.z_index = _fuente.z_index + 1

	var rect_region := _obtener_rect_region()
	var tamano_textura := Vector2(_fuente.texture.get_size())
	var minimo_uv := rect_region.position / tamano_textura
	var maximo_uv := rect_region.end / tamano_textura
	_material_outline.set_shader_parameter(&"color_outline", color_outline)
	_material_outline.set_shader_parameter(&"grosor", grosor)
	_material_outline.set_shader_parameter(&"uv_min", minimo_uv)
	_material_outline.set_shader_parameter(&"uv_max", maximo_uv)
	_material_outline.set_shader_parameter(&"tamano_region_px", rect_region.size)
	_material_outline.set_shader_parameter(&"centro_local", _fuente.get_rect().get_center())


func _obtener_rect_region() -> Rect2:
	if _fuente.region_enabled:
		return Rect2(_fuente.region_rect.position, _fuente.region_rect.size.abs())
	var tamano_textura := Vector2(_fuente.texture.get_size())
	var tamano_frame := tamano_textura / Vector2(_fuente.hframes, _fuente.vframes)
	return Rect2(Vector2(_fuente.frame_coords) * tamano_frame, tamano_frame)
