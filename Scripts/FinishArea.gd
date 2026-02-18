extends Area3D

func _ready():
	# Подключаем сигнал входа
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Проверяем, что вошедший объект — игрок (по группе)
	if body.is_in_group("player"):
		# Находим редактор (текущую сцену) и вызываем on_win
		var editor = get_tree().current_scene
		if editor and editor.has_method("on_win"):
			editor.on_win()
