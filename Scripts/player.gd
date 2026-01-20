extends CharacterBody3D

@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var jump_force := 5.0
@export var mouse_sensitivity_horizontal := 0.1
@export var mouse_sensitivity_vertical := 4.5  # Simplified sensitivity
@export var gravity := 9.8

@onready var camera := $Camera3D

@onready var interaction_ui: Control = $InteractionUI
@onready var subtitles: CanvasLayer = $Subtitles
@onready var crosshair: Label = $Crosshair/Control/Label

@export var push_force: float = 150.0           # Tune: higher = stronger push (try 100-300)
@export var push_layers: int = 1 << 5           # Layer 6 (bitshift: 1<<5 = 32 = layer 6)
@export var max_push_distance: float = 1.5      # How far player can push (raycast limit)
@export var player_mass: float = 60.0           # "Player weight" for heavy box resistance
	
# Флаги возможностей
var can_move := true
var can_jump := true
var can_sprint := true
var can_look := true

var controls_locked := false

var pitch := 0.0

func _ready():
	add_to_group("player")

	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event):
	if controls_locked or not can_look:
		return
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

	if controls_locked or not can_move:
		velocity.x = 0
		velocity.z = 0
	else:
		handle_movement(delta)
	_push_rigidbodies(delta)
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

# Add this function to your player.gd
func _push_rigidbodies(delta: float) -> void:
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is RigidBody3D:
			var normal = collision.get_normal()
			
			# Skip pushing if mostly standing on top (prevents downward torque on landing)
			if normal.y > 0.65:	# ← tune 0.6–0.8; higher = more strict
				continue
			
			# Also skip if almost vertical (side hits only)
			if abs(normal.y) > 0.9:
				continue
			
			var push_dir = -normal
			push_dir.y = 0.0
			if push_dir.length_squared() < 0.01:
				continue
			push_dir = push_dir.normalized()
			
			var mass_ratio = min(player_mass / collider.mass, 1.0)
			if mass_ratio < 0.25:
				continue
			
			var contact_pos_local = collision.get_position() - collider.global_position
			var impulse = push_dir * push_force * mass_ratio * delta
			
			collider.apply_impulse(impulse, contact_pos_local)
			
			# Optional: tiny slowdown only when actually pushing side
			velocity.x *= 0.9
			velocity.z *= 0.9

# ===== Методы управления возможностями =====

func set_can_move(value: bool):
	can_move = value

func set_can_jump(value: bool):
	can_jump = value

func set_can_sprint(value: bool):
	can_sprint = value

func set_can_look(value: bool):
	can_look = value
	
func lock_controls():
	controls_locked = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unlock_controls():
	controls_locked = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _fade_node(node: Node, target_alpha: float, duration := 1.0):
	if node == null:
		return

	var tween := create_tween()
	var track := tween.tween_property(
		node,
		"modulate:a",
		target_alpha,
		duration
	)

	if track:
		track.set_trans(Tween.TRANS_SINE)
		track.set_ease(Tween.EASE_IN_OUT)


func hide_game_ui():
	_fade_node(interaction_ui, 0.0)
	_fade_node(subtitles, 0.0)
	_fade_node(crosshair, 0.0)

func show_game_ui():
	_fade_node(interaction_ui, 1.0)
	_fade_node(subtitles, 1.0)
	_fade_node(crosshair, 1.0)
