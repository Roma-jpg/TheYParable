extends Interactable


func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = interaction_text

func perform_interaction():
	LoadingScreen.start(3, "Шоутайм!")
	await get_tree().create_timer(2.7).timeout
	get_tree().change_scene_to_file("res://Scenes/level_editor.tscn")
	LoadingScreen.allow_fade_out()
