extends CanvasLayer

@onready var subtitle_panel = $Control/Panel
@onready var margin_container = $Control/Panel/CenterContainer
@onready var subtitle_label = $Control/Panel/CenterContainer/Label

# Настройки субтитров
var max_width: float = 600.0
var min_width: float = 200.0
var padding: Vector2 = Vector2(20, 10)  # Дополнительные отступы

func _ready():
	# Подключаемся к системе монологов
	MonologueSystem.subtitle_changed.connect(_on_subtitle_changed)
	hide_subtitle()
	
	# Настраиваем начальный размер
	subtitle_panel.custom_minimum_size = Vector2(min_width, 50)

func _on_subtitle_changed(text: String):
	if text == "" or text == null:
		hide_subtitle()
	else:
		show_subtitle(text)

func show_subtitle(text: String):
	subtitle_label.text = text
	subtitle_panel.show()
	
	# Ждем обновления размера
	await get_tree().process_frame
	await get_tree().process_frame  # Двойное ожидание для гарантии
	
	# Автоматически подгоняем размер панели
	adjust_panel_size()
	
	# Центрируем панель
	center_panel()
	
	# Анимация появления
	var tween = create_tween()
	tween.tween_property(subtitle_panel, "modulate", Color.WHITE, 0.3).from(Color.TRANSPARENT)

func adjust_panel_size():
	"""Автоматически подгоняет размер панели под текст"""
	
	# Получаем размер текста в Label
	var font = subtitle_label.get_theme_font("font")
	var font_size = subtitle_label.get_theme_font_size("font_size")
	var text_width = font.get_string_size(subtitle_label.text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size).x
	var text_height = font.get_string_size(subtitle_label.text, HORIZONTAL_ALIGNMENT_CENTER, max_width, font_size).y
	
	# Добавляем отступы MarginContainer
	var margin_left = margin_container.get_theme_constant("margin_left")
	var margin_right = margin_container.get_theme_constant("margin_right")
	var margin_top = margin_container.get_theme_constant("margin_top")
	var margin_bottom = margin_container.get_theme_constant("margin_bottom")
	
	# Рассчитываем конечный размер
	var final_width = clamp(
		text_width + margin_left + margin_right + padding.x * 2,
		min_width,
		max_width
	)
	
	var final_height = text_height + margin_top + margin_bottom + padding.y * 2
	
	# Устанавливаем размер панели
	subtitle_panel.custom_minimum_size = Vector2(final_width, final_height)
	
	# Также устанавливаем текущий размер
	subtitle_panel.size = Vector2(final_width, final_height)

func center_panel():
	"""Центрирует панель внизу экрана"""
	var viewport_size = get_viewport().get_visible_rect().size
	var panel_size = subtitle_panel.size
	
	# Позиция внизу с отступом
	var pos_x = (viewport_size.x - panel_size.x) / 2
	var pos_y = viewport_size.y - panel_size.y - 20  # 20px от низа
	
	subtitle_panel.position = Vector2(pos_x, pos_y)

func hide_subtitle():
	# Анимация исчезновения
	var tween = create_tween()
	tween.tween_property(subtitle_panel, "modulate", Color.TRANSPARENT, 0.3)
	await tween.finished
	subtitle_panel.hide()
	subtitle_label.text = ""
