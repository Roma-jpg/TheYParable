extends Control

@export var typing_speed: float = 0.05     # Seconds per character (can be overridden per call)
@export var command_prefix: String = "> "   # Shown before commands
@export var enter_delay: float = 0.5        # Small pause after typing before "enter"

@onready var output: RichTextLabel = $ColorRect/HBoxContainer2/ColorRect/ScrollContainer/MarginContainer/OutputLabel
@onready var prefix_label: Label = $ColorRect/HBoxContainer2/HBoxContainer/PrefixLabel
@onready var current_line: RichTextLabel = $ColorRect/HBoxContainer2/HBoxContainer/CommandLabel
@onready var type_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

@onready var tween = get_tree().create_tween()

var start_pos: Vector2

@export var pop_distance: float = 30.0
@export var pop_duration: float = 0.25
@export var fade_duration: float = 0.2


var is_typing: bool = false


func _ready() -> void:
	start_pos = position
	output.text = ""
	current_line.text = ""
	output.scroll_following = true  # Auto-scrolls to bottom


## Types a single message with character-by-character animation
## use_prefix = true → shows command_prefix before the text
## Supports basic BBCode
func type_message(text: String, use_prefix: bool = true, custom_speed: float = -1) -> void:
	if is_typing:
		await typing_completed

	is_typing = true

	var speed = custom_speed if custom_speed > 0 else typing_speed
	var prefix = command_prefix if use_prefix else ""

	current_line.text = text
	current_line.visible_characters = 0

	await get_tree().create_timer(0.7).timeout

	for i in text.length():
		current_line.visible_characters = i + 1

		if type_sound.stream:
			type_sound.play()

		await get_tree().create_timer(speed).timeout

	await get_tree().create_timer(enter_delay).timeout

	var line = prefix + text
	output.text += line + "\n"
	await get_tree().process_frame
	output.scroll_to_line(output.get_line_count() - 1)

	current_line.text = ""
	current_line.visible_characters = 0

	is_typing = false
	typing_completed.emit()



## Instantly prints text to output (no animation, no prefix, no sound)
## Supports BBCode. Great for logs, errors, or bulk output.
func print_instant(text: String) -> void:
	output.text += text + "\n"
	# scroll_following handles auto-scroll


## Convenience function: command + optional output (Minecraft style)
## Example: await play_command("/gamemode survival", "You are now in Survival Mode")
func play_command(command: String, output_text: String = "", output_color: String = "white") -> void:
	await type_message(command, true)

	if output_text != "":
		await type_message("[color=" + output_color + "]" + output_text + "[/color]", false)


func open_console() -> void:
	visible = true
	modulate.a = 0
	position = start_pos + Vector2(0, pop_distance)

	if tween:
		tween.kill()

	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	tween.tween_property(self, "position:y", start_pos.y, pop_duration)

	await tween.finished

func close() -> void:
	if tween:
		tween.kill()

	tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_duration)
	tween.tween_property(self, "position:y", start_pos.y + pop_distance, pop_duration)

	await tween.finished
	visible = false


func _on_close_complete() -> void:
	visible = false


signal typing_completed
