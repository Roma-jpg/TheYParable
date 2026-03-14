extends Node3D

@export var speed: float = 26.0

var lifetime: float = 0.0

func _ready():
	add_to_group("spawned_object")   # Add to group for counting

func _physics_process(delta):
	position.z -= speed * delta
	lifetime += delta
	if lifetime >= 20.0:
		queue_free()
