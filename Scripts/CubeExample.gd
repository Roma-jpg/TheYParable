extends Interactable

@export var interaction_count: int = 0

func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = "[E]Cube"

func perform_interaction():
	
	MonologueSystem.play_monologue("1a_Y_wake_up")
	# Ожидание завершения
	await MonologueSystem.monologue_finished
	print("Монолог завершен!")
