extends Node2D

@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	if PunishmentManager.punishment_active and not PunishmentManager.video_completed:
		get_tree().change_scene_to_file("res://Scenes/punishment_room.tscn")

func _on_start_button_pressed() -> void:
	canvas_layer.visible = false
	LoadingScreen.start(
		6.0,
		"Совет: Чтобы идти вперёд, идите вперёд."
	)
	
	await get_tree().create_timer(5.3).timeout
	get_tree().change_scene_to_file("res://Scenes/start_room.tscn")
	LoadingScreen.allow_fade_out()

func _on_options_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/settings_scene.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func fade_out_canvas_layer() -> void:
	var tween := get_tree().create_tween()
	tween.tween_property(
		canvas_layer,
		"modulate:a",
		0.0,
		1.0
	)
