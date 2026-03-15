extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(1).timeout
	await MonologueSystem.play_and_wait_monologues(["final_room_intro1", "final_room_intro2"])
	print("yada yada yada")
	
