extends Node

# Наследуем от основной системы
var MonologueSystem = preload("res://Scripts/MonologueSystem.gd")
var system: MonologueSystem

func _ready():
	system = MonologueSystem.new()
	add_child(system)
	load_monologues_from_json("res://data/monologues.json")

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
		else:
			push_error("Ошибка парсинга JSON: ", json.get_error_message())
	else:
		push_error("Не удалось открыть файл: ", path)

# Прокси-методы для удобства
func play_monologue(key: String):
	return system.play_monologue(key)

func play_sequence(keys: Array):
	system.play_sequence(keys)
