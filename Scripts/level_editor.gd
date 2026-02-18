extends Node3D

# Экспортируемые сцены — укажите свои пути!
@export var wall_scene: PackedScene
@export var ramp_scene: PackedScene
@export var trampoline_scene: PackedScene
@export var finish_scene: PackedScene
@export var spawn_scene: PackedScene

@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var grid_visual: Node3D = $GridVisual
@onready var placed_objects: Node3D = $PlacedObjects
@onready var grid_plane: StaticBody3D = $GridPlane

# Переменные для управления камерой
var camera_dragging: bool = false
var mouse_sensitivity: float = 0.002
var camera_speed: float = 10.0

var grid: Array = []          # 3D-массив: для каждой ячейки список типов объектов по высоте
var spawn_cell: Vector2i = Vector2i(-1, -1)   # ячейка спавна (только уровень 0)
var finish_data = {           # данные финиша: ячейка и уровень
	"cell": Vector2i(-1, -1),
	"level": -1
}
var spawn_marker: Node3D
var finish_object: Node3D
var dragging_type: String = ""
var preview_drag: Control = null

var canvas_layer: CanvasLayer
var palette_panel: PanelContainer

var player_scene: PackedScene = preload("res://Scenes/player.tscn")
var player_instance: CharacterBody3D

# Параметры сетки
const CELL_SIZE = 3.0
const GRID_SIZE_X = 10
const GRID_SIZE_Z = 15
const MAX_HEIGHT_LEVELS = 10

# Смещение сетки так, чтобы она была центрирована
var grid_offset: Vector3

func _ready():
	add_to_group("editors")
	calculate_grid_offset()
	init_grid()
	create_grid_visual()
	create_ui()
	update_special_visuals()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func calculate_grid_offset():
	grid_offset = Vector3(
		-(GRID_SIZE_X - 1) * CELL_SIZE / 2.0,
		0,
		-(GRID_SIZE_Z - 1) * CELL_SIZE / 2.0
	)

func _input(event):
	if player_instance != null:
		if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
			print("Выход из режима игры")
			_return_to_editor()
			return
	if dragging_type != "":
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			var mouse_pos = get_viewport().get_mouse_position()
			var ray_from = camera.project_ray_origin(mouse_pos)
			var ray_to = ray_from + camera.project_ray_normal(mouse_pos) * 1000.0
			var space_state = get_world_3d().direct_space_state
			var query = PhysicsRayQueryParameters3D.create(ray_from, ray_to)
			query.collision_mask = 1
			query.collide_with_areas = false
			query.collide_with_bodies = true
			var result = space_state.intersect_ray(query)
			
			if result and result.collider == grid_plane:
				var hit_pos = result.position
				var cell = snap_to_grid(hit_pos)
				place_item(cell, dragging_type)
			else:
				print("Размещение отменено: либо нет коллизии, либо collider не GridPlane")
			
			dragging_type = ""
			if preview_drag:
				preview_drag.queue_free()
				preview_drag = null

	if player_instance == null:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed and dragging_type == "":
				camera_dragging = true
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			elif not event.pressed:
				camera_dragging = false
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		if event is InputEventMouseMotion and camera_dragging:
			camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
			camera.rotate_x(-event.relative.y * mouse_sensitivity)
			camera.rotation.x = clamp(camera.rotation.x, -PI/2, PI/2)

	if event is InputEventKey and event.keycode == KEY_ENTER and event.pressed and not event.echo:
		if player_instance == null:
			start_play()

func _process(delta):
	if camera_dragging and player_instance == null:
		var move_dir = Vector3()
		var cam_basis = camera_pivot.global_transform.basis
		if Input.is_key_pressed(KEY_W):
			move_dir -= cam_basis.z
		if Input.is_key_pressed(KEY_S):
			move_dir += cam_basis.z
		if Input.is_key_pressed(KEY_A):
			move_dir -= cam_basis.x
		if Input.is_key_pressed(KEY_D):
			move_dir += cam_basis.x
		if Input.is_key_pressed(KEY_Q):
			move_dir -= Vector3.UP
		if Input.is_key_pressed(KEY_E):
			move_dir += Vector3.UP

		if move_dir.length() > 0:
			move_dir = move_dir.normalized() * camera_speed * delta
			camera_pivot.global_position += move_dir

