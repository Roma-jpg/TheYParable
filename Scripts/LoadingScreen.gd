
extends Control

signal finished

@export var fade_time: float = 1.0

@onready var progress_bar: ProgressBar = $MarginContainer2/ProgressBar
@onready var advice_label = $MarginContainer/VBoxContainer/Advice

var _estimated_duration: float = 0.0
var _steps: Array[Dictionary] = []
var _current_step: int = 0
var _active: bool = false
var _can_fade_out: bool = false
var rng: RandomNumberGenerator

func _ready() -> void:
	hide()
	modulate.a = 0.0
	progress_bar.value = 0
	top_level = true
	z_index = 100

func start(duration: float, advice_text: String) -> void:
	_hide_player_ui()
	_lock_player_controls()
	
	_estimated_duration = max(duration, 0.1)
	advice_label.text = advice_text
	progress_bar.value = 0
	_steps.clear()
	_current_step = 0
	_active = false
	_can_fade_out = false
	
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	show()
	await _fade_in()
	
	_prepare_fake_progress()
	_active = true

func _process(delta: float) -> void:
	if not _active or _current_step >= _steps.size():
		return
	
	var step = _steps[_current_step]
	step.time_left -= delta
	_steps[_current_step] = step
	
	if step.time_left <= 0.0:
		_animate_progress(step)
		_current_step += 1

func allow_fade_out() -> void:
	if _can_fade_out:
		return
	
	_can_fade_out = true
	_active = false  # Stop any further step processing
	
	# Snappy finish: quick jump to 100% if not there yet
	if progress_bar.value < 100.0:
		var quick_duration: float = rng.randf_range(0.2, 0.5)
		var tween = create_tween()
		tween.tween_property(progress_bar, "value", 100.0, quick_duration)
		tween.set_trans(Tween.TRANS_CUBIC)
		tween.set_ease(Tween.EASE_OUT)
		await tween.finished
	
	await _fade_out()
	_show_player_ui()
	_unlock_player_controls()
	finished.emit()
	hide()

# -------------------------
# Internals
# -------------------------
func _prepare_fake_progress() -> void:
	var num_steps: int = rng.randi_range(8, 14)
	var remaining_time: float = _estimated_duration
	var current_value: float = 0.0
	
	var transitions = [Tween.TRANS_LINEAR, Tween.TRANS_SINE, Tween.TRANS_QUAD, Tween.TRANS_CUBIC, Tween.TRANS_QUINT]
	var eases = [Tween.EASE_IN, Tween.EASE_OUT, Tween.EASE_IN_OUT]
	
	for i in num_steps:
		var steps_left: int = num_steps - i
		var base_wait: float = remaining_time / max(steps_left, 1)
		var wait: float = rng.randf_range(base_wait * 0.4, base_wait * 1.8)
		wait = max(wait, 0.1)
		
		# Occasional longer stall for realism
		if rng.randf() < 0.15:
			wait += rng.randf_range(0.4, 1.0)
		
		# Progress increment – bigger jumps early, smaller near end
		var increment_factor: float = rng.randf_range(0.07, 0.20)
		if current_value > 60.0:
			increment_factor *= rng.randf_range(0.3, 0.7)  # Slow down near end
		
		var target: float = current_value + increment_factor * 100.0
		target = min(target, 100.0)
		
		var tween_duration: float = rng.randf_range(0.15, 0.45)  # Snappy tweens
		
		_steps.append({
			"time_left": wait,
			"target_value": target,
			"tween_duration": tween_duration,
			"trans": transitions.pick_random(),
			"ease": eases.pick_random()
		})
		
		remaining_time -= wait
		current_value = target
	
	# Force last step to exactly 100%
	if not _steps.is_empty():
		_steps[-1].target_value = 100.0

func _animate_progress(step: Dictionary) -> void:
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", step.target_value, step.tween_duration)
	tween.set_trans(step.trans)
	tween.set_ease(step.ease)

func _fade_in() -> void:
	if fade_time <= 0.0:
		modulate.a = 1.0
		return
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_time)
	await tween.finished

func _fade_out() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, fade_time)
	await tween.finished

func _lock_player_controls() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("lock_controls"):
			p.lock_controls()

func _unlock_player_controls() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("unlock_controls"):
			p.unlock_controls()

func _hide_player_ui() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("hide_game_ui"):
			p.hide_game_ui()

func _show_player_ui() -> void:
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("show_game_ui"):
			p.show_game_ui()
