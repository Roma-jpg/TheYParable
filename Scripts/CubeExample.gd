extends Interactable

@export var interaction_count: int = 0
@onready var console: Control = Console

func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = interaction_text

func perform_interaction():
	
	console.show()  # Or modulate alpha, etc.

	await console.type_message("> engine.Core.TheYParable.collision = true;", false, 0.04)  # Slower typing
	await get_tree().create_timer(1).timeout
	await console.print_instant("[color=green]Parameter `collisions` was successfully changed to `true`.[/color]")
	await get_tree().create_timer(1).timeout
	console.close()
