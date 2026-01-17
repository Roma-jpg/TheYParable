class_name Interactable
extends Area3D

@export var interaction_text: String = "Interact [E]"

var is_focused: bool = false

func _ready():
	collision_layer = 2
	collision_mask = 0
	input_ray_pickable = true

func on_gained_focus():
	if is_focused:
		return
	is_focused = true
	print("[INTERACTABLE] Focus gained: ", name)

func on_lost_focus():
	if not is_focused:
		return
	is_focused = false
	print("[INTERACTABLE] Focus lost: ", name)

func interact():
	print("[INTERACTABLE] Interact called: ", name)
	perform_interaction()

func perform_interaction():
	print("[INTERACTABLE] Default interaction")

func get_interaction_text() -> String:
	return interaction_text
