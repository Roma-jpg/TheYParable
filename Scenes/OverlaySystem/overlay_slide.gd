extends CanvasLayer

@onready var dismiss_button = $BGDimmer/DismissButton

signal slide_closed

var closable: bool = true
var allow_next: bool = false
var is_closing: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Ensure high layer so new overlays appear on top
	layer = 1000
	
	# Set all CanvasItem children to transparent initially
	for child in get_children():
		if child is CanvasItem:
			child.modulate.a = 0.0
	
	# Fade in all children in parallel
	_fade_children(1.0, 0.3)
	
	if dismiss_button:
		dismiss_button.pressed.connect(close_slide)

func configure_slide(is_closable: bool, can_go_next: bool) -> void:
	closable = is_closable
	allow_next = can_go_next
	
	if dismiss_button:
		dismiss_button.visible = closable

func close_slide() -> void:
	if is_closing:
		return
	is_closing = true
	
	slide_closed.emit()
	
	# Fade out all children and free when done
	_fade_children(0.0, 0.3).finished.connect(queue_free)

func _fade_children(target_alpha: float, duration: float) -> Tween:
	var tween = create_tween()
	tween.set_parallel(true)
	for child in get_children():
		if child is CanvasItem:
			tween.tween_property(child, "modulate:a", target_alpha, duration)
	return tween

func _input(event: InputEvent) -> void:
	if is_closing:
		return
	
	if event.is_action_pressed("ui_cancel"):
		if closable:
			close_slide()
			get_viewport().set_input_as_handled()
	
	if event.is_action_pressed("ui_accept"):
		if allow_next:
			close_slide()
			get_viewport().set_input_as_handled()
