extends CharacterBody3D

# ===== ЭКСПОРТИРУЕМЫЕ ПАРАМЕТРЫ =====

# Движение
@export var walk_speed := 4.0
@export var sprint_speed := 7.0
@export var jump_force := 5.0
@export var gravity := 9.8

# Камера и ввод
@export var mouse_sensitivity_horizontal := 0.1
@export var mouse_sensitivity_vertical := 4.5
@export var camera_distance := 0.5
@export var camera_collision_layer := 2
@export var camera_min_distance := 0.1

# Взаимодействие с физикой
@export var push_force: float = 150.0
@export var push_layers: int = 1 << 5      # Слой 6
@export var max_push_distance: float = 1.5
@export var player_mass: float = 60.0

# Сохранение и респаун
@export var save_interval := 10.0
@export var fall_limit_y := -50.0
@export var respawn_sound: AudioStream

# Управление с геймпада
@export var gamepad_deadzone := 0.15
@export var gamepad_sensitivity_horizontal := 2.0
@export var gamepad_sensitivity_vertical := 100.5
@export var touchpad_sensitivity := 3.0

# ===== ССЫЛКИ НА УЗЛЫ =====

@onready var camera := $SpringArm3D/Camera3D
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var interaction_ui: Control = $InteractionUI
@onready var subtitles: CanvasLayer = $Subtitles
@onready var crosshair: Label = $Crosshair/Control/Label
@onready var respawn_anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var sfx_player := AudioStreamPlayer3D.new()

# Меню паузы (дочерние узлы Crosshair)
@onready var pause_menu: Control = $Crosshair/Pause
@onready var resume_button: Button = $Crosshair/Pause/PanelContainer/MarginContainer/VBoxContainer2/MarginContainer/VBoxContainer/ResumeButton
@onready var main_menu_button: Button = $Crosshair/Pause/PanelContainer/MarginContainer/VBoxContainer2/MarginContainer/VBoxContainer/MainMenuButton
@onready var fun_button: Button = $Crosshair/Pause/PanelContainer/MarginContainer/VBoxContainer2/MarginContainer/VBoxContainer/FunButton

# Шаги
@export var footstep_sound_path: String = "res://Assets/Audio/footsteps.wav"
@export var footstep_volume_db: float = 0.0
@export var footstep_max_distance: float = 9999.9

# ===== ВНУТРЕННИЕ ПЕРЕМЕННЫЕ СОСТОЯНИЯ =====

# Камера
var current_camera_distance := camera_distance
var camera_base_rotation := Vector3.ZERO
var camera_shake_strength := 0.0
var pitch := 0.0

# Управление возможностями
var can_move := true
var can_jump := true
var can_sprint := true
var can_look := true
var controls_locked := false

# Система ввода
var using_gamepad := false
var last_input_type := "keyboard"
var input_delay := 0.0
var input_queue := []

# Система бездействия (монологи)
var idle_timer: float = 0.0
var current_idle_stage: int = 0
var is_playing_monologue := false
var idle_stages = [
	{ "time": 900.0,  "monologue": "idle_1" },
	{ "time": 1200.0, "monologue": ["what_if_u_died_1", "what_if_u_died_2", "what_if_u_died_3", "what_if_u_died_4"] },
	{ "time": 1500.0, "monologue": "idle_3" }
]

# Сохранение чекпоинта
var save_timer := 0.0
var saved_position: Vector3
var saved_rotation: Vector3
var has_saved := false

# Настройки (из Settings)
var epileptic_mode_enabled := false
var slippery_world_enabled := false
var temperature_mode := "20с"

# Состояние паузы
var is_paused := false

# Пасхалка с счётчиком прыжков
var jump_count_standing := 0
var gravity_test_triggered := false

# Шаги
var footstep_player: AudioStreamPlayer3D
var was_moving_on_ground: bool = false
var is_sprinting: bool = false

# ===== МЕТОДЫ ЖИЗНЕННОГО ЦИКЛА =====

