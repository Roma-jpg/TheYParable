# LocationAFKTrigger.gd
extends BaseTrigger
class_name LocationAFKTrigger

# Array of stages, each with a "time" (float) and a "monologue" (String or Array[String])
@export var idle_stages: Array[Dictionary] = [
	{ "time": 5.0,  "monologue": ["t_corridor_idle_1", "t_corridor_idle_2", "t_corridor_idle_3", "t_corridor_idle_4"] },
	{ "time": 25.0, "monologue": ["t_corridor_idle_5", "t_corridor_idle_6"] },
	{ "time": 50.0, "monologue": ["u_should_explore_1", "u_should_explore_2", "u_should_explore_3", "u_should_explore_4"] }
]

var player: CharacterBody3D = null
var idle_timer: float = 0.0
var current_stage_index: int = 0
var is_playing_monologue: bool = false
var monitoring2: bool = false

func _ready():
	super._ready()
	body_exited.connect(_on_body_exited)
	# Ensure stages are sorted by time (just in case)
	idle_stages.sort_custom(func(a, b): return a["time"] < b["time"])

func _on_body_entered(body: Node3D):
	# Let the base class filter by group and one‑shot setting
	super._on_body_entered(body)

func on_trigger_enter(body: CharacterBody3D):
	# Called only if base class conditions are met
	player = body
	idle_timer = 0.0
	current_stage_index = 0
	is_playing_monologue = false
	monitoring2 = true

func _on_body_exited(body: Node3D):
	if body == player:
		# Player left the area – stop monitoring2 and reset
		monitoring2 = false
		player = null
		idle_timer = 0.0
		current_stage_index = 0
		is_playing_monologue = false

func _process(delta: float):
	if not monitoring2 or player == null:
		return

	# Determine if player is idle: on floor and not moving horizontally
	var is_idle = player.is_on_floor() and Vector2(player.velocity.x, player.velocity.z).length_squared() < 0.01

	if is_idle:
		idle_timer += delta
	else:
		# Movement resets everything – idle chain broken
		idle_timer = 0.0
		current_stage_index = 0
		# If a monologue was playing, it will continue, but the stage index is reset,
		# so after it finishes we won't accidentally advance further.
		# (You could also cancel the monologue here, but that's optional.)

	# Check if we've reached the next stage and are not already playing one
	while current_stage_index < idle_stages.size() and idle_timer >= idle_stages[current_stage_index]["time"]:
		if not is_playing_monologue:
			_play_stage_monologue(idle_stages[current_stage_index]["monologue"])
			# _play_stage_monologue is async; it will advance the index when done.
			# We break here to avoid multiple triggers in the same frame.
			break
		else:
			# If we are already playing, just wait – the index will advance after the monologue ends.
			break

func _play_stage_monologue(monologue_data):
	is_playing_monologue = true

	# Convert monologue_data to an Array[String]
	var monologue_array: Array[String]
	if monologue_data is String:
		monologue_array = [monologue_data]
	elif monologue_data is Array:
		# Ensure all elements are strings (convert if necessary)
		monologue_array = []
		for item in monologue_data:
			monologue_array.append(str(item))  # Convert to string just in case
	else:
		push_error("Invalid monologue data type: ", typeof(monologue_data))
		is_playing_monologue = false
		return

	# Play all monologues in sequence and wait for completion
	await MonologueSystem.play_and_wait_monologues(monologue_array)

	# After the monologue(s) finish, advance to the next stage
	current_stage_index += 1
	is_playing_monologue = false

	# Note: the idle timer continues accumulating while the monologue played,
	# so if the player remained idle, we might already be past the next stage's time.
	# The _process loop will catch that in the next frame because we reset is_playing_monologue.
