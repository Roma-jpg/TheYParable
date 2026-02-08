extends Node2D


# Called when the node enters the scene tree for the first time.

func _ready():
	if get_tree().current_scene:
		print_scene_tree(get_tree().current_scene)

func print_scene_tree(node: Node, prefix := "", is_last := true):
	var connector = "└── " if is_last else "├── "
	
	# Формируем строку узла
	var line = prefix + connector + node.name
	
	# Label - выводим его текст
	if node is Label:
		line += " (\"" + str(node.text) + "\")"
	
	# OptionButton - выводим все элементы в одной строке
	if node is OptionButton:
		var items := []
		for i in range(node.get_item_count()):
			items.append(node.get_item_text(i)) # get_item_text возвращает текст пункта списка OptionButton:contentReference[oaicite:1]{index=1}
		line += " [" + ", ".join(items) + "]"
	
	print(line)
	
	# Обработка детей
	var children = node.get_children()
	for i in range(children.size()):
		var child = children[i]
		var last = (i == children.size() - 1)
		var new_prefix = prefix + ("    " if is_last else "│   ")
		print_scene_tree(child, new_prefix, last)
