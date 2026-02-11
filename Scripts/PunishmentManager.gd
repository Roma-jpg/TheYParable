extends Node

var save_path = "user://punishment.save"

var punishment_active = false
var video_completed = false


func _ready():
	load_state()


func start_punishment():
	punishment_active = true
	video_completed = false
	save_state()


func finish_video():
	video_completed = true
	punishment_active = false
	save_state()


func load_state():
	if not FileAccess.file_exists(save_path):
		return
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	while not file.eof_reached():
		var line = file.get_line()
		if line.begins_with("punishment_active="):
			punishment_active = line.split("=")[1] == "true"
		elif line.begins_with("video_completed="):
			video_completed = line.split("=")[1] == "true"


func save_state():
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_line("punishment_active=" + str(punishment_active))
	file.store_line("video_completed=" + str(video_completed))
