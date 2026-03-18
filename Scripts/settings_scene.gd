extends Control

# Graphics $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Графика/MarginContainer/VBoxContainer/HBoxContainer/OptionButton"
@onready var resolution_option = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Графика/MarginContainer/VBoxContainer/HBoxContainer/OptionButton"
@onready var fullscreen_option = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Графика/MarginContainer/VBoxContainer/HBoxContainer2/OptionButton"
@onready var vsync_check = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Графика/MarginContainer/VBoxContainer/HBoxContainer3/CheckButton"
@onready var fps_option = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Графика/MarginContainer/VBoxContainer/HBoxContainer4/OptionButton"
@onready var save_graphics = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Графика/MarginContainer2/SaveButton"

@onready var volume_slider = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Звук/MarginContainer/VBoxContainer/HBoxContainer/MarginContainer/HSlider"
@onready var mute_check = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Звук/MarginContainer/VBoxContainer/HBoxContainer2/CheckButton"
@onready var save_sound = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Звук/MarginContainer2/SaveButton"

# Misc
@onready var monday_check = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Хз/MarginContainer/VBoxContainer/HBoxContainer/CheckButton"
@onready var slippery_check = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Хз/MarginContainer/VBoxContainer/HBoxContainer2/CheckButton"
@onready var gravity_option = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Хз/MarginContainer/VBoxContainer/HBoxContainer3/OptionButton"
@onready var temp_option = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Хз/MarginContainer/VBoxContainer/HBoxContainer4/OptionButton"
@onready var save_misc = $"MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TabContainer/Хз/MarginContainer2/SaveButton"


@onready var exit_popup = $PanelContainer


func _ready():
	load_ui_values()

	save_graphics.pressed.connect(_on_save_graphics)
	save_sound.pressed.connect(_on_save_sound)
	save_misc.pressed.connect(_on_save_misc)


func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		show_exit_popup()

func show_exit_popup():
	exit_popup.visible = true

func hide_exit_popup():
	exit_popup.visible = false


func exit_without_saving():
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")


# -------------------
# Load UI
# -------------------

func load_ui_values():
	var g = Settings.settings["graphics"]
	resolution_option.select(_find_option_index(resolution_option, g["resolution"]))
	fullscreen_option.select(_find_option_index(fullscreen_option, g["fullscreen"]))
	vsync_check.button_pressed = g["vsync"]
	fps_option.select(_find_option_index(fps_option, str(g["fps_limit"])))

	var s = Settings.settings["sound"]
	volume_slider.value = s["volume"] * 100.0
	mute_check.button_pressed = s["mute"]

	var m = Settings.settings["misc"]
	monday_check.button_pressed = m["epileptic_mode"]
	slippery_check.button_pressed = m["slippery_world"]
	gravity_option.select(_find_option_index(gravity_option, m["gravity"]))
	temp_option.select(_find_option_index(temp_option, m["temperature"]))

func _find_option_index(opt: OptionButton, text: String) -> int:
	for i in opt.item_count:
		if opt.get_item_text(i) == text:
			return i
	return 0

# -------------------
# Save Graphics
# -------------------

func _on_save_graphics():
	var g = Settings.settings["graphics"]

	g["resolution"] = resolution_option.get_item_text(resolution_option.selected)
	g["fullscreen"] = fullscreen_option.get_item_text(fullscreen_option.selected)
	g["vsync"] = vsync_check.button_pressed
	g["fps_limit"] = fps_option.get_item_text(fps_option.selected)

	Settings.apply_graphics()
	Settings.save_settings()

	print("Graphics saved")

# -------------------
# Save Sound
# -------------------

func _on_save_sound():
	var s = Settings.settings["sound"]

	s["volume"] = volume_slider.value / 100.0
	s["mute"] = mute_check.button_pressed

	Settings.apply_sound()
	Settings.save_settings()

	print("Sound saved")

# -------------------
# Save Misc
# -------------------

func _on_save_misc():
	var m = Settings.settings["misc"]

	m["epileptic_mode"] = monday_check.button_pressed
	m["slippery_world"] = slippery_check.button_pressed
	m["gravity"] = gravity_option.get_item_text(gravity_option.selected)
	m["temperature"] = temp_option.get_item_text(temp_option.selected)

	Settings.apply_misc()
	Settings.save_settings()

	print("Misc saved")



func _on_ok_button_pressed() -> void:
	print("yaas")
	exit_without_saving()



func _on_no_button_pressed() -> void:
	print("no")
	hide_exit_popup()


func _on_exit_button_pressed() -> void:
	exit_without_saving()