func init_grid():
	grid.resize(GRID_SIZE_Z)
	for z in range(GRID_SIZE_Z):
		grid[z] = []
		grid[z].resize(GRID_SIZE_X)
		for x in range(GRID_SIZE_X):
			grid[z][x] = []

func create_grid_visual():
	for child in grid_visual.get_children():
		child.queue_free()

	for z in range(GRID_SIZE_Z):
		for x in range(GRID_SIZE_X):
			var floor_mesh = MeshInstance3D.new()
			floor_mesh.mesh = BoxMesh.new()
			floor_mesh.mesh.size = Vector3(CELL_SIZE, 0.15, CELL_SIZE)
			floor_mesh.position = grid_pos(Vector2i(x, z), 0) + Vector3(0, -0.075, 0)
			var mat = StandardMaterial3D.new()
			mat.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
			floor_mesh.material_override = mat
			grid_visual.add_child(floor_mesh)

	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color.WHITE
	line_mat.vertex_color_use_as_albedo = true

	for i in range(GRID_SIZE_X + 1):
		var x_pos = grid_offset.x + i * CELL_SIZE
		var line = MeshInstance3D.new()
		line.mesh = create_line_mesh(Vector3(x_pos, 0.02, grid_offset.z), Vector3(x_pos, 0.02, grid_offset.z + GRID_SIZE_Z * CELL_SIZE))
		line.material_override = line_mat
		grid_visual.add_child(line)

	for i in range(GRID_SIZE_Z + 1):
		var z_pos = grid_offset.z + i * CELL_SIZE
		var line = MeshInstance3D.new()
		line.mesh = create_line_mesh(Vector3(grid_offset.x, 0.02, z_pos), Vector3(grid_offset.x + GRID_SIZE_X * CELL_SIZE, 0.02, z_pos))
		line.material_override = line_mat
		grid_visual.add_child(line)

func create_line_mesh(from: Vector3, to: Vector3) -> Mesh:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(from)
	mesh.surface_add_vertex(to)
	mesh.surface_end()
	return mesh

func grid_pos(cell: Vector2i, level: int) -> Vector3:
	return Vector3(
		grid_offset.x + cell.x * CELL_SIZE + CELL_SIZE/2,
		level * CELL_SIZE,
		grid_offset.z + cell.y * CELL_SIZE + CELL_SIZE/2
	)

func snap_to_grid(pos: Vector3) -> Vector2i:
	var local = pos - grid_offset
	var x = int(floor(local.x / CELL_SIZE))
	var z = int(floor(local.z / CELL_SIZE))
	x = clamp(x, 0, GRID_SIZE_X - 1)
	z = clamp(z, 0, GRID_SIZE_Z - 1)
	return Vector2i(x, z)

func get_cell_center(cell: Vector2i) -> Vector3:
	return grid_pos(cell, 0)

# Проверка, занята ли ячейка спавном (только уровень 0)
func is_cell_occupied_by_spawn(cell: Vector2i) -> bool:
	return cell == spawn_cell

# Проверка, занят ли конкретный уровень в ячейке финишем
func is_level_occupied_by_finish(cell: Vector2i, level: int) -> bool:
	return finish_data.cell == cell and finish_data.level == level

