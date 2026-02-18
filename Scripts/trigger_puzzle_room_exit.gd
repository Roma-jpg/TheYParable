extends BaseTrigger

@export var monologue_id: String = "intro_01"

func on_trigger_enter(body):
	MonologueSystem.play_monologue("T_good_job")
	await MonologueSystem.monologue_finished
	await get_tree().create_timer(1).timeout
	LoadingScreen.start(3, "Пора поменяться местами ;)")
	await get_tree().create_timer(3).timeout
	LoadingScreen.allow_fade_out()
	get_tree().change_scene_to_file("res://Scenes/puzzle_room.tscn")