func _ready():
	# Инициализация
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	
	respawn_anim.visible = false
	camera_base_rotation = camera.rotation
	
	sfx_player.stream = respawn_sound
	add_child(sfx_player)

	# Начальный чекпоинт
	saved_position = global_position
	saved_rotation = rotation
	has_saved = true
	apply_misc_settings()
	print("Чекпоинт сохранён при старте: ", saved_position)
	
	# Настройка меню паузы
	pause_menu.visible = false
	pause_menu.process_mode = PROCESS_MODE_ALWAYS  # Чтобы работало при заморозке дерева
	resume_button.pressed.connect(_on_resume_button_pressed)
	main_menu_button.pressed.connect(_on_main_menu_button_pressed)
	fun_button.pressed.connect(_on_fun_button_pressed)
	pause_menu.gui_input.connect(_on_pause_menu_gui_input)

	# --- NEW: Footstep audio player setup ---
	footstep_player = AudioStreamPlayer3D.new()
	footstep_player.finished.connect(_on_footstep_finished)
	var footstep_stream = load(footstep_sound_path) as AudioStream
	if footstep_stream:
		footstep_player.stream = footstep_stream
		footstep_player.volume_db = footstep_volume_db
		footstep_player.max_distance = footstep_max_distance
		footstep_player.bus = "SFX"  # Change to your sound bus if needed
	else:
		push_error("Footstep sound not found at: ", footstep_sound_path)
	add_child(footstep_player)

func _input(event):
	# Обработка нажатия Escape для возврата в редактор или открытия меню паузы
	if event.is_action_pressed("ui_cancel"):
		var editor = get_tree().get_first_node_in_group("editors")
		if editor:
			editor._return_to_editor()
		else:
			toggle_pause()

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		print("Mouse move detected!")
	# Сбрасываем таймер бездействия при любом вводе
	idle_timer = 0.0
	current_idle_stage = 0
	
	# Определяем тип последнего ввода
	if (event is InputEventKey or event is InputEventMouse or 
		event is InputEventMouseMotion):
		last_input_type = "keyboard"
		using_gamepad = false
	elif (event is InputEventJoypadButton or 
		  event is InputEventJoypadMotion):
		last_input_type = "gamepad"
		using_gamepad = true

	# Режим «эпилепсия» — добавляем события в очередь с задержкой
	if epileptic_mode_enabled:
		input_queue.append({ "event": event, "time": Time.get_ticks_msec() + randi_range(500, 700) })

	if controls_locked or not can_look:
		return

	# Обработка мыши (только если не используется геймпад)
	if event is InputEventMouseMotion and (not using_gamepad or last_input_type == "keyboard"):
		rotate_y(-event.relative.x * mouse_sensitivity_horizontal * 0.01)
		pitch -= event.relative.y * mouse_sensitivity_vertical * 0.01
		pitch = clamp(pitch, -85.0, 85.0)
		camera.rotation.x = deg_to_rad(pitch)
	
	# Обработка сенсорной панели DualShock
	elif event is InputEventScreenDrag and event.index == 0:
		rotate_y(-event.relative.x * touchpad_sensitivity * 0.01)
		pitch -= event.relative.y * touchpad_sensitivity * 0.01
		pitch = clamp(pitch, -85.0, 85.0)
		camera.rotation.x = deg_to_rad(pitch)

