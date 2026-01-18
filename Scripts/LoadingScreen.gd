extends Control

signal finished

@export var fade_time := 1.0

@onready var progress_bar: ProgressBar = $MarginContainer2/ProgressBar
@onready var advice_label = $MarginContainer/VBoxContainer/Advice

var _estimated_duration := 0.0
var _steps := []
var _current_step := 0
var _active := false
var _can_fade_out := false

func _ready():
	hide()
	modulate.a = 0.0
	progress_bar.value = 0
	top_level = true
	z_index = 10_000

func start(duration: float, advice_text: String):
	_hide_player_ui()
	_lock_player_controls()

	_estimated_duration = max(duration, 0.1)
	advice_label.text = advice_text
	progress_bar.value = 0

	_active = false
	_can_fade_out = false
	_steps.clear()
	_current_step = 0

	show()
	await _fade_in()
	_prepare_fake_progress()
	_active = true



func _process(delta):
	if not _active:
		return

	if _current_step >= _steps.size():
		return

	var step = _steps[_current_step]
	step.time_left -= delta
	_steps[_current_step] = step

	if step.time_left <= 0.0:
		_animate_progress(step.target_value)
		_current_step += 1

func allow_fade_out():
	if not _can_fade_out:
		_can_fade_out = true
		await _fade_out()
		_show_player_ui()
		_unlock_player_controls()
		emit_signal("finished")
		hide()


# -------------------------
# Internals
# -------------------------

func _prepare_fake_progress():
	var remaining_time = _estimated_duration
	var current_value = 0.0

	for i in 5:
		var steps_left = 5 - i
		var max_wait = remaining_time - (steps_left * 0.2)
		var wait = randf_range(0.2, max_wait / steps_left)

		var target = lerp(current_value, 100.0, randf_range(0.12, 0.28))
		target = min(target, 100.0)

		_steps.append({
			"time_left": wait,
			"target_value": target
		})

		remaining_time -= wait
		current_value = target

	_steps[-1].target_value = 100.0

func _animate_progress(target: float):
	var tween = create_tween()
	tween.tween_property(
		progress_bar,
		"value",
		target,
		0.4
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _fade_in():
	if fade_time <= 0.0:
		modulate.a = 1.0
		return
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time)
	await tween.finished


func _fade_out():
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	await tween.finished


func _lock_player_controls():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("lock_controls"):
			p.lock_controls()

func _unlock_player_controls():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("unlock_controls"):
			p.unlock_controls()

func _hide_player_ui():
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("hide_game_ui"):
			p.hide_game_ui()

func _show_player_ui():
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("show_game_ui"):
			p.show_game_ui()
