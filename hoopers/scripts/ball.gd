extends CharacterBody3D

enum BallState { ASCENDING, DESCENDING, GROUNDED }
var current_state: BallState = BallState.GROUNDED

@export var max_jump_height: float = 4.0
@export var jump_duration: float = 0.8
@export var grid_spacing: float = 2.0

var gravity: float
var jump_velocity: float
var vertical_speed: float = 0.0
var time_in_air: float = 0.0

var current_grid_pos: Vector2i
var target_grid_pos: Vector2i
var start_y: float
var target_y: float

var next_move_direction: Vector2i = Vector2i.ZERO
var can_receive_input: bool = false

var level_manager: Node

signal landed_on_platform(grid_pos)

func _ready():
	calculate_jump_physics()
	current_grid_pos = world_to_grid(global_position)
	target_grid_pos = current_grid_pos
	start_y = global_position.y
	target_y = start_y
	
	var managers = get_tree().get_nodes_in_group("LevelManager")
	if managers.size() > 0:
		level_manager = managers[0]
	else:
		level_manager = get_parent()

func calculate_jump_physics():
	jump_velocity = (2.0 * max_jump_height) / (jump_duration / 2.0)
	gravity = (2.0 * max_jump_height) / pow(jump_duration / 2.0, 2)

func _physics_process(delta):
	if can_receive_input:
		process_input()
	
	match current_state:
		BallState.GROUNDED:
			handle_grounded_state()
		BallState.ASCENDING, BallState.DESCENDING:
			handle_airborne_state(delta)
	
	move_and_slide()

func process_input():
	var input_dir = Vector2i.ZERO
	
	if Input.is_action_just_pressed("move_up"):
		input_dir = Vector2i(0, -1)
	elif Input.is_action_just_pressed("move_down"):
		input_dir = Vector2i(0, 1)
	elif Input.is_action_just_pressed("move_left"):
		input_dir = Vector2i(-1, 0)
	elif Input.is_action_just_pressed("move_right"):
		input_dir = Vector2i(1, 0)
	
	if input_dir != Vector2i.ZERO:
		var potential_next_pos = target_grid_pos + input_dir
		if is_valid_move(potential_next_pos):
			next_move_direction = input_dir
			can_receive_input = false

func handle_grounded_state():
	var next_pos = current_grid_pos + next_move_direction
	
	if not is_valid_move(next_pos):
		next_pos = current_grid_pos
		next_move_direction = Vector2i.ZERO
	
	target_grid_pos = next_pos
	target_y = level_manager.get_top_y_position(target_grid_pos)
	
	next_move_direction = Vector2i.ZERO
	can_receive_input = true  
	
	start_jump()

func handle_airborne_state(delta):
	can_receive_input = true
	
	time_in_air += delta
	
	if current_state == BallState.ASCENDING:
		vertical_speed = jump_velocity - gravity * time_in_air
		if vertical_speed <= 0:
			current_state = BallState.DESCENDING
	else:
		vertical_speed -= gravity * delta
	
	var target_world_x = target_grid_pos.x * grid_spacing
	var target_world_z = target_grid_pos.y * grid_spacing
	var horizontal_target = Vector3(target_world_x, global_position.y, target_world_z)
	global_position = global_position.move_toward(horizontal_target, grid_spacing * 3.0 * delta)
	
	var current_y = start_y + (jump_velocity * time_in_air) - (0.5 * gravity * time_in_air * time_in_air)
	global_position.y = current_y
	
	if current_state == BallState.DESCENDING and global_position.y <= target_y + 0.1:
		land()

func start_jump():
	current_state = BallState.ASCENDING
	time_in_air = 0.0
	start_y = global_position.y
	vertical_speed = jump_velocity
	can_receive_input = true

func land():
	current_state = BallState.GROUNDED
	current_grid_pos = target_grid_pos
	global_position.y = target_y + 0.1
	
	landed_on_platform.emit(current_grid_pos)

func is_valid_move(grid_pos: Vector2i) -> bool:
	var matrix = level_manager.current_matrix
	if not (grid_pos.y >= 0 and grid_pos.y < matrix.size() and 
			grid_pos.x >= 0 and grid_pos.x < matrix[0].size()):
		return false
	
	var cell_value = matrix[grid_pos.y][grid_pos.x]
	if cell_value == "0":
		return false
	
	var target_height = cell_value.to_int() if cell_value.is_valid_int() else 1
	var current_height = get_current_stack_height()
	
	var height_difference = target_height - current_height
	var max_height_in_units = max_jump_height / 0.2
	
	if height_difference > max_height_in_units:
		return false
	
	return true

func get_current_stack_height() -> int:
	var matrix = level_manager.current_matrix
	var cell = matrix[current_grid_pos.y][current_grid_pos.x]
	return cell.to_int() if cell.is_valid_int() else 1

func world_to_grid(world_pos: Vector3) -> Vector2i:
	return Vector2i(round(world_pos.x / grid_spacing), round(world_pos.z / grid_spacing))
