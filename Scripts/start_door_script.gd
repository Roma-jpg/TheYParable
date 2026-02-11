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
		opened = true
	else:
		interaction_text = "Дверь заклинило в этом положении, закрыть обратно нельзя."
