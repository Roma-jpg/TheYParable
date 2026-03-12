extends BaseTrigger

func _ready() -> void:
	super._ready()
	one_shot = false

func _on_trigger_enter(body: CharacterBody3D):
	body.position.y -= 10
