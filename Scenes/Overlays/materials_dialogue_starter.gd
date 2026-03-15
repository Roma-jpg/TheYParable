extends MarginContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await MonologueSystem.play_and_wait_monologues(["2a_materials_expl1", "2a_materials_expl2", ""])
	print("HELL YEAH")
