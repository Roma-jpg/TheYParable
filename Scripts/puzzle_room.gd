extends Node3D

@onready var cubick: RigidBody3D = $RigidBody3D
var _is_handling_fall := false
var _first_fall_done := false

func _ready() -> void:
	_lock_player_controls()
	await get_tree().create_timer(1.0).timeout
	await MonologueSystem.play_and_wait_monologues(["puzzle_room_intro_1", "puzzle_room_intro_2", "puzzle_room_intro_3"])
	_unlock_player_controls()
	

func _process(_delta: float) -> void:
	if cubick.position.y < -20 and not _is_handling_fall:
		_is_handling_fall = true
		_handle_fall()

func _handle_fall() -> void:
	await get_tree().create_timer(1.0).timeout

	if cubick.position.y >= -20:
		_is_handling_fall = false
		return

	if not _first_fall_done:
		MonologueSystem.play_monologue("how_could_you_lose_a_cube")
		await MonologueSystem.monologue_finished
		await get_tree().create_timer(1.0).timeout
		_first_fall_done = true
	else:
		await get_tree().create_timer(1.0).timeout
	cubick.position = Vector3(-5.16, 0.78, -5.53)
	_is_handling_fall = false

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
