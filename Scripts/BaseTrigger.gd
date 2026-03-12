# BaseTrigger.gd
extends Area3D
class_name BaseTrigger

@export var target_group: String = "player"
@export var one_shot: bool = true
@export var enabled: bool = true

var has_been_triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if not enabled:
		return
	if one_shot and has_been_triggered:
		return
	if body.is_in_group(target_group):
		has_been_triggered = true
		on_trigger_enter(body)

# Change this line — most triggers expect the player anyway
func on_trigger_enter(body: CharacterBody3D) -> void:
	pass
