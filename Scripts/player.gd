extends CharacterBody3D

@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var jump_force := 5.0
@export var mouse_sensitivity_horizontal := 0.1
@export var mouse_sensitivity_vertical := 4.5  # Simplified sensitivity
@export var gravity := 9.8

@onready var camera := $Camera3D
	
# Флаги возможностей
var can_move := true
var can_jump := true
var can_sprint := true
var can_look := true

var pitch := 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if not can_look:
		return

	if event is InputEventMouseMotion:
		# Rotate player horizontally (yaw)
		rotate_y(-event.relative.x * mouse_sensitivity_horizontal * 0.01)
		
		# Rotate camera vertically (pitch)
		pitch -= event.relative.y * mouse_sensitivity_vertical * 0.01
		pitch = clamp(pitch, -85.0, 85.0)
		camera.rotation.x = deg_to_rad(pitch)

func _physics_process(delta):
	# Гравитация
	if not is_on_floor():
		velocity.y -= gravity * delta

	if can_move:
		handle_movement(delta)
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

func handle_movement(delta):
	# Get input based on camera direction
	var camera_forward = camera.global_transform.basis.z
	var camera_right = camera.global_transform.basis.x
	
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	
	# Calculate direction relative to camera
	var direction = Vector3.ZERO
	direction += camera_forward * input_dir.y
	direction += camera_right * input_dir.x
	direction.y = 0
	direction = direction.normalized()

	var speed := walk_speed
	if can_sprint and Input.is_action_pressed("sprint"):
		speed = sprint_speed

	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

	if can_jump and Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_force

# ===== Методы управления возможностями =====

func set_can_move(value: bool):
	can_move = value

func set_can_jump(value: bool):
	can_jump = value

func set_can_sprint(value: bool):
	can_sprint = value

func set_can_look(value: bool):
	can_look = value
