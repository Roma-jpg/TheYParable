extends Node3D

# Экспортируемые переменные для гибкости (можно назначить в инспекторе)
@export var cube_normal: RigidBody3D
@export var cube_black: RigidBody3D

# Начальные позиции кубиков
var normal_start_pos: Vector3
var black_start_pos: Vector3

var _first_fall_done := false          # Был ли показан монолог о потере
var _handling_normal := false           # Флаг обработки падения обычного кубика
var _handling_black := false            # Флаг обработки падения чёрного кубика

func _ready() -> void:
	# Сохраняем начальные позиции
	normal_start_pos = cube_normal.position
	black_start_pos = cube_black.position
	
	_lock_player_controls()
	await get_tree().create_timer(1.0).timeout
	await MonologueSystem.play_and_wait_monologues(["puzzle_room_intro_1", "puzzle_room_intro_2", "puzzle_room_intro_3"])
	_unlock_player_controls()

func _process(_delta: float) -> void:
	# Проверяем падение обычного кубика
	if cube_normal.position.y < -20 and not _handling_normal:
		_handling_normal = true
		_handle_fall(cube_normal, normal_start_pos, "_handling_normal")
	
	# Проверяем падение чёрного кубика
	if cube_black.position.y < -20 and not _handling_black:
		_handling_black = true
		_handle_fall(cube_black, black_start_pos, "_handling_black")

func _handle_fall(cube: RigidBody3D, start_pos: Vector3, handling_var_name: String) -> void:
	await get_tree().create_timer(1.0).timeout
	
	# Если кубик за время ожидания вернулся (например, подхватили), сбрасываем флаг
	if cube.position.y >= -20:
		set(handling_var_name, false)
		return
	
	# Монолог только при первом падении любого кубика
	if not _first_fall_done:
		MonologueSystem.play_monologue("how_could_you_lose_a_cube")
		await MonologueSystem.monologue_finished
		await get_tree().create_timer(1.0).timeout
		_first_fall_done = true
	else:
		await get_tree().create_timer(1.0).timeout
	
	# Восстанавливаем позицию и сбрасываем скорости
	cube.position = start_pos
	cube.linear_velocity = Vector3.ZERO
	cube.angular_velocity = Vector3.ZERO
	cube.sleeping = false
	
	# Сбрасываем флаг обработки
	set(handling_var_name, false)

func _lock_player_controls():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("lock_controls"):
			p.lock_controls()

func _unlock_player_controls():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("unlock_controls"):
			p.unlock_controls()