func place_item(cell: Vector2i, item_type: String):
	print("place_item: ", item_type, " в ячейке ", cell)
	
	# Ластик
	if item_type == "erase":
		# Проверяем, не спавн ли это на уровне 0
		if cell == spawn_cell:
			if spawn_marker:
				spawn_marker.queue_free()
				spawn_marker = null
			spawn_cell = Vector2i(-1, -1)
			print("Спавн удалён")
			return
		
		# Проверяем, не финиш ли это на каком-либо уровне
		# Для этого надо знать уровень, на котором стоит финиш. Но при стирании мы не знаем уровень, просто ячейку.
		# Решение: удаляем финиш, если он есть в этой ячейке (независимо от уровня), потому что финиш может быть только один.
		if finish_data.cell == cell:
			if finish_object:
				finish_object.queue_free()
				finish_object = null
			finish_data.cell = Vector2i(-1, -1)
			finish_data.level = -1
			print("Финиш удалён")
			return
		
		# Иначе удаляем верхний обычный объект в ячейке
		if grid[cell.y][cell.x].size() > 0:
			remove_top_object(cell)
		else:
			print("Нечего стирать в ячейке ", cell)
		return

	# Установка спавна (только уровень 0)
	if item_type == "spawn":
		# Проверяем, не занята ли ячейка блоками на уровне 0 (в grid на уровне 0 есть объект?)
		if grid[cell.y][cell.x].size() > 0 and grid[cell.y][cell.x][0] != "":
			print("Нельзя поставить спавн: ячейка занята блоком на уровне 0")
			return
		# Проверяем, не занята ли ячейка другим спецобъектом на уровне 0
		if is_cell_occupied_by_spawn(cell) or (finish_data.cell == cell and finish_data.level == 0):
			print("Нельзя поставить спавн: ячейка уже занята спавном или финишем на уровне 0")
			return
		
		# Удаляем старый спавн
		if spawn_cell != Vector2i(-1, -1):
			if spawn_marker:
				spawn_marker.queue_free()
				spawn_marker = null
		
		spawn_cell = cell
		update_special_visuals()
		print("Спавн установлен на ", cell, " уровень 0")
		return

	# Установка финиша (можно на любой уровень)
	if item_type == "finish":
		# Определяем уровень, на который поставим финиш:
		# Если в ячейке уже есть блоки, ставим на следующий свободный уровень (текущая высота)
		# Если ячейка пуста, ставим на уровень 0.
		var current_height = grid[cell.y][cell.x].size()
		var target_level = current_height  # следующий свободный уровень
		
		# Проверяем, не занят ли целевой уровень финишем (если финиш уже есть в этой ячейке на другом уровне, можно переместить)
		# Но финиш может быть только один, поэтому если в этой ячейке уже есть финиш на другом уровне, мы его переместим.
		# Если финиш уже есть в другой ячейке, мы его удалим оттуда и поставим сюда.
		
		# Удаляем старый финиш, если он есть
		if finish_data.cell != Vector2i(-1, -1):
			if finish_object:
				finish_object.queue_free()
				finish_object = null
		
		finish_data.cell = cell
		finish_data.level = target_level
		update_special_visuals()
		print("Финиш установлен на ", cell, " уровень ", target_level)
		return

	# Для обычных объектов (стена, рампа, батут)
	# Проверяем, не занят ли уровень 0 спавном (если ставим на уровень 0)
	var target_level = grid[cell.y][cell.x].size()  # следующий свободный уровень
	if target_level == 0 and is_cell_occupied_by_spawn(cell):
		print("Нельзя разместить объект на уровне 0: ячейка занята спавном")
		return
	# Проверяем, не занят ли целевой уровень финишем
	if is_level_occupied_by_finish(cell, target_level):
		print("Нельзя разместить объект на уровне ", target_level, ": ячейка занята финишем")
		return
	
	if target_level >= MAX_HEIGHT_LEVELS:
		print("Нельзя разместить больше объектов в ячейке ", cell, ", лимит высоты")
		return

	var obj = create_object(item_type)
	if obj:
		obj.position = grid_pos(cell, target_level)
		placed_objects.add_child(obj)
		grid[cell.y][cell.x].append(item_type)
		print("Размещён объект ", item_type, " на уровне ", target_level)
	else:
		print("Ошибка: не удалось создать объект типа ", item_type)

