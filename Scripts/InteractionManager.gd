extends Node
class_name InteractionManager

@export var max_interaction_distance: float = 5.0
@export var interaction_key: String = "interact"

signal interactable_focused(text: String)
signal interactable_unfocused()

@onready var camera: Camera3D = get_parent() if get_parent() is Camera3D else null
@onready var raycast: RayCast3D = $RayCast3D if has_node("RayCast3D") else null

var current_interactable: Interactable = null
var can_interact: bool = true

func _ready():
	if not raycast:
		raycast = RayCast3D.new()
		raycast.name = "RayCast3D"
		raycast.enabled = true
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = false
		raycast.collision_mask = 2
		add_child(raycast)

func _process(_delta):
	if not can_interact or not camera:
		return
	
	raycast.global_transform.origin = camera.global_transform.origin
	raycast.target_position = camera.global_transform.basis * Vector3(0, 0, -max_interaction_distance)
	
	_check_for_interactable()

func _check_for_interactable():
	var previous_interactable = current_interactable
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		current_interactable = collider.get_parent() as Interactable
		if not current_interactable and collider is Interactable:
			current_interactable = collider
		
		if current_interactable:
			var distance = camera.global_transform.origin.distance_to(current_interactable.global_transform.origin)
			if distance > max_interaction_distance:
				current_interactable = null
	else:
		current_interactable = null
	
	if previous_interactable != current_interactable:
		if previous_interactable:
			previous_interactable.on_lost_focus()
			interactable_unfocused.emit()
		if current_interactable:
			current_interactable.on_gained_focus()
			interactable_focused.emit(current_interactable.get_interaction_text())

func _input(event):
	if not can_interact:
		return
	if event.is_action_pressed(interaction_key) and current_interactable:
		current_interactable.interact()

func enable_interaction():
	can_interact = true

func disable_interaction():
	can_interact = false
	if current_interactable:
		current_interactable.on_lost_focus()
		current_interactable = null
		interactable_unfocused.emit()

func get_current_interactable() -> Interactable:
	return current_interactable

func is_looking_at_interactable() -> bool:
	return current_interactable != null
