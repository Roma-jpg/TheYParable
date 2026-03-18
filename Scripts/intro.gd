extends Node

# UI Elements
@onready var slides: Array[Control] = [
	$CanvasLayer/ColorRect/Slide1,
	$CanvasLayer/ColorRect/Slide2,
	$CanvasLayer/ColorRect/Slide3
]
@onready var subtitle_display: Label = $CanvasLayer/SubtitleDisplay

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

# === PRELOADED AUDIO ===
var audio_map := {
	"0a_hello": preload("res://Assets/Audio/Monologues/0a_hello.wav"),
	"0a_but_first_theory": preload("res://Assets/Audio/Monologues/0a_but_first_theory.wav"),
	"0a_engine_is": preload("res://Assets/Audio/Monologues/0a_engine_is.wav"),
	"0a_90s_graphics": preload("res://Assets/Audio/Monologues/0a_90s_graphics.wav"),
	"0a_I_chose_godot": preload("res://Assets/Audio/Monologues/0a_I_chose_godot.wav"),
	"0a_godot_is_simple": preload("res://Assets/Audio/Monologues/0a_godot_is_simple.wav")
}

var has_started := false
var current_step := 0
var is_transitioning := false

func _ready() -> void:
	MonologueSystem.subtitle_changed.connect(_on_subtitle_changed)
	
	for slide in slides:
		slide.visible = false
		slide.modulate.a = 0.0

	await get_tree().create_timer(0.5).timeout
	has_started = true
	execute_step(0)

func _input(event: InputEvent) -> void:
	if not has_started:
		return
		
	if is_transitioning:
		return
		
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if MonologueSystem.is_playing:
			MonologueSystem.skip_monologue()
		else:
			current_step += 1
			execute_step(current_step)

# === STATE MACHINE ===
func execute_step(step: int) -> void:
	is_transitioning = true
	
	match step:
		0:
			await fade_to_slide(0)
			play_audio("0a_hello")
		1:
			play_audio("0a_but_first_theory")
		2:
			await fade_to_slide(1)
			play_audio("0a_engine_is")
		3:
			play_audio("0a_90s_graphics")
		4:
			await fade_to_slide(2)
			play_audio("0a_I_chose_godot")
		5:
			play_audio("0a_godot_is_simple")
		6:
			await finish_presentation()
			
	is_transitioning = false

# === AUDIO ===
func play_audio(audio_name: String) -> void:
	var stream: AudioStream = null
	
	# 1. Try preloaded first (fast + safe for export)
	if audio_map.has(audio_name):
		stream = audio_map[audio_name]
	else:
		# 2. Fallback to runtime load (just in case)
		var file_path = "res://Assets/Audio/Monologues/" + audio_name + ".wav"
		stream = ResourceLoader.load(file_path)
		
		if stream == null:
			push_error("Failed to load " + file_path)
			return
	
	audio_player.stream = stream
	audio_player.play()
	
	# Subtitle sync
	if MonologueSystem.monologues.has(audio_name):
		MonologueSystem.subtitle_changed.emit(MonologueSystem.monologues[audio_name])

# === VISUALS ===
func fade_to_slide(index: int) -> void:
	var tween = create_tween()
	tween.set_parallel(true)
	
	for i in slides.size():
		if i == index:
			slides[i].visible = true
			tween.tween_property(slides[i], "modulate:a", 1.0, 0.6)
		else:
			tween.tween_property(slides[i], "modulate:a", 0.0, 0.6)
			
	await tween.finished
	
	for i in slides.size():
		if i != index:
			slides[i].visible = false

# === END ===
func finish_presentation() -> void:
	MonologueSystem.stop_monologue()
	MonologueSystem.clear_queue()
	
	await get_tree().create_timer(0.5).timeout
	
	LoadingScreen.start(4.0, "Совет: Чтобы идти вперёд, идите вперёд.")
	await get_tree().create_timer(3.9).timeout
	LoadingScreen.allow_fade_out()
	
	get_tree().change_scene_to_file("res://Scenes/start_room.tscn")

func _on_subtitle_changed(text: String) -> void:
	if subtitle_display:
		subtitle_display.text = text
