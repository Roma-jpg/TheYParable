extends Node

# Dictionary to store overlay scenes
var slide_library: Dictionary = {}

# Current slide instance
var current_slide: Node = null

# Sequence state
var current_sequence: Array[String] = []
var sequence_index: int = -1

# Signal for errors (replaces push_error)
signal error_occurred(message: String)
signal slides_finished

func _ready() -> void:
	register_slide("materials", preload("res://Scenes/Overlays/how_materials_work.tscn"))
	register_slide("buttons", preload("res://Scenes/Overlays/button_work.tscn"))

# Inside your Slide/Overlay script
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_slide_closed()
		get_viewport().set_input_as_handled() # This tells Godot "I'm done with this event!"

func register_slide(slide_name: String, slide_scene: PackedScene) -> void:
	slide_library[slide_name] = slide_scene

# Public API – accepts either a single slide name (String) or a sequence (Array[String])
func show_slide(slide_identifier) -> void:
	if current_slide != null:
		error_occurred.emit("Cannot show new slide: a slide or sequence is already active.")
		return
	
	var sequence: Array[String] = []
	if slide_identifier is String:
		sequence = [slide_identifier]
	elif slide_identifier is Array:
		sequence = slide_identifier
	else:
		error_occurred.emit("Invalid slide identifier: must be String or Array[String].")
		return
	
	if sequence.is_empty():
		return
	
	current_sequence = sequence
	sequence_index = 0
	get_tree().paused = true
	
	_display_slide(current_sequence[0])

func _display_slide(slide_name: String) -> void:
	if not slide_library.has(slide_name):
		error_occurred.emit("Slide not found: " + slide_name)
		_cleanup_sequence()
		return
	
	var slide_scene: PackedScene = slide_library[slide_name]
	var slide_instance = slide_scene.instantiate()
	
	var is_last: bool = (sequence_index == current_sequence.size() - 1)
	
	# Only 2 arguments now
	slide_instance.configure_slide(
		is_last,     # closable – true only on last/single slide
		not is_last  # allow_next – true only on non-last slides
	)
	
	get_tree().root.add_child(slide_instance)
	current_slide = slide_instance
	
	slide_instance.slide_closed.connect(_on_slide_closed)

func _on_slide_closed() -> void:
	if current_slide:
		current_slide = null  # Fade-out and queue_free handled in overlay_slide.gd
	
	if sequence_index >= 0:
		_advance_sequence()
	else:
		get_tree().paused = false

func _advance_sequence() -> void:
	sequence_index += 1
	if sequence_index < current_sequence.size():
		_display_slide(current_sequence[sequence_index])
	else:
		_cleanup_sequence()

func _cleanup_sequence() -> void:
	sequence_index = -1
	current_sequence.clear()
	get_tree().paused = false

	slides_finished.emit()

func is_showing() -> bool:
	return current_slide != null
