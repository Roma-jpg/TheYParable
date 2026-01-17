extends Node
class_name InteractionManager

# Configuration
@export var max_interaction_distance: float = 5.0
@export var interaction_key: String = "interact"  # Set up in Input Map
@export var show_debug_ray: bool = false
@export var ray_color: Color = Color.YELLOW
@export var ray_width: float = 0.02

@export var ui_controller: Control

signal interactable_focused(text: String)  # Now sends String
signal interactable_unfocused()

# Node references
@onready var camera: Camera3D = get_parent() if get_parent() is Camera3D else null
@onready var raycast: RayCast3D = $RayCast3D if has_node("RayCast3D") else null

# State variables
var current_interactable: Interactable = null
var can_interact: bool = true


func _ready():
	# Initialize raycast if not already in scene
	if not raycast:
		raycast = RayCast3D.new()
		raycast.name = "RayCast3D"
		raycast.enabled = true
		raycast.collide_with_areas = true
		raycast.collide_with_bodies = false
		raycast.collision_mask = 2
		add_child(raycast)
	
	if show_debug_ray:
		setup_debug_ray()

func _process(_delta):
	if not can_interact or not camera:
		return
	
	# Update raycast position and direction
	update_raycast()
	update_ui()
	
	# Check for interactables
	check_for_interactable()

func update_raycast():
	# Position raycast at camera
	if camera:
		raycast.global_transform.origin = camera.global_transform.origin
		raycast.target_position = camera.global_transform.basis * Vector3(0, 0, -max_interaction_distance)
		
		# Update debug ray if enabled
		if show_debug_ray:
			update_debug_ray()

# In check_for_interactable() function, add these prints:
func check_for_interactable():
	var previous_interactable = current_interactable
	
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		# Check for Interactable (Area3D)
		current_interactable = collider.get_parent() as Interactable
		
		# If collider itself is Interactable (for Area3D)
		if not current_interactable and collider is Interactable:
			current_interactable = collider
		
		# Check distance
		if current_interactable:
			var distance = camera.global_transform.origin.distance_to(current_interactable.global_transform.origin)
			if distance > max_interaction_distance:
				current_interactable = null
	else:
		current_interactable = null
	
	# Handle focus changes
	if previous_interactable != current_interactable:
		if previous_interactable:
			previous_interactable.on_lost_focus()
			interactable_unfocused.emit()  # ← Changed: no parameter
		if current_interactable:
			current_interactable.on_gained_focus()
			interactable_focused.emit(current_interactable.get_interaction_text())

func _input(event):
	if not can_interact:
		return
	
	if event.is_action_pressed(interaction_key) and current_interactable:
		current_interactable.interact()
		# Optional: Disable interaction briefly to prevent spamming
		# can_interact = false
		# await get_tree().create_timer(0.2).timeout
		# can_interact = true

func setup_debug_ray():
	# Create a CylinderMesh for visualization
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = "DebugRay"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = ray_width / 2
	cylinder.bottom_radius = ray_width / 2
	cylinder.height = max_interaction_distance
	
	mesh_instance.mesh = cylinder
	mesh_instance.material_override = StandardMaterial3D.new()
	mesh_instance.material_override.albedo_color = ray_color
	
	# Position and rotate the cylinder
	mesh_instance.position = Vector3(0, 0, -max_interaction_distance / 2)
	mesh_instance.rotation_degrees = Vector3(90, 0, 0)
	
	add_child(mesh_instance)

func update_ui():
	if not ui_controller:
		return
	
	if current_interactable:
		# Tell UI to show text
		if ui_controller.has_method("show_interaction"):
			ui_controller.show_interaction(current_interactable.get_interaction_text())
	else:
		# Tell UI to hide
		if ui_controller.has_method("hide_interaction"):
			ui_controller.hide_interaction()

func update_debug_ray():
	var debug_ray = get_node_or_null("DebugRay")
	if debug_ray:
		debug_ray.visible = current_interactable != null

# Public methods for external control
func enable_interaction():
	can_interact = true

func disable_interaction():
	can_interact = false
	if current_interactable:
		current_interactable.on_lost_focus()
		current_interactable = null

func get_current_interactable() -> Interactable:
	return current_interactable

func is_looking_at_interactable() -> bool:
	return current_interactable != null
