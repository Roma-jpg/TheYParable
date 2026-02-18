extends Node3D  # Attach this script to the root node of your trampoline scene

# Reference to the CollisionShape3D as given
@onready var collision_shape_3d_2: CollisionShape3D = $JumpArea3D/CollisionShape3D2

# The Area3D that actually detects bodies (parent of the shape)
@onready var jump_area: Area3D = collision_shape_3d_2.get_parent()

# How high the player should be launched (adjust in the inspector)
@export var launch_strength: float = 15.0

func _ready():
	# Make sure the area can detect bodies
	jump_area.monitoring = true
	# Connect the signal
	jump_area.body_entered.connect(_on_jump_area_body_entered)

func _on_jump_area_body_entered(body: Node3D):
	# Only affect the player
	if not body.is_in_group("player"):
		return
	
	# Launch upward depending on body type
	if body is CharacterBody3D:
		# For character bodies, set vertical velocity
		body.velocity.y = launch_strength
	elif body is RigidBody3D:
		# For rigid bodies, apply an impulse
		body.apply_central_impulse(Vector3.UP * launch_strength * body.mass)
	else:
		# Fallback: try to set linear_velocity if it exists (some custom bodies)
		if body.has_method("set_linear_velocity"):
			body.set_linear_velocity(Vector3.UP * launch_strength)
	
	# Optional: play a sound or effect here
	print("Trampoline launched ", body.name)
