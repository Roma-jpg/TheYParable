extends CanvasLayer

@onready var subtitle_panel = $Control/Panel
@onready var subtitle_label = $Control/Panel/CenterContainer/Label

var max_width: float = 800.0
var min_width: float = 300.0
var padding: Vector2 = Vector2(40, 20)

func _ready() -> void:
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
		$Control/Panel/CenterContainer.get_theme_constant("margin_left") + $Control/Panel/CenterContainer.get_theme_constant("margin_right"),
		$Control/Panel/CenterContainer.get_theme_constant("margin_top") + $Control/Panel/CenterContainer.get_theme_constant("margin_bottom")
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
