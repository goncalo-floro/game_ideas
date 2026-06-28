extends Control

@onready var btn_up = $MarginContainer/VBoxContainer/HBoxContainer/Up
@onready var btn_down = $MarginContainer/VBoxContainer/HBoxContainer/Down
@onready var btn_left = $MarginContainer/VBoxContainer/HBoxContainer/Left
@onready var btn_right = $MarginContainer/VBoxContainer/HBoxContainer/Right

var ball: CharacterBody3D

func _ready():
	btn_up.pressed.connect(func(): simulate_action("move_up"))
	btn_down.pressed.connect(func(): simulate_action("move_down"))
	btn_left.pressed.connect(func(): simulate_action("move_left"))
	btn_right.pressed.connect(func(): simulate_action("move_right"))

func initialize(ball_node: CharacterBody3D):
	ball = ball_node

func simulate_action(action_name: String):
	if ball and ball.can_receive_input:
		var event = InputEventAction.new()
		event.action = action_name
		event.pressed = true
		Input.parse_input_event(event)

func _process(delta):
	if ball:
		var can_press = ball.can_receive_input
		btn_up.disabled = not can_press
		btn_down.disabled = not can_press
		btn_left.disabled = not can_press
		btn_right.disabled = not can_press
		
		var color = Color.WHITE if can_press else Color.GRAY
		btn_up.modulate = color
		btn_down.modulate = color
		btn_left.modulate = color
		btn_right.modulate = color
