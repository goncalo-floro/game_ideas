extends StaticBody3D

@export var grid_position: Vector2i
@export var layer_index: int = 0
@export var is_teleporter_base: bool = false

signal platform_broken(grid_pos, layer_info)

func _ready():
	update_appearance()

func update_appearance():
	var material = StandardMaterial3D.new()
	
	if is_teleporter_base:
		material.albedo_color = Color.PURPLE
		material.emission_enabled = true
		material.emission = Color.PURPLE * 0.3
	else:
		# variação de cor com a altura da camada
		var brightness = 0.4 + (layer_index * 0.15)
		material.albedo_color = Color(0.3, 0.7, brightness)
	
	$MeshInstance3D.material_override = material

func hit():
	if is_teleporter_base:
		platform_broken.emit(grid_position, -1)  # -1 = teleporte
	else:
		platform_broken.emit(grid_position, layer_index)
		queue_free()
