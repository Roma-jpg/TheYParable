extends Node3D

@onready var player_animation_player: AnimationPlayer = $Player/AnimationPlayer
@onready var animation_player: AnimationPlayer = $Player/Y/AnimationPlayer
@onready var camera_animation_player: AnimationPlayer = $Camera3D/CameraAnimationPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_lock_player_controls()
	LoadingScreen.fade_time = 0
	LoadingScreen.start(4, "Совет: чтобы прыгать, прыгните")
	
	camera_animation_player.play("CameraPickup")
	camera_animation_player.stop()          # stop at current frame
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
	player_animation_player.stop()          # stop at current frame
	player_animation_player.seek(0.0, true) # go to first frame (0 seconds)
	MonologueSystem.play_monologue("1a_see_that_camera")
	await MonologueSystem.monologue_finished
	await get_tree().create_timer(1.0).timeout
	player_animation_player.play("walk_up")
	await player_animation_player.animation_finished
	camera_animation_player.play("CameraPickup")
	await camera_animation_player.animation_finished
	print("done")
	_unlock_player_controls()

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
