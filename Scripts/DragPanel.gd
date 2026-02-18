extends Panel

@export var drag_type: String = ""
@export var icon: Texture2D = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP

func _get_drag_data(at_position: Vector2):
	# Превью перетаскивания
	var preview = TextureRect.new()
	preview.texture = icon
	preview.custom_minimum_size = Vector2(64, 64)  # Задаём размер превью
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	# Сообщаем сцене, что начался драг
	var root = get_tree().current_scene
	if root and root.has_method("start_dragging"):
		root.start_dragging(drag_type)

	return drag_type
