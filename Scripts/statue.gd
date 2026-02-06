extends Interactable

@export var sound_effect: AudioStream  # assign in Inspector
@export var rotation_axis: Vector3 = Vector3.UP  # axis to rotate around

var rotating := false  # lock to prevent multiple interactions

func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = "Цитоплазматические"

func perform_interaction():
	if rotating:
		return  # ignore input while rotation is happening
	if not sound_effect:
		print("No sound effect assigned")
		return

	rotating = true  # lock

	var parent_node = get_parent()

	# Create and play the audio
	var audio_player := AudioStreamPlayer3D.new()
	parent_node.add_child(audio_player)
	audio_player.stream = sound_effect
	audio_player.play()

	# Duration of the sound
	var duration := sound_effect.get_length()

	# Random direction: left (-1) or right (+1)
	var direction := -1 if randf() < 0.5 else 1
	var target_angle := deg_to_rad(90 * direction)

	# Tween rotation over sound duration
	var tween := create_tween()
	tween.tween_property(
		parent_node,
		"rotation",
		parent_node.rotation + rotation_axis * target_angle,
		duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Unlock and cleanup when finished
	tween.finished.connect(func():
		audio_player.queue_free()
		rotating = false
	)
