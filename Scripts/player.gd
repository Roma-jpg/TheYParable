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
@onready var respawn_anim: AnimatedSprite2D = $AnimatedSprite2D


@export var push_force: float = 150.0           # Tune: higher = stronger push (try 100-300)
@export var push_layers: int = 1 << 5           # Layer 6 (bitshift: 1<<5 = 32 = layer 6)
@export var max_push_distance: float = 1.5      # How far player can push (raycast limit)
@export var player_mass: float = 60.0           # "Player weight" for heavy box resistance
	
	
@export var save_interval := 10.0
@export var fall_limit_y := -50.0
@export var respawn_sound: AudioStream

var save_timer := 0.0
var saved_position: Vector3
var saved_rotation: Vector3
var has_saved := false

@onready var sfx_player := AudioStreamPlayer3D.new()

# Для настроек
var epileptic_mode_enabled := false
var slippery_world_enabled := false
var temperature_mode := "20с"

var input_delay := 0.0
var input_queue := []

var camera_shake_strength := 0.0
var camera_base_rotation := Vector3.ZERO


# Флаги возможностей
var can_move := true
var can_jump := true
var can_sprint := true
var can_look := true

var controls_locked := false

var pitch := 0.0

@export var gamepad_deadzone := 0.15  # Мертвая зона для стиков (защита от drift)
@export var gamepad_sensitivity_horizontal := 2.0  # Чувствительность правого стика
@export var gamepad_sensitivity_vertical := 1.5  # Чувствительность правого стика
@export var touchpad_sensitivity := 3.0  # Чувствительность сенсорной панели

var using_gamepad := false  # Флаг использования геймпада
var last_input_type := "keyboard"  # Последний использованный тип ввода

func _ready():
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	respawn_anim.visible = false
	camera_base_rotation = camera.rotation

	
	sfx_player.stream = respawn_sound
	add_child(sfx_player)

	# Initial checkpoint save on game start
	saved_position = global_position
	saved_rotation = rotation
	has_saved = true
	apply_misc_settings()
	print("Checkpoint saved on game start at: ", saved_position)

func _on_joy_connection_changed(device_id: int, connected: bool):
	if connected:
		print("Gamepad connected: ", Input.get_joy_name(device_id))
		using_gamepad = true
	else:
		print("Gamepad disconnected")
		# Проверяем, остались ли другие подключенные геймпады
		var joypads = Input.get_connected_joypads()
		using_gamepad = joypads.size() > 0

func _process_gamepad_input(delta):
	if not using_gamepad or controls_locked or not can_look:
		return
	
	# Получаем данные с правого стика
	var right_stick_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var right_stick_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	
	# Применяем мертвую зону для защиты от drift
	if abs(right_stick_x) < gamepad_deadzone:
		right_stick_x = 0
	if abs(right_stick_y) < gamepad_deadzone:
		right_stick_y = 0
	
	# Вращение камеры с помощью правого стика
	if right_stick_x != 0:
		rotate_y(-right_stick_x * gamepad_sensitivity_horizontal * delta)
	
	if right_stick_y != 0:
		pitch += right_stick_y * gamepad_sensitivity_vertical * delta
		pitch = clamp(pitch, -85.0, 85.0)
		camera.rotation.x = deg_to_rad(pitch)


func _unhandled_input(event):
	# Определяем тип последнего ввода
	if (event is InputEventKey or event is InputEventMouse or 
		event is InputEventMouseMotion):
		last_input_type = "keyboard"
		using_gamepad = false
	elif (event is InputEventJoypadButton or 
		  event is InputEventJoypadMotion):
		last_input_type = "gamepad"
		using_gamepad = true

	if epileptic_mode_enabled:
		input_queue.append({ "event": event, "time": Time.get_ticks_msec() + randi_range(500, 700) })

	if controls_locked or not can_look:
		return

	# Обработка мыши
	if event is InputEventMouseMotion:
		# Только если активно управление мышью
		if not using_gamepad or last_input_type == "keyboard":
			rotate_y(-event.relative.x * mouse_sensitivity_horizontal * 0.01)
			pitch -= event.relative.y * mouse_sensitivity_vertical * 0.01
			pitch = clamp(pitch, -85.0, 85.0)
			camera.rotation.x = deg_to_rad(pitch)
	
	# Обработка сенсорной панели на DualShock
	elif event is InputEventScreenDrag:
		if event.index == 0:  # Основной палец
			rotate_y(-event.relative.x * touchpad_sensitivity * 0.01)
			pitch -= event.relative.y * touchpad_sensitivity * 0.01
			pitch = clamp(pitch, -85.0, 85.0)
			camera.rotation.x = deg_to_rad(pitch)


