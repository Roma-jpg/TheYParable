extends Control

@export var typing_speed: float = 0.05
@export var command_prefix: String = "> "
@export var enter_delay: float = 0.5
@export var fade_duration: float = 0.3

@onready var output: RichTextLabel = $ColorRect/HBoxContainer2/ColorRect/ScrollContainer/MarginContainer/OutputLabel
@onready var prefix_label: Label = $ColorRect/HBoxContainer2/HBoxContainer/PrefixLabel
@onready var current_line: RichTextLabel = $ColorRect/HBoxContainer2/HBoxContainer/CommandLabel
@onready var type_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_typing: bool = false

signal typing_completed

func _ready() -> void:
	output.text = ""
	current_line.text = ""
	prefix_label.text = command_prefix
	output.scroll_following = true

func type_message(text: String, use_prefix: bool = true, custom_speed: float = -1, instant: bool = false) -> void:
	if is_typing:
		await typing_completed
	
	is_typing = true
	
	var speed: float = custom_speed if custom_speed > 0 else typing_speed
	
	if instant:
		var prefix: String = command_prefix if use_prefix else ""
		output.text += prefix + text + "\n"
		output.scroll_to_line(output.get_line_count() - 1)
		is_typing = false
		typing_completed.emit()
		return
	
	# Setup prefix visibility/text for typing
	prefix_label.visible = use_prefix
	if use_prefix:
		prefix_label.text = command_prefix
	current_line.text = text
	current_line.visible_characters = 0
	
	await get_tree().create_timer(0.7).timeout
	
	for i in text.length():
		current_line.visible_characters = i + 1
		if type_sound.stream:
			type_sound.play()
		await get_tree().create_timer(speed).timeout
	
	await get_tree().create_timer(enter_delay).timeout
	
	var prefix: String = command_prefix if use_prefix else ""
	output.text += prefix + text + "\n"
	await get_tree().process_frame
	output.scroll_to_line(output.get_line_count() - 1)
	
	current_line.text = ""
	current_line.visible_characters = 0
	prefix_label.text = command_prefix  # Reset for next command
	
	is_typing = false
	typing_completed.emit()

func print_instant(text: String) -> void:
	output.text += text + "\n"
	output.scroll_to_line(output.get_line_count() - 1)

func play_command(command: String, output_text: String = "", output_color: String = "white") -> void:
	await type_message(command, true)
	if output_text != "":
		await type_message("[color=" + output_color + "]" + output_text + "[/color]", false)

func open_console() -> void:
	visible = true
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	await tween.finished

func close() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	await tween.finished
	visible = false