func _physics_process(delta):
	# Обработка ввода с геймпада (правый стик)
	_process_gamepad_input(delta)
	
	# Обновление коллизии камеры
	_update_camera_collision()
	
	# Очередь ввода для эпилептического режима
	if epileptic_mode_enabled:
		_process_input_queue()
	
	# Гравитация
	if not is_on_floor():
		var grav = ProjectSettings.get_setting("physics/3d/default_gravity")
		velocity.y -= grav * delta

	# Управление движением
	if controls_locked or not can_move:
		velocity.x = 0
		velocity.z = 0
	else:
		handle_movement(delta)
	
	# Взаимодействие с физическими телами (толкание)
	_push_rigidbodies(delta)
	
	move_and_slide()
	
	var is_moving_on_ground = is_on_floor() and Vector2(velocity.x, velocity.z).length_squared() > 0.01

	if is_moving_on_ground:
		# Set pitch based on sprint state (1.7x when sprinting)
		footstep_player.pitch_scale = 1.5 if is_sprinting else 1.0
		if not footstep_player.playing:
			footstep_player.play()
	else:
		if footstep_player.playing:
			footstep_player.stop()

	was_moving_on_ground = is_moving_on_ground
	# --- END of footstep logic ---

	# Таймер бездействия (только если стоим на месте)
	if is_on_floor() and velocity.length_squared() < 0.01:
		idle_timer += delta
	else:
		idle_timer = 0.0
		current_idle_stage = 0

	# Запуск монолога бездействия, если не играется другой
	if not is_playing_monologue:
		if current_idle_stage < idle_stages.size() and idle_timer >= idle_stages[current_idle_stage]["time"]:
			start_idle_monologue(idle_stages[current_idle_stage]["monologue"])
	
	# Автосохранение чекпоинта (только если не падаем)
	save_timer += delta
	if save_timer >= save_interval:
		save_timer = 0.0
		if velocity.y >= 0.0:
			saved_position = global_position
			saved_rotation = rotation
			has_saved = true
			print("Чекпоинт обновлён: ", saved_position, " | velocity.y = ", velocity.y)
		else:
			print("Чекпоинт пропущен (падение): velocity.y = ", velocity.y)

	# Эффект дрожания камеры
	_apply_camera_shake(delta)
	
	# Телепортация при падении ниже лимита
	if has_saved and global_position.y <= fall_limit_y:
		_teleport_to_saved()

# ===== ОБРАБОТКА ВВОДА =====

func _on_joy_connection_changed(device_id: int, connected: bool):
	# Обновляем флаг наличия геймпада
	if connected:
		print("Геймпад подключён: ", Input.get_joy_name(device_id))
		using_gamepad = true
	else:
		print("Геймпад отключён")
		var joypads = Input.get_connected_joypads()
		using_gamepad = joypads.size() > 0

func _process_gamepad_input(delta):
	# Вращение камеры правым стиком геймпада
	if not using_gamepad or controls_locked or not can_look:
		return
	
	var right_stick_x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var right_stick_y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	
	# Мёртвая зона
	if abs(right_stick_x) < gamepad_deadzone:
		right_stick_x = 0
	if abs(right_stick_y) < gamepad_deadzone:
		right_stick_y = 0
	
	if right_stick_x != 0:
		rotate_y(-right_stick_x * gamepad_sensitivity_horizontal * delta)	 # yaw usually stays like this

	if right_stick_y != 0:
		pitch -= right_stick_y * gamepad_sensitivity_vertical * delta
		pitch = clamp(pitch, -85.0, 85.0)
		camera.rotation.x = deg_to_rad(pitch)   # ← add this

# ===== ДВИЖЕНИЕ И ФИЗИКА =====

func handle_movement(delta):
	# Направления камеры
	var camera_forward = camera.global_transform.basis.z
	var camera_right = camera.global_transform.basis.x
	
	var input_dir := Vector2.ZERO
	
	# Получение ввода в зависимости от типа управления
	if using_gamepad:
		# Левый стик
		var left_stick_x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
		var left_stick_y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
		
		if abs(left_stick_x) < gamepad_deadzone:
			left_stick_x = 0
		if abs(left_stick_y) < gamepad_deadzone:
			left_stick_y = 0
		
		input_dir.x = left_stick_x
		input_dir.y = left_stick_y  # Инверсия для соответствия WASD
		
		# D-pad (крестовина)
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
	
	# Направление движения относительно камеры
	var direction = Vector3.ZERO
	direction += camera_forward * input_dir.y
	direction += camera_right * input_dir.x
	direction.y = 0
	if direction.length() > 0:
		direction = direction.normalized()

	# Выбор скорости (ходьба / спринт)
	var speed := walk_speed
	var sprint_input = false
	if using_gamepad:
		sprint_input = (Input.is_action_pressed("sprint"))
		if can_sprint and sprint_input:
			speed = sprint_speed
	else:
		sprint_input = Input.is_action_pressed("sprint")
		if can_sprint and sprint_input:
			speed = sprint_speed

	# --- NEW: Track sprint state for footstep pitch ---
	is_sprinting = sprint_input and direction.length() > 0  # only sprint when actually moving
	# ----------------------------------------------------

	# Применение скорости к velocity
	var target_x = direction.x * speed
	var target_z = direction.z * speed

	if slippery_world_enabled:
		# Плавное ускорение (скользкий мир)
		var factor = 0.03
		velocity.x = lerp(velocity.x, target_x, factor * delta * 60)
		velocity.z = lerp(velocity.z, target_z, factor * delta * 60)
	else:
		# Мгновенное изменение скорости
		velocity.x = target_x
		velocity.z = target_z

	# Прыжок
	var jump_pressed = false
	if using_gamepad:
		jump_pressed = Input.is_action_just_pressed("gamepad_jump")
	else:
		jump_pressed = Input.is_action_just_pressed("jump")
	
	if can_jump and jump_pressed and is_on_floor():
		velocity.y = jump_force

