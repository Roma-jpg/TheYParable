extends Node3D

# Reference to the CollisionShape3D as given
@onready var collision_shape_3d_2: CollisionShape3D = $JumpArea3D/CollisionShape3D2

# The Area3D that actually detects bodies (parent of the shape)
@onready var jump_area: Area3D = collision_shape_3d_2.get_parent()

# How high the player should be launched (adjust in the inspector)
@export var launch_strength: float = 15.0

# Hardcoded path to the trampoline sound effect
const TRAMPOLINE_SOUND_PATH = "res://Assets/Audio/cartoon-jump.wav"

# Audio player reference (created at runtime)
var audio_player: AudioStreamPlayer3D

func _ready():
	# Make sure the area can detect bodies
	jump_area.monitoring = true
	# Connect the signal
	jump_area.body_entered.connect(_on_jump_area_body_entered)
	
	# Create and set up the audio player
	audio_player = AudioStreamPlayer3D.new()
	# Load the sound resource from the hardcoded path
	var sound_stream = load(TRAMPOLINE_SOUND_PATH) as AudioStream
	if sound_stream:
		audio_player.stream = sound_stream
	else:
		push_error("Trampoline sound effect not found at: ", TRAMPOLINE_SOUND_PATH)
	# Add it as a child so it processes in 3D space
	add_child(audio_player)

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
	
	# Play the trampoline sound effect
	if audio_player and audio_player.stream:
		audio_player.play()
	
	# Optional debug message
	print("Trampoline launched ", body.name)
