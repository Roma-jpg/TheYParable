extends Node3D
signal button_pressed
signal button_depressed

@export var required_groups := ["cube", "player"]
@export var press_animation := "push"

@onready var area: Area3D = $Cylinder/Area3D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var press_sound: AudioStreamPlayer3D = $AudioStreamPlayer3D_down
@onready var release_sound: AudioStreamPlayer3D = $AudioStreamPlayer3D_up

var press_count := 0
var is_pressed := false
var player_triggered_once := false
var cube_triggered_once := false
var cube_stay_timer := 0.0
var cube_on_button := false

func _ready():
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _process(delta):
	if cube_on_button and not cube_triggered_once:
		cube_stay_timer += delta
		if cube_stay_timer >= 2.0:
			cube_triggered_once = true
			MonologueSystem.play_and_wait_monologues(["puzzle_room_well_done_1", "puzzle_room_well_done_2", "puzzle_room_well_done_3", "puzzle_room_well_done_4"])

func _on_body_entered(body):
	if _is_valid_presser(body):
		press_count += 1
		_update_state()

	if body.is_in_group("player") and not player_triggered_once:
		player_triggered_once = true
		MonologueSystem.play_and_wait_monologues(["button_pressed_with_player_1", "button_pressed_with_player_2"])
		print("Player stepped on the button (one shot)")

	if body.is_in_group("cube"):
		cube_on_button = true
		cube_stay_timer = 0.0

func _on_body_exited(body):
	if _is_valid_presser(body):
		press_count -= 1
		_update_state()

	if body.is_in_group("cube"):
		cube_on_button = false
		cube_stay_timer = 0.0

func _is_valid_presser(body) -> bool:
	for group in required_groups:
		if body.is_in_group(group):
			return true
	return false

func _update_state():
	if press_count > 0 and not is_pressed:
		_press()
	elif press_count <= 0 and is_pressed:
		_release()

func _press():
	is_pressed = true
	anim.play(press_animation)
	press_sound.play()
	emit_signal("button_pressed")

func _release():
	is_pressed = false
	anim.play_backwards(press_animation)
	release_sound.play()
	emit_signal("button_depressed")
