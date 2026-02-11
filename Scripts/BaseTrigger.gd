extends Area3D
class_name BaseTrigger

@export var target_group: String = "player"
@export var one_shot: bool = false
@export var enabled: bool = true

var triggered: bool = false

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if not enabled:
		return
	
	if one_shot and triggered:
		return
	
	if body.is_in_group(target_group):
		triggered = true
		on_trigger_enter(body)

func on_trigger_enter(body):
	pass  # Override in subclasses
