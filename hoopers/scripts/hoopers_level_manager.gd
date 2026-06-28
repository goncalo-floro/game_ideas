extends Node3D

@export var platform_scene: PackedScene
@export var ball: CharacterBody3D
@export var platform_thickness: float = 0.2
@export var grid_spacing: float = 2.0

static var current_matrix: Array = []
static var platform_stacks: Dictionary = {}
static var teleport_positions: Dictionary = {}

var current_level_name: String = "hoopers_start"
var data_node: Node

func _ready():
	# Instancia o nó de dados se não existir
	data_node = get_node_or_null("/root/HoopersData")
	if not data_node:
		var data_script = load("res://scripts/hoopers_data.gd")
		data_node = data_script.new()
		data_node.name = "HoopersData"
		get_tree().root.add_child(data_node)
	
	load_level(current_level_name)
	ball.landed_on_platform.connect(_on_ball_landed)

func load_level(level_id: String):
	# Limpa plataformas antigas
	for stack in platform_stacks.values():
		for platform in stack:
			platform.queue_free()
	platform_stacks.clear()
	teleport_positions.clear()
	
	current_level_name = level_id
	current_matrix = data_node.level_map[level_id].duplicate(true)
	
	for z in range(current_matrix.size()):
		for x in range(current_matrix[z].size()):
			var cell_value = current_matrix[z][x]
			var grid_pos = Vector2i(x, z)
			
			if cell_value == "0":
				continue
			
			if cell_value.is_valid_int():
				var height = cell_value.to_int()
				create_platform_stack(grid_pos, height, false)
			else:
				create_platform_stack(grid_pos, 1, true)
				teleport_positions[cell_value] = grid_pos
	
	reset_ball_position()

func create_platform_stack(grid_pos: Vector2i, height: int, is_teleporter: bool):
	var stack = []
	
	for i in range(height):
		var platform = platform_scene.instantiate()
		platform.grid_position = grid_pos
		platform.layer_index = i
		platform.is_teleporter_base = is_teleporter
		
		var y_pos = (i * platform_thickness) + (platform_thickness / 2.0)
		platform.position = Vector3(grid_pos.x * grid_spacing, y_pos, grid_pos.y * grid_spacing)
		
		add_child(platform)
		stack.append(platform)
		
		platform.platform_broken.connect(_on_platform_broken)
	
	platform_stacks[grid_pos] = stack

func _on_platform_broken(grid_pos: Vector2i, layer_info: int):
	if layer_info == -1:
		# Teleporte ativado
		var teleport_id = current_matrix[grid_pos.y][grid_pos.x]
		_on_teleport_activated(teleport_id)
		return
	
	if platform_stacks.has(grid_pos):
		var stack = platform_stacks[grid_pos]
		var new_height = stack.size() - 1
		
		if new_height <= 0:
			current_matrix[grid_pos.y][grid_pos.x] = "0"
			platform_stacks.erase(grid_pos)
		else:
			current_matrix[grid_pos.y][grid_pos.x] = str(new_height)
			platform_stacks[grid_pos] = stack.slice(0, new_height)

func _on_teleport_activated(target_level: String):
	if data_node.level_map.has(target_level):
		var return_teleport = current_level_name
		
		load_level(target_level)
		
		if teleport_positions.has(return_teleport):
			var target_pos = teleport_positions[return_teleport]
			place_ball_at_grid(target_pos)

func _on_ball_landed(grid_pos: Vector2i):
	if not platform_stacks.has(grid_pos) or current_matrix[grid_pos.y][grid_pos.x] == "0":
		die()
		return
	
	var stack = platform_stacks[grid_pos]
	if stack.size() > 0:
		var top_platform = stack[stack.size() - 1]
		top_platform.hit()

func place_ball_at_grid(grid_pos: Vector2i):
	var world_pos = Vector3(grid_pos.x * grid_spacing, 0, grid_pos.y * grid_spacing)
	
	if platform_stacks.has(grid_pos):
		var stack_height = platform_stacks[grid_pos].size()
		world_pos.y = (stack_height * platform_thickness) + 0.6
	
	ball.global_position = world_pos
	ball.current_grid_pos = grid_pos
	ball.target_grid_pos = grid_pos
	ball.current_state = ball.BallState.GROUNDED
	ball.velocity = Vector3.ZERO

func reset_ball_position():
	for z in range(current_matrix.size()):
		for x in range(current_matrix[z].size()):
			var cell = current_matrix[z][x]
			if cell != "0":
				place_ball_at_grid(Vector2i(x, z))
				return

func die():
	load_level(current_level_name)

static func get_top_y_position(grid_pos: Vector2i) -> float:
	if platform_stacks.has(grid_pos):
		var stack = platform_stacks[grid_pos]
		return stack.size() * 0.2  # platform_thickness
	return 0.0