func remove_top_object(cell: Vector2i):
	var list = grid[cell.y][cell.x]
	if list.size() == 0:
		return
	var old_size = list.size()
	list.pop_back()
	var pos_to_remove = grid_pos(cell, old_size - 1)
	for child in placed_objects.get_children():
		if child.position.is_equal_approx(pos_to_remove):
			child.queue_free()
			break

func create_object(item_type: String) -> Node3D:
	var obj: Node3D
	match item_type:
		"wall":
			obj = wall_scene.instantiate() if wall_scene else null
		"ramp":
			obj = ramp_scene.instantiate() if ramp_scene else null
		"trampoline":
			obj = trampoline_scene.instantiate() if trampoline_scene else null
		_:
			return null

	if obj:
		_set_object_physics_enabled(obj, false)
	return obj

func update_special_visuals():
	# Спавн маркер (всегда на уровне 0)
	if spawn_marker:
		spawn_marker.queue_free()
		spawn_marker = null
	if spawn_scene and spawn_cell != Vector2i(-1, -1):
		spawn_marker = spawn_scene.instantiate()
		spawn_marker.position = grid_pos(spawn_cell, 0)
		placed_objects.add_child(spawn_marker)

	# Финиш
	if finish_object:
		finish_object.queue_free()
		finish_object = null
	if finish_scene and finish_data.cell != Vector2i(-1, -1):
		finish_object = finish_scene.instantiate()
		finish_object.position = grid_pos(finish_data.cell, finish_data.level)
		placed_objects.add_child(finish_object)
		if finish_object.has_method("set_editor"):
			finish_object.set_editor(self)

func create_ui():
	canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)

	palette_panel = PanelContainer.new()
	palette_panel.anchor_left = 0.8
	palette_panel.anchor_right = 1.0
	palette_panel.anchor_top = 0.0
	palette_panel.anchor_bottom = 1.0

	var scroll = ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	palette_panel.add_child(scroll)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 12)
	scroll.add_child(vbox)

	canvas_layer.add_child(palette_panel)

	vbox.add_child(create_drag_panel("res://Assets/EditorIcons/wall_icon.png", "wall"))
	vbox.add_child(create_drag_panel("res://Assets/EditorIcons/ramp_icon.png", "ramp"))
	vbox.add_child(create_drag_panel("res://Assets/EditorIcons/trampoline_icon.png", "trampoline"))
	vbox.add_child(create_drag_panel("res://Assets/EditorIcons/erase_icon.png", "erase"))
	vbox.add_child(create_drag_panel("res://Assets/EditorIcons/spawn_icon.png", "spawn"))
	vbox.add_child(create_drag_panel("res://Assets/EditorIcons/finish_icon.png", "finish"))

	var play_btn = Button.new()
	play_btn.text = "▶ Play!"
	play_btn.custom_minimum_size = Vector2(0, 60)
	play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_btn.pressed.connect(Callable(self, "start_play"))
	vbox.add_child(play_btn)

	var clear_btn = Button.new()
	clear_btn.text = "Очистить всё"
	clear_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	clear_btn.pressed.connect(Callable(self, "clear_all"))
	vbox.add_child(clear_btn)

	var export_btn = Button.new()
	export_btn.text = "Экспорт"
	export_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	export_btn.pressed.connect(Callable(self, "_on_export_pressed"))
	vbox.add_child(export_btn)

	var import_btn = Button.new()
	import_btn.text = "Импорт"
	import_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_btn.pressed.connect(Callable(self, "_on_import_pressed"))
	vbox.add_child(import_btn)

	var title = Label.new()
	title.text = "Элементы уровня"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	vbox.add_child(title)

