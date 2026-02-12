extends Interactable

var opened := false
@onready var animation_player: AnimationPlayer = $"../AnimationPlayer"

func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = interaction_text

func perform_interaction():
	if !opened:
		animation_player.play("start_door_open")
		var sound = AudioStreamPlayer2D.new()
		sound.stream = preload("res://Assets/Audio/door_open.wav")
		sound.volume_db = 2
		add_child(sound)
		sound.play()
		await sound.finished
		sound.queue_free()
		opened = true
		interaction_text = "Дверь заклинило в этом положении, закрыть обратно нельзя."
	else:
		interaction_text = "Дверь заклинило в этом положении, закрыть обратно нельзя."
