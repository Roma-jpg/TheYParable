extends BaseTrigger

func on_trigger_enter(_body):
	MonologueSystem.play_monologue("T_good_job")
	await MonologueSystem.monologue_finished
	await get_tree().create_timer(1).timeout
	LoadingScreen.start(3, "Пора поменяться местами ;)")
	await get_tree().create_timer(1.5).timeout
	await MonologueSystem.play_and_wait_monologues(["puzzle_room_outro_1", "puzzle_room_outro_2", "puzzle_room_outro_3"])
	await get_tree().create_timer(1).timeout
	LoadingScreen.allow_fade_out()
	get_tree().change_scene_to_file("res://Scenes/final_room.tscn")
