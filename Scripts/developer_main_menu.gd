extends Control

const SCENES_PATH := "res://Scenes/"

@onready var grid : GridContainer = $PanelContainer/MarginContainer/VBoxContainer/GridContainer

func _ready():
	#grid.clear()
	var dir = DirAccess.open(SCENES_PATH)
	if not dir:
		print("Не удалось открыть папку ", SCENES_PATH)
		return
	
	for file_name in dir.get_files():
		if file_name.ends_with(".tscn"):
			var scene_path = SCENES_PATH + file_name
			_create_scene_button(scene_path)

func _create_scene_button(scene_path: String) -> void:
	var scene_name = scene_path.get_file().get_basename()
	
	var btn = Button.new()
	btn.text = scene_name
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(Callable(self, "_on_scene_button_pressed").bind(scene_path))
	grid.add_child(btn)

func _on_scene_button_pressed(scene_path: String) -> void:
	var packed_scene := load(scene_path) as PackedScene
	if not packed_scene:
		print("Не удалось загрузить сцену: ", scene_path)
		return
	
	var new_scene := packed_scene.instantiate()
	get_tree().root.add_child(new_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = new_scene
