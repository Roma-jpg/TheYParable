extends Node

# Наследуем от основной системы
var MonologueSystem = preload("res://Scripts/MonologueSystem.gd")
var system: MonologueSystem

func _ready():
	system = MonologueSystem.new()
	add_child(system)
	load_monologues_from_json("res://data/monologues.json")
	
	# Подключаем сигналы для отладки
	system.monologue_started.connect(_on_monologue_started)
	system.monologue_finished.connect(_on_monologue_finished)
	system.subtitle_changed.connect(_on_subtitle_changed)

func load_monologues_from_json(path: String):
	"""Загрузка монологов из JSON файла"""
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var error = json.parse(file.get_as_text())
		if error == OK:
			var data = json.data
			if data.has("monologues"):
				for key in data["monologues"]:
					system.add_monologue(key, data["monologues"][key])
				print("Загружено монологов: ", system.monologues.size())
				system.print_all_monologues() # Показать все загруженные монологи
		else:
			push_error("Ошибка парсинга JSON: ", json.get_error_message())
	else:
		push_error("Не удалось открыть файл: ", path)
		# Создаем дефолтный файл если не существует
		create_default_json(path)

func create_default_json(path: String):
	"""Создание дефолтного JSON файла если он не существует"""
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	var default_data = {
		"monologues": {
			"example_1": "Это пример монолога без аудио файла.",
			"example_2": "Второй пример с более длинным текстом для тестирования длительности субтитров."
		}
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(default_data, "\t"))
		print("Создан дефолтный JSON файл: ", path)
		load_monologues_from_json(path) # Перезагружаем данные
	else:
		push_error("Не удалось создать дефолтный JSON файл: ", path)

# Прокси-методы для удобства
func play_monologue(key: String):
	return system.play_monlogue(key)

func play_sequence(keys: Array):
	system.play_sequence(keys)

# Сигналы для отладки
func _on_monologue_started(key: String):
	print("Монолог начался: ", key)

func _on_monologue_finished(key: String):
	print("Монолог завершился: ", key)

func _on_subtitle_changed(text: String):
	if text != "":
		print("Субтитры: ", text)
	else:
		print("Субтитры скрыты")
