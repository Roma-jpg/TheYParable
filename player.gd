extends CharacterBody3D

@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var jump_force := 5.0
@export var mouse_sensitivity := 0.1
@export var gravity := 9.8

@onready var head := $Head
@onready var camera := $Head/Camera3D

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
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, -85.0, 85.0)
		head.rotation_degrees.x = pitch

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
	var input_dir := Vector2.ZERO
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	input_dir.y = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

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
