extends Interactable

var sfx_player: AudioStreamPlayer

@export var audio_path := "res://Assets/Audio/gudok-poezda_reverb.mp3"
@export var image_path := "res://Assets/Pictures/fuckin_train.jpg"
@export var image_node_path: NodePath
@export var fade_duration := 2.0

@onready var screen_image: TextureRect = get_node(image_node_path)

func _ready():
	super._ready()
	update_interaction_text()
	_setup_sfx()
	if screen_image:
		screen_image.visible = false
		screen_image.modulate.a = 1.0

func update_interaction_text():
	interaction_text = interaction_text

func _setup_sfx():
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	sfx_player.stream = load(audio_path)

func perform_interaction():
	print("From polka")
	if not sfx_player.playing:
		sfx_player.play()
		_show_image_with_fade()

func _show_image_with_fade():
	if not screen_image:
		return

	screen_image.visible = true
	screen_image.modulate.a = 1.0

	var audio_length = sfx_player.stream.get_length()
	var fade_start_time = max(audio_length - fade_duration, 0.0)

	await get_tree().create_timer(fade_start_time).timeout

	# fade out over fade_duration
	var timer = 0.0
	while timer < fade_duration:
		var delta = get_process_delta_time()
		timer += delta
		screen_image.modulate.a = clamp(1.0 - timer / fade_duration, 0.0, 1.0)
		await get_tree().process_frame

	screen_image.visible = false
	screen_image.modulate.a = 1.0  # reset alpha for next time
