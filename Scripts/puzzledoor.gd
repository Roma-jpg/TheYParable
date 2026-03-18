extends Node3D

@export var button1_path: NodePath
@export var button2_path: NodePath
@export var door_animation := "opendoor"

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var left_indicator: Label3D = $"../LeftIndicator"
@onready var right_indicator: Label3D = $"../RightIndicator"

# Состояние кубов на кнопках
var cube1_on_button := false   # cube_normal на кнопке 1
var cube2_on_button := false   # cube_black на кнопке 2

# Таймер для обучения
var both_cubes_stable_timer := 0.0
var training_triggered := false
var door_open := false

# Ссылки на Area3D кнопок (чтобы не искать каждый раз)
var button1_area: Area3D
var button2_area: Area3D

func _ready():
	var button1 = get_node(button1_path)
	var button2 = get_node(button2_path)
	
	# Получаем Area3D каждой кнопки по известному пути
	button1_area = button1.get_node("Cylinder/Area3D")
	button2_area = button2.get_node("Cylinder/Area3D")
	
	# Подключаемся ко входам/выходам тел на кнопках
	button1_area.body_entered.connect(_on_button1_body_entered)
	button1_area.body_exited.connect(_on_button1_body_exited)
	button2_area.body_entered.connect(_on_button2_body_entered)
	button2_area.body_exited.connect(_on_button2_body_exited)
	
	# Начальное обновление состояния
	_update_cube_states()

func _process(delta):
	# Обновляем состояние кубов (на случай, если они ушли/пришли)
	_update_cube_states()
	
	# Управление дверью (только если оба нужных куба на месте)
	var should_be_open = cube1_on_button and cube2_on_button
	if should_be_open and not door_open:
		anim.play(door_animation)
		door_open = true
	elif not should_be_open and door_open:
		anim.play_backwards(door_animation)
		door_open = false
	
	# Таймер для обучения (сбрасывается, если кубы ушли)
	if cube1_on_button and cube2_on_button:
		both_cubes_stable_timer += delta
		if both_cubes_stable_timer >= 2.0 and not training_triggered:
			_trigger_training()
	else:
		both_cubes_stable_timer = 0.0

# Проверяем, какие кубы сейчас на кнопках
func _update_cube_states():
	# Собираем все тела на кнопках через сохранённые Area3D
	var bodies_on_button1 = button1_area.get_overlapping_bodies()
	var bodies_on_button2 = button2_area.get_overlapping_bodies()
	
	# Проверяем наличие cube_normal на первой кнопке
	cube1_on_button = false
	for body in bodies_on_button1:
		if body.is_in_group("cube_normal"):
			cube1_on_button = true
			break
	
	# Проверяем наличие cube_black на второй кнопке
	cube2_on_button = false
	for body in bodies_on_button2:
		if body.is_in_group("cube_black"):
			cube2_on_button = true
			break
	
	# Обновляем индикаторы
	left_indicator.text = "✔" if cube1_on_button else "X"
	right_indicator.text = "✔" if cube2_on_button else "X"

# Обработчики входа/выхода для кнопки 1
func _on_button1_body_entered(_body):
	_update_cube_states()

func _on_button1_body_exited(_body):
	_update_cube_states()

# Обработчики входа/выхода для кнопки 2
func _on_button2_body_entered(_body):
	_update_cube_states()

func _on_button2_body_exited(_body):
	_update_cube_states()

# Запуск обучения (один раз)
func _trigger_training():
	training_triggered = true
	
	# Ваша цепочка обучения
	MonologueSystem.play_monologue("puzzle_room_well_done_1")
	await MonologueSystem.monologue_finished
	VisualisationDirector.show_slide("buttons")
	await MonologueSystem.play_and_wait_monologues(["puzzle_room_well_done_2", "puzzle_room_well_done_3", "puzzle_room_well_done_4"])
	
	# Отключаем преграду, если она есть (путь может отличаться)
	$"../StaticBody3D/playa_stoppa".disabled = true