func _push_rigidbodies(delta: float) -> void:
	# Толкание RigidBody при столкновении
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
		
		if collider is RigidBody3D:
			var normal = collision.get_normal()
			
			# Не толкаем, если игрок стоит сверху (чтобы не создавать крутящий момент при приземлении)
			if normal.y > 0.65:
				continue
			
			# Пропускаем почти вертикальные столкновения
			if abs(normal.y) > 0.9:
				continue
			
			var push_dir = -normal
			push_dir.y = 0.0
			if push_dir.length_squared() < 0.01:
				continue
			push_dir = push_dir.normalized()
			
			# Учитываем соотношение масс
			var mass_ratio = min(player_mass / collider.mass, 1.0)
			if mass_ratio < 0.25:
				continue
			
			var contact_pos_local = collision.get_position() - collider.global_position
			var impulse = push_dir * push_force * mass_ratio * delta
			
			collider.apply_impulse(impulse, contact_pos_local)
			
			# Небольшое замедление игрока при толкании
			velocity.x *= 0.9
			velocity.z *= 0.9

# ===== КАМЕРА =====

func _update_camera_collision():
	# Корректировка расстояния камеры при столкновении с препятствиями
	var space_state = get_world_3d().direct_space_state
	
	var from = global_position + Vector3(0, 1.5, 0)  # Точка на уровне глаз
	var to = from - camera.global_transform.basis.z * camera_distance
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = camera_collision_layer
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var collision_point = result.position
		var new_distance = from.distance_to(collision_point) - 0.1
		current_camera_distance = max(new_distance, camera_min_distance)
	else:
		# Плавное возвращение к нормальному расстоянию
		current_camera_distance = lerp(current_camera_distance, camera_distance, 0.1)
	
	camera.position.z = -current_camera_distance

func _apply_camera_shake(_delta):
	# Дрожание камеры (например, от холода)
	if camera_shake_strength <= 0.0:
		return
	var shake_x = randf_range(-camera_shake_strength, camera_shake_strength)
	var shake_y = randf_range(-camera_shake_strength, camera_shake_strength)
	var shake_z = randf_range(-camera_shake_strength, camera_shake_strength)

	camera.rotation = camera_base_rotation + Vector3(shake_x, shake_y, shake_z)
	
	# Обновляем базовый поворот, чтобы дрожание накапливалось правильно
	camera_base_rotation.x = camera.rotation.x
	camera_base_rotation.y = camera.rotation.y
	camera_base_rotation.z = camera.rotation.z

# ===== УПРАВЛЕНИЕ ИНТЕРФЕЙСОМ =====

func hide_game_ui():
	# Скрываем элементы интерфейса
	_fade_node(interaction_ui, 0.0)
	_fade_node(subtitles, 0.0)
	_fade_node(crosshair, 0.0)

func show_game_ui():
	# Показываем элементы интерфейса
	_fade_node(interaction_ui, 1.0)
	_fade_node(subtitles, 1.0)
	_fade_node(crosshair, 1.0)

func _fade_node(node: Node, target_alpha: float, duration := 1.0):
	# Плавное изменение прозрачности узла
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

# ===== СОХРАНЕНИЕ И РЕСПАУН =====