func _physics_process(delta):
	
	_process_gamepad_input(delta)
	
	if epileptic_mode_enabled:
		_process_input_queue()
	# Гравитация
	if not is_on_floor():
		var grav = ProjectSettings.get_setting("physics/3d/default_gravity")
		velocity.y -= grav * delta


	if controls_locked or not can_move:
		velocity.x = 0
		velocity.z = 0
	else:
		handle_movement(delta)
	_push_rigidbodies(delta)
	move_and_slide()
	save_timer += delta
	if save_timer >= save_interval:
		save_timer = 0.0
		
		if velocity.y >= 0.0:
			saved_position = global_position
			saved_rotation = rotation
			has_saved = true
			print("Checkpoint updated at: ", saved_position, " | velocity.y = ", velocity.y)
		else:
			print("Checkpoint skipped - falling | velocity.y = ", velocity.y)

	_apply_camera_shake(delta)
	# Teleport if fallen too low
	if has_saved and global_position.y <= fall_limit_y:
		_teleport_to_saved()

func handle_movement(delta):
	# Get input based on camera direction
	var camera_forward = camera.global_transform.basis.z
	var camera_right = camera.global_transform.basis.x
	
	var input_dir := Vector2.ZERO
	
	# Обработка ввода с клавиатуры и геймпада
	if using_gamepad:
		# Используем левый стик для движения
		var left_stick_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		var left_stick_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		
		# Применяем мертвую зону
		if abs(left_stick_x) < gamepad_deadzone:
			left_stick_x = 0
		if abs(left_stick_y) < gamepad_deadzone:
			left_stick_y = 0
		
		input_dir.x = left_stick_x
		input_dir.y = -left_stick_y  # Инвертируем ось Y для соответствия WASD
		
		# Альтернатива: D-pad (крестик) для точного управления
		if Input.is_action_pressed("gamepad_dpad_right"):
			input_dir.x = 1.0
		elif Input.is_action_pressed("gamepad_dpad_left"):
			input_dir.x = -1.0
		
		if Input.is_action_pressed("gamepad_dpad_up"):
			input_dir.y = 1.0
		elif Input.is_action_pressed("gamepad_dpad_down"):
			input_dir.y = -1.0
	else:
		# Клавиатура
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_backward")
	
	# Calculate direction relative to camera
	var direction = Vector3.ZERO
	direction += camera_forward * input_dir.y
	direction += camera_right * input_dir.x
	direction.y = 0
	if direction.length() > 0:
		direction = direction.normalized()

	var speed := walk_speed
	
	# Обработка спринта (геймпад)
	if using_gamepad:
		if can_sprint and Input.is_action_pressed("gamepad_sprint"):
			speed = sprint_speed
		# Альтернатива: кнопка левого стика для спринта
		if can_sprint and Input.is_action_pressed("gamepad_left_stick_click"):
			speed = sprint_speed
	else:
		if can_sprint and Input.is_action_pressed("sprint"):
			speed = sprint_speed

	var target_x = direction.x * speed
	var target_z = direction.z * speed

	var factor = 0.03
	if slippery_world_enabled:
		velocity.x = lerp(velocity.x, target_x, factor * delta * 60)
		velocity.z = lerp(velocity.z, target_z, factor * delta * 60)
	else:
		velocity.x = target_x
		velocity.z = target_z

	# Обработка прыжка
	var jump_pressed = false
	if using_gamepad:
		jump_pressed = Input.is_action_just_pressed("gamepad_jump")
	else:
		jump_pressed = Input.is_action_just_pressed("jump")
	
	if can_jump and jump_pressed and is_on_floor():
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

func _teleport_to_saved():
	global_position = saved_position
	rotation = saved_rotation
	velocity = Vector3.ZERO
	
	sfx_player.global_position = global_position
	
	respawn_anim.visible = true
	respawn_anim.frame = 0
	respawn_anim.play()
	
	if sfx_player.stream:
		print("Playing respawn sound")
		sfx_player.play()
	else:
		print("ERROR: No audio stream assigned")
	
	await respawn_anim.animation_finished
	respawn_anim.visible = false

func apply_misc_settings():
	var m = Settings.settings["misc"]

	epileptic_mode_enabled = m["epileptic_mode"]
	slippery_world_enabled = m["slippery_world"]
	temperature_mode = m["temperature"]

	_apply_temperature()

func _apply_temperature():
	match temperature_mode:
		"26с":
			camera_shake_strength = 0.0
		"20с":
			camera_shake_strength = 0.03
		"15с":
			camera_shake_strength = 0.1
		"Ниже нуля":
			camera_shake_strength = 0.15

func _apply_camera_shake(delta):
	if camera_shake_strength <= 0.0:
		return
	var shake_x = randf_range(-camera_shake_strength, camera_shake_strength)
	var shake_y = randf_range(-camera_shake_strength, camera_shake_strength)
	var shake_z = randf_range(-camera_shake_strength, camera_shake_strength)

	camera.rotation = camera_base_rotation + Vector3(shake_x, shake_y, shake_z)
	
	camera_base_rotation.x = camera.rotation.x
	camera_base_rotation.y = camera.rotation.y
	camera_base_rotation.z = camera.rotation.z


func _process_input_queue():
	var now = Time.get_ticks_msec()

	for i in range(input_queue.size() - 1, -1, -1):
		if input_queue[i]["time"] <= now:
			_unhandled_input(input_queue[i]["event"])
			input_queue.remove_at(i)
