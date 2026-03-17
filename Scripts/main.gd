extends Node3D

# The scene to spawn (assign in the inspector)
@export var scene_to_spawn: PackedScene
# Spawn interval in seconds
@export var spawn_interval: float = 2.0
# Coordinates where the scene will be spawned (local to this node)
@export var spawn_position: Vector3 = Vector3(-17, 0, 165)

@onready var timer: Timer = $Timer

func _ready():
	timer.wait_time = spawn_interval
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	await get_tree().create_timer(1).timeout
	#MonologueSystem.play_and_wait_monologues([
		#"debug_room_1",
		#"debug_room_2",
		#"debug_room_3",
		#"debug_room_4",
		#"debug_room_5",
		#"try_to_kill_yourself",
		#"you_cant_die_in_this_game"
	#])

func _on_timer_timeout():
	# Check if there is already an instance of the spawned object in the scene
	var instances = get_tree().get_nodes_in_group("spawned_object")
	if instances.is_empty():   # Only spawn if none exist
		if scene_to_spawn:
			var instance = scene_to_spawn.instantiate()
			add_child(instance)
			instance.position = spawn_position
	# If an instance exists, do nothing (skip spawning)
