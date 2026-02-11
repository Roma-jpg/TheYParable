extends Node

@onready var texture_rect_on: TextureRect = $TextureRect_on
@onready var texture_rect_off: TextureRect = $TextureRect_off
@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

# Путь к монологам
var first_monologue = "res://Assets/Audio/Monologues/serious_room.wav"
var second_monologue = "res://Assets/Audio/Monologues/serious_room_2.wav"
var reward_monologue = "res://Assets/Audio/Monologues/serious_room_3.wav"

func _ready():
	# Телевизор выключен
	texture_rect_on.visible = false
	texture_rect_off.visible = true
	
	# Выбираем первый или второй монолог
	var monologue_path = first_monologue
	if PunishmentManager.punishment_active and not PunishmentManager.video_completed:
		monologue_path = second_monologue
	
	_play_monologue(monologue_path, "_on_start_monologue_finished")


func _play_monologue(path: String, callback_name: String):
	audio_stream_player_2d.stream = load(path)
	audio_stream_player_2d.play()
	audio_stream_player_2d.connect("finished", Callable(self, callback_name))


func _on_start_monologue_finished():
	# Включаем телевизор и запускаем видео
	texture_rect_off.visible = false
	texture_rect_on.visible = true
	video_stream_player.visible = true
	video_stream_player.play()
	
	PunishmentManager.start_punishment()
	
	# Ждем окончания видео
	video_stream_player.connect("finished", Callable(self, "_on_video_finished"))


func _on_video_finished():
	# Проигрываем монолог награды после видео
	_play_monologue(reward_monologue, "_on_reward_monologue_finished")


func _on_reward_monologue_finished():
	PunishmentManager.finish_video()
	# Здесь можно добавить переход обратно в игру, если нужно
	await get_tree().create_timer(1.0).timeout
	LoadingScreen.start(3, "Извини что тебе пришлось это увидеть.")
	await get_tree().create_timer(3.0).timeout
	LoadingScreen.allow_fade_out()
	get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
	get_tree().quit()