func _teleport_to_saved():
	# Телепортация к последнему чекпоинту
	global_position = saved_position
	rotation = saved_rotation
	velocity = Vector3.ZERO
	
	sfx_player.global_position = global_position
	
	# Анимация и звук респауна
	respawn_anim.visible = true
	respawn_anim.frame = 0
	respawn_anim.play()
	
	if sfx_player.stream:
		print("Воспроизведение звука респауна")
		sfx_player.play()
	else:
		print("ОШИБКА: Не назначен аудиопоток")
	
	await respawn_anim.animation_finished
	respawn_anim.visible = false

# ===== НАСТРОЙКИ =====

func apply_misc_settings():
	# Применение настроек из глобального объекта Settings
	var m = Settings.settings["misc"]

	epileptic_mode_enabled = m["epileptic_mode"]
	slippery_world_enabled = m["slippery_world"]
	temperature_mode = m["temperature"]

	_apply_temperature()

func _apply_temperature():
	# Установка силы дрожания камеры в зависимости от температуры
	match temperature_mode:
		"26с":
			camera_shake_strength = 0.0
		"-20с":
			camera_shake_strength = 0.1
		"-15с":
			camera_shake_strength = 0.03
		"Ниже нуля":
			camera_shake_strength = 0.01

# ===== ОЧЕРЕДЬ ВВОДА (ЭПИЛЕПТИЧЕСКИЙ РЕЖИМ) =====

func _process_input_queue():
	# Обработка отложенных событий ввода
	var now = Time.get_ticks_msec()

	for i in range(input_queue.size() - 1, -1, -1):
		if input_queue[i]["time"] <= now:
			_unhandled_input(input_queue[i]["event"])
			input_queue.remove_at(i)

# ===== МОНОЛОГИ БЕЗДЕЙСТВИЯ =====

func start_idle_monologue(monologue_data):
	# Запуск монолога, если ещё не играется другой
	if is_playing_monologue:
		return
	is_playing_monologue = true
	_play_monologue_async(monologue_data)

func _play_monologue_async(monologue_data):
	# Воспроизведение одного или нескольких монологов через глобальную систему
	if monologue_data is String:
		await MonologueSystem.play_and_wait_monologues([monologue_data])
	elif monologue_data is Array:
		await MonologueSystem.play_and_wait_monologues(monologue_data)
	is_playing_monologue = false
	current_idle_stage += 1  # Переход к следующему этапу

# ===== УПРАВЛЕНИЕ ВОЗМОЖНОСТЯМИ =====

func set_can_move(value: bool):
	can_move = value

func set_can_jump(value: bool):
	can_jump = value

func set_can_sprint(value: bool):
	can_sprint = value

func set_can_look(value: bool):
	can_look = value

func lock_controls():
	# Блокировка управления и показ курсора
	controls_locked = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func unlock_controls():
	# Разблокировка управления и захват мыши
	controls_locked = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# ===== МЕНЮ ПАУЗЫ =====

func toggle_pause():
	# Переключение состояния паузы
	if is_paused:
		unpause_game()
	else:
		pause_game()

func pause_game():
	# Постановка игры на паузу
	is_paused = true
	pause_menu.visible = true
	lock_controls()                # Блокируем ввод игрока
	get_tree().paused = true        # Замораживаем всё, кроме узлов с process_mode = ALWAYS

func unpause_game():
	# Снятие игры с паузы
	is_paused = false
	pause_menu.visible = false
	unlock_controls()               # Возвращаем ввод игроку
	get_tree().paused = false       # Размораживаем дерево

func _on_resume_button_pressed() -> void:
	unpause_game()

func _on_main_menu_button_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func _on_fun_button_pressed() -> void:
	#fun_button.text = "НЕЕЕЕЕТТ"
	$Crosshair/Pause/AudioStreamPlayer3D.play()
	await $Crosshair/Pause/AudioStreamPlayer3D.finished
	fun_button.text = "ПРОШУ НЕ НАЖИМАЙ СЮДА"
	
func _on_pause_menu_gui_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		unpause_game()

func _on_footstep_finished():
	# If the player is still moving on ground, restart the sound
	if is_on_floor() and Vector2(velocity.x, velocity.z).length_squared() > 0.01:
		footstep_player.play()
