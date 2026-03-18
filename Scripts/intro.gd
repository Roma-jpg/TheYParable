extends Node

# UI Elements
@onready var slides: Array[Control] = [
	$CanvasLayer/ColorRect/Slide1,
	$CanvasLayer/ColorRect/Slide2,
	$CanvasLayer/ColorRect/Slide3
]
@onready var subtitle_display: Label = $CanvasLayer/SubtitleDisplay # Ensure you have this node!

var current_step := 0
var is_transitioning := false

func _ready() -> void:
	# Connect the subtitle system
	MonologueSystem.subtitle_changed.connect(_on_subtitle_changed)
	
	# Hide all slides initially
	for slide in slides:
		slide.visible = false
		slide.modulate.a = 0.0

	# Start the first step automatically after a tiny delay to ensure the scene has loaded
	await get_tree().create_timer(0.5).timeout
	execute_step(0)

func _input(event: InputEvent) -> void:
	# Prevent mashing the spacebar while things are fading in/out
	if is_transitioning:
		return
		
	# Check for Space, Enter, or Left Mouse Click
	if event.is_action_pressed("ui_accept") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		if MonologueSystem.is_playing:
			# If they press space while talking, skip the current audio line
			MonologueSystem.skip_monologue()
		else:
			# If audio is done, advance to the next step
			current_step += 1
			execute_step(current_step)

# === THE STATE MACHINE ===
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

# === HELPER FUNCTIONS ===

@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

func play_audio(audio_name: String) -> void:
	# 1. Construct the full path
	var file_path = "res://Assets/Audio/Monologues/" + audio_name + ".wav"
	
	# 2. Check if the file actually exists before trying to load it
	if FileAccess.file_exists(file_path):
		# 3. Load the audio file from the folder
		var stream = load(file_path)
		
		# 4. Assign to your node and play
		audio_player.stream = stream
		audio_player.play()
		
		# 5. Update the MonologueSystem text manually 
		# (So the subtitles still show up!)
		if MonologueSystem.monologues.has(audio_name):
			MonologueSystem.subtitle_changed.emit(MonologueSystem.monologues[audio_name])
	else:
		push_error("CRITICAL: Audio file not found at " + file_path)

func fade_to_slide(index: int) -> void:
	var tween = create_tween()
	tween.set_parallel(true) # Run fades simultaneously
	
	for i in slides.size():
		if i == index:
			slides[i].visible = true
			tween.tween_property(slides[i], "modulate:a", 1.0, 0.6)
		else:
			tween.tween_property(slides[i], "modulate:a", 0.0, 0.6)
			
	await tween.finished
	
	# Clean up visibility for hidden slides
	for i in slides.size():
		if i != index:
			slides[i].visible = false

func finish_presentation() -> void:
	MonologueSystem.stop_monologue()
	MonologueSystem.clear_queue()
	
	# A short pause before triggering the loading screen
	await get_tree().create_timer(0.5).timeout
	
	LoadingScreen.start(4.0, "Совет: Чтобы идти вперёд, идите вперёд.")
	await get_tree().create_timer(3.9).timeout
	LoadingScreen.allow_fade_out()
	
	get_tree().change_scene_to_file("res://Scenes/start_room.tscn")

func _on_subtitle_changed(text: String) -> void:
	if subtitle_display:
		subtitle_display.text = text