func create_drag_panel(icon_path: String, d_type: String) -> Panel:
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(80, 80)

	var tex = load(icon_path)
	var tex_rect = TextureRect.new()
	tex_rect.texture = tex
	tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex_rect.anchor_right = 1.0
	tex_rect.anchor_bottom = 1.0
	panel.add_child(tex_rect)

	var s = load("res://Scripts/DragPanel.gd")
	panel.set_script(s)
	panel.drag_type = d_type
	panel.icon = tex

	return panel

func start_dragging(d_type: String):
	dragging_type = d_type

func start_play():
	_start_playing()

func _start_playing():
	# Проверка наличия спавна
	if spawn_cell == Vector2i(-1, -1):
		print("Предупреждение: точка спавна не установлена, игрок появится в (0,0)")
		var start_pos = Vector3(0, CELL_SIZE, 0)
	else:
		var start_pos = grid_pos(spawn_cell, 0) + Vector3(0, CELL_SIZE, 0)
	
	if finish_data.cell == Vector2i(-1, -1):
		print("Предупреждение: финиш не установлен, уровень невозможно завершить")

	set_process(false)
	set_process_input(false)

	if canvas_layer:
		canvas_layer.visible = false

	camera.current = false

	for obj in placed_objects.get_children():
		_set_object_physics_enabled(obj, true)

	player_instance = player_scene.instantiate()
	if spawn_cell == Vector2i(-1, -1):
		player_instance.position = Vector3(0, CELL_SIZE, 0)
	else:
		player_instance.position = grid_pos(spawn_cell, 0) + Vector3(0, CELL_SIZE, 0)
	add_child(player_instance)
	player_instance.add_to_group("player")

	var player_cam = player_instance.find_child("Camera3D", true, false)
	if player_cam:
		player_cam.current = true

func _set_object_physics_enabled(obj: Node3D, enabled: bool):
	if obj is StaticBody3D or obj is Area3D:
		obj.collision_layer = 1 if enabled else 0
		obj.collision_mask = 1 if enabled else 0
	for child in obj.get_children():
		if child is Node3D:
			_set_object_physics_enabled(child, enabled)

func on_win():
	print("Уровень пройден!")
	camera.current = true
	set_process(true)
	set_process_input(true)

	if player_instance:
		player_instance.queue_free()
		player_instance = null

	for obj in placed_objects.get_children():
		_set_object_physics_enabled(obj, false)

	if canvas_layer:
		canvas_layer.visible = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera_dragging = false

func clear_all():
	init_grid()
	for child in placed_objects.get_children():
		child.queue_free()
	spawn_cell = Vector2i(-1, -1)
	finish_data.cell = Vector2i(-1, -1)
	finish_data.level = -1
	print("Уровень полностью очищен")

# ========== ЭКСПОРТ ==========
func _on_export_pressed():
	var filters = PackedStringArray(["*.json ; JSON files"])
	DisplayServer.file_dialog_show(
		"Сохранить уровень",
		"",
		"level.json",
		false,
		DisplayServer.FILE_DIALOG_MODE_SAVE_FILE,
		filters,
		Callable(self, "_on_export_file_selected")
	)

func _on_export_file_selected(status: bool, selected_paths: PackedStringArray, _selected_filter: int = 0):
	if status and selected_paths.size() > 0:
		save_level_to_file(selected_paths[0])


func save_level_to_file(path: String):
	# Формируем данные для сохранения
	var data = {
		"spawn_cell": [spawn_cell.x, spawn_cell.y] if spawn_cell != Vector2i(-1, -1) else null,
		"finish_data": {
			"cell": [finish_data.cell.x, finish_data.cell.y] if finish_data.cell != Vector2i(-1, -1) else null,
			"level": finish_data.level
		},
		"grid": []
	}
	
	# Преобразуем трёхмерный массив grid в формат JSON
	for z in range(GRID_SIZE_Z):
		var row = []
		for x in range(GRID_SIZE_X):
			row.append(grid[z][x].duplicate())	# копируем список типов объектов в ячейке
		data.grid.append(row)
	
	# Запись в файл
	var json_string = JSON.stringify(data, "\t")	# с отступами для читаемости
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		print("Уровень сохранён в ", path)
	else:
		print("Ошибка сохранения файла")

