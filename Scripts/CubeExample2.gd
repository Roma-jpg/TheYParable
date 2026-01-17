extends Interactable

@export var interaction_count: int = 0


func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = interaction_text

func perform_interaction():
	await Console.open_console()
	await get_tree().create_timer(1.5).timeout
	await Console.type_message("engine.TheYParable.Core.collision_processing = true;")
	await get_tree().create_timer(2).timeout
	Console.print_instant("[color=green]Variable `engine.TheYParable.Core.collision_processing` is set to `true`.[/color]")
	await get_tree().create_timer(2.5).timeout
	Console.close()
	
