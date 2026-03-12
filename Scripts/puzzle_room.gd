extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_lock_player_controls()
	await get_tree().create_timer(1.0).timeout
	await MonologueSystem.play_and_wait_monologues(["puzzle_room_intro_1", "puzzle_room_intro_2", "puzzle_room_intro_3"])
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
