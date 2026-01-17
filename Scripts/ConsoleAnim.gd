extends Control

@export var typing_speed: float = 0.05     # Seconds per character (can be overridden per call)
@export var command_prefix: String = "> "   # Shown before commands
@export var enter_delay: float = 0.2        # Small pause after typing before "enter"

@onready var output: RichTextLabel = $ColorRect/HBoxContainer2/ColorRect/ScrollContainer/MarginContainer/OutputLabel
@onready var prefix_label: Label = $ColorRect/HBoxContainer2/HBoxContainer/PrefixLabel
@onready var current_line: RichTextLabel = $ColorRect/HBoxContainer2/HBoxContainer/CommandLabel
@onready var type_sound: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_typing: bool = false


func _ready() -> void:
	output.text = ""
	current_line.text = ""
	output.scroll_following = true  # Auto-scrolls to bottom


## Types a single message with character-by-character animation
## use_prefix = true → shows command_prefix before the text
## Supports basic BBCode
func type_message(text: String, use_prefix: bool = false, custom_speed: float = -1) -> void:
	if is_typing:
		await typing_completed  # Wait for previous animation to finish

	is_typing = true

	var speed = custom_speed if custom_speed > 0 else typing_speed
	var prefix = command_prefix if use_prefix else ""

	prefix_label.text = prefix
	current_line.text = ""  # Clear previous content

	var visible_chars: int = 0
	
	await get_tree().create_timer(0.7).timeout
	
	# Reveal character by character
	for c in text:
		visible_chars += 1
		current_line.visible_characters = visible_chars
		current_line.text = prefix + text   # full text, but only visible_chars shown

		if type_sound.stream:
			type_sound.play()

		await get_tree().create_timer(speed).timeout

	# Small pause to simulate "enter" key press
	await get_tree().create_timer(enter_delay).timeout

	# Move completed line to output/history
	var line = prefix + text
	output.text += line + "\n"
	await get_tree().process_frame
	output.scroll_to_line(output.get_line_count() - 1)

	# Clean up current input line
	current_line.text = ""

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


## Hides the entire console UI
func close() -> void:
	visible = false


signal typing_completed