# ========== ИМПОРТ ==========
func _on_import_pressed():
	var filters = PackedStringArray(["*.json ; JSON files"])
	DisplayServer.file_dialog_show(
		"Загрузить уровень",
		"",
		"",
		false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		filters,
		Callable(self, "_on_import_file_selected")
	)

func _on_import_file_selected(status: bool, selected_paths: PackedStringArray, _selected_filter: int = 0):
	if status and selected_paths.size() > 0:
		load_level_from_file(selected_paths[0])

func load_level_from_file(path: String):
	# Чтение файла
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("Ошибка открытия файла")
		return
	
	var json_string = file.get_as_text()
	var json = JSON.new()
	var error = json.parse(json_string)
	if error != OK:
		print("Ошибка парсинга JSON: ", json.get_error_message())
		return
	
	var data = json.data
	if not (data is Dictionary):
		print("Неверный формат данных: ожидается словарь")
		return
	
	if not data.has("grid"):
		print("В файле отсутствует поле grid")
		return
	
	# Очищаем текущий уровень
	clear_all()
	
	# Восстанавливаем spawn_cell
	if data.has("spawn_cell") and data.spawn_cell != null:
		var sc = data.spawn_cell
		if sc is Array and sc.size() == 2:
			spawn_cell = Vector2i(sc[0], sc[1])
		else:
			spawn_cell = Vector2i(-1, -1)
	else:
		spawn_cell = Vector2i(-1, -1)
	
	# Восстанавливаем finish_data
	if data.has("finish_data") and data.finish_data != null:
		var fd = data.finish_data
		if fd is Dictionary:
			if fd.has("cell") and fd.cell != null and fd.cell is Array and fd.cell.size() == 2:
				finish_data.cell = Vector2i(fd.cell[0], fd.cell[1])
			else:
				finish_data.cell = Vector2i(-1, -1)
			finish_data.level = fd.get("level", -1) if fd.has("level") else -1
		else:
			finish_data.cell = Vector2i(-1, -1)
			finish_data.level = -1
	else:
		finish_data.cell = Vector2i(-1, -1)
		finish_data.level = -1
	
	# Проверка размерности сетки
	if not (data.grid is Array and data.grid.size() == GRID_SIZE_Z):
		print("Ошибка: несоответствие размеров сетки (ожидалось ", GRID_SIZE_Z, " рядов)")
		clear_all()
		return
	
	# Восстанавливаем обычные объекты из grid
	for z in range(GRID_SIZE_Z):
		var row_data = data.grid[z]
		if not (row_data is Array and row_data.size() == GRID_SIZE_X):
			print("Ошибка: несоответствие размеров сетки по X в ряду ", z)
			clear_all()
			return
		
		for x in range(GRID_SIZE_X):
			var cell_data = row_data[x]
			if cell_data is Array:
				for level in range(cell_data.size()):
					var item_type = cell_data[level]
					if item_type is String:
						var obj = create_object(item_type)
						if obj:
							obj.position = grid_pos(Vector2i(x, z), level)
							placed_objects.add_child(obj)
							grid[z][x].append(item_type)
						else:
							print("Неизвестный тип объекта: ", item_type, " в [", z, ",", x, "] ур. ", level)
	
	# Обновляем визуальные маркеры спавна и финиша
	update_special_visuals()
	print("Уровень загружен из ", path)

func _return_to_editor():
	camera.current = true
	set_process(true)
	set_process_input(true)

	if player_instance:
		player_instance.queue_free()
		player_instance = null

	for obj in placed_objects.get_children():
		_set_object_physics_enabled(obj, false)

	if canvas_layer:
		canvas_layer.visible = true

	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera_dragging = false
