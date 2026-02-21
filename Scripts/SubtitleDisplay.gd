extends CanvasLayer

@onready var subtitle_panel = $Control/Panel
@onready var subtitle_label = $Control/Panel/MarginContainer/Label

var max_width: float = 800.0
var min_width: float = 300.0
var padding: Vector2 = Vector2(40, 20)

func _ready() -> void:
	debug_print_scene_tree()
	MonologueSystem.subtitle_changed.connect(_on_subtitle_changed)
	hide_subtitle()
	subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _on_subtitle_changed(text: String) -> void:
	if text == "":
		hide_subtitle()
	else:
		show_subtitle(text)

func show_subtitle(text: String) -> void:
	subtitle_label.text = text
	await get_tree().process_frame
	await get_tree().process_frame
	
	adjust_panel_size()
	center_panel()
	
	subtitle_panel.modulate.a = 0.0
	subtitle_panel.show()
	var tween = create_tween()
	tween.tween_property(subtitle_panel, "modulate:a", 1.0, 0.3)

func adjust_panel_size() -> void:
	var label_size = subtitle_label.get_minimum_size()
	var margins = Vector2(
		$Control/Panel/MarginContainer.get_theme_constant("margin_left") + $Control/Panel/MarginContainer.get_theme_constant("margin_right"),
		$Control/Panel/MarginContainer.get_theme_constant("margin_top") + $Control/Panel/MarginContainer.get_theme_constant("margin_bottom")
	)
	var final_width = clamp(label_size.x + margins.x + padding.x * 2, min_width, max_width)
	var final_height = label_size.y + margins.y + padding.y * 2
	subtitle_panel.custom_minimum_size = Vector2(final_width, final_height)

func center_panel() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = subtitle_panel.size
	subtitle_panel.position = Vector2(
		(viewport_size.x - panel_size.x) / 2,
		viewport_size.y - panel_size.y - 50
	)

func hide_subtitle() -> void:
	var tween = create_tween()
	tween.tween_property(subtitle_panel, "modulate:a", 0.0, 0.3)
	await tween.finished
	subtitle_panel.hide()
	subtitle_label.text = ""

func debug_print_scene_tree():
	print("\n" + "=".repeat(60))
	print("DEBUG: SCENE TREE HIERARCHY")
	print("=".repeat(60))
	_debug_print_node_recursive(get_tree().current_scene, 0)
	print("=".repeat(60) + "\n")

func _debug_print_node_recursive(node: Node, current_depth: int, indent: String = ""):
	# No max_depth check
	var node_prefix = "├── "
	if node.get_child_count() == 0:
		node_prefix = "└── "
	
	var visible_str = ""
	if node is CanvasItem:
		visible_str = " [Visible: %s]" % node.visible
		if node.has_method("get_modulate"):
			visible_str += " [Alpha: %.2f]" % node.modulate.a
	
	var node_info = "%s%s%s (%s)%s" % [indent, node_prefix, node.name, node.get_class(), visible_str]
	print(node_info)
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		var is_last = (i == node.get_child_count() - 1)
		var new_indent = indent + ("	" if is_last else "│	 ")
		_debug_print_node_recursive(child, current_depth + 1, new_indent)
