extends BaseTrigger

@export var target_position: Vector3 = Vector3(-15.2, 1.05, -0.5)
@onready var neon_sign: Node3D = $"../../../neon_sign"
@onready var video_stream_player: VideoStreamPlayer = $VideoStreamPlayer

var counter := -1
var can_interact := true

func _ready() -> void:
	super._ready()
	one_shot = false

func on_trigger_enter(body):
	if can_interact:
		pass
	else:
		return
	# Телепорт игрока
	body.global_position = target_position
	
	# Повернуть игрока строго в -X
	body.look_at(body.global_position + Vector3.LEFT, Vector3.UP)
	
	if counter <= 1:
		MonologueSystem.play_monologue("T_corridor_we_dont_have_a_lot_of_time")
	elif counter == 2:
		neon_sign.visible = true
		MonologueSystem.play_monologue("T_you_should_stop")
	elif counter == 4:
		MonologueSystem.play_monologue("T_last_warning")
	elif counter >= 7:
		can_interact = false
		MonologueSystem.play_monologue("T_youre_cooked")
		await MonologueSystem.monologue_finished
		await get_tree().create_timer(1.0).timeout
		LoadingScreen.start(3, "Айайяй, Игрик.")
		await get_tree().create_timer(3.0).timeout
		LoadingScreen.allow_fade_out()
		get_tree().change_scene_to_packed(preload("res://Scenes/punishment_room.tscn"))
	else:
		pass
	counter += 1
	
