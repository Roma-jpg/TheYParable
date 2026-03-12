extends Node3D

@export var enable_intro_sequence: bool = false  # hardcoded switch

@onready var player_animation_player: AnimationPlayer = $Player/AnimationPlayer
@onready var animation_player: AnimationPlayer = $Player/Y/AnimationPlayer
@onready var camera_animation_player: AnimationPlayer = $Camera3D/CameraAnimationPlayer
@onready var camera_3d: Camera3D = $Camera3D


func _ready() -> void:
	if enable_intro_sequence:
		await _play_intro_sequence()
	else:
		# Skip everything, unlock player immediately
		_unlock_player_controls()
		# Make sure the main camera is active if intro is skipped
		camera_3d.current = false


func _play_intro_sequence() -> void:
	_lock_player_controls()
	LoadingScreen.fade_time = 0
	LoadingScreen.start(4, "Совет: чтобы прыгать, прыгните")
	
	MaterialManager.make_objects_white()
	camera_animation_player.play("CameraPickup")
	camera_animation_player.stop()
	camera_animation_player.seek(0.0, true)
	animation_player.play("wakeup")
	animation_player.stop()
	animation_player.seek(0.0, true)
	
	await get_tree().create_timer(5.2).timeout
	LoadingScreen.fade_time = 1
	LoadingScreen.allow_fade_out()
	await get_tree().create_timer(1).timeout
	_lock_player_controls()
	await get_tree().create_timer(1.5).timeout
	MonologueSystem.play_monologue("1a_Y_wake_up")
	await MonologueSystem.monologue_finished
	await get_tree().create_timer(1.0).timeout
	MonologueSystem.play_monologue("1a_no_anim")
	await MonologueSystem.monologue_finished
	await get_tree().create_timer(1.0).timeout
	Console.open_console()
	Console.type_message("engine.TheYParable.Characters.Y.animated = true;")
	await Console.typing_completed
	await get_tree().create_timer(1.0).timeout
	Console.print_instant("[color=green]Variable `engine.TheYParable.Characters.Y.animated` changed to `true`.[/color]")
	await get_tree().create_timer(1.0).timeout
	
	Console.close()
	MonologueSystem.play_monologue("1a_now_you_can_move")
	await MonologueSystem.monologue_finished
	animation_player.play("wakeup")
	await animation_player.animation_finished
	player_animation_player.play("walk_up")
	player_animation_player.stop()
	player_animation_player.seek(0.0, true)
	MonologueSystem.play_monologue("1a_see_that_camera")
	await MonologueSystem.monologue_finished
	await get_tree().create_timer(1.0).timeout
	player_animation_player.play("walk_up")
	await player_animation_player.animation_finished
	camera_animation_player.play("CameraPickup")
	await camera_animation_player.animation_finished
	_unlock_player_controls()
	
	await get_tree().create_timer(2.0).timeout
	await MonologueSystem.play_and_wait_monologues([
		"2a_just_look_at_that",
		"2a_adult_joke",
		"2a_being_serious_now",
	    "2a_now_we_will_meet_aspect"
	])
	await MonologueSystem.monologue_finished
	await get_tree().create_timer(1.0).timeout
	
	VisualisationDirector.show_slide("materials")
	await VisualisationDirector.slides_finished
	
	await get_tree().create_timer(1.0).timeout
	
	

func _lock_player_controls():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("lock_controls"):
			p.lock_controls()

func _unlock_player_controls():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("unlock_controls"):
			p.unlock_controls()
