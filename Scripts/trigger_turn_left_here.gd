extends BaseTrigger

func _ready() -> void:
	super._ready()
	one_shot = true
	pass

func on_trigger_enter(_body: CharacterBody3D) -> void:
	MonologueSystem.play_monologue("T_corridor_to_the_left")
