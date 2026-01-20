extends Node

# Signals
signal monologue_started(key: String)
signal monologue_finished(key: String)
signal subtitle_changed(text: String)

# Settings
var subtitle_prefix: String = "Диктор: "
var audio_folder: String = "res://Assets/Audio/Monologues/"
var subtitles_enabled: bool = true
var auto_advance: bool = true

# Data
var monologues: Dictionary = {}
var audio_queue: Array[String] = []

# Audio player
var current_audio: AudioStreamPlayer
var current_key: String = ""
var is_playing: bool = false

# Subtitle settings
var subtitle_settings = {
	"duration_multiplier": 1.2,
}

# Audio config
var audio_config = {
	"volume_db": -5.0,
	"pitch_scale": 1.0,
	"bus": "Master"
}

func _ready() -> void:
	setup_audio_player()
	load_base_monologues()
	load_monologues_from_json("res://data/monologues.json")

func setup_audio_player() -> void:
	current_audio = AudioStreamPlayer.new()
	current_audio.name = "MonologueAudioPlayer"
	current_audio.bus = audio_config["bus"]
	current_audio.finished.connect(_on_audio_finished)
	add_child(current_audio)

func load_base_monologues() -> void:
	monologues = {
		"1a_now_you_can_move": "Вот, теперь ты можешь двигаться.",
		"1a_no_anim": "А, точно, у тебя же еще нету анимации. Секунду.",
		"1a_Y_wake_up": "Игрик, просыпайся. У нас сегодня много дел. Игрик, просыпайся. У нас сегодня много дел. Игрик, просыпайся. У нас сегодня много дел.",
		"1a_see_that_camera": "Видишь вон ту камеру на тумбочке? Подойди к ней и надень ее на голову."
	}

func load_monologues_from_json(path: String) -> void:
	if not FileAccess.file_exists(path):
		create_default_json(path)
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Could not open monologues JSON: ", path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("JSON parse error in monologues: ", json.get_error_message())
		return
	
	var data = json.data
	if data is Dictionary and data.has("monologues"):
		for key in data["monologues"]:
			monologues[key] = data["monologues"][key]

func create_default_json(path: String) -> void:
	var dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir):
		DirAccess.make_dir_recursive_absolute(dir)
	
	var default_data = {
		"monologues": {
			"example_1": "Это пример монолога без аудио файла.",
			"example_2": "Второй пример с более длинным текстом для тестирования длительности субтитров."
		}
	}
	
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(default_data, "\t"))
		file.close()
		print("Created default monologues.json at: ", path)
		load_monologues_from_json(path)  # Reload with defaults
	else:
		push_error("Failed to create default monologues.json")

func play_monologue(key: String, force: bool = false) -> bool:
	if not monologues.has(key):
		push_error("Monologue not found: ", key)
		return false
	
	if is_playing and not force:
		if auto_advance:
			audio_queue.append(key)
			return true
		else:
			return false
	
	stop_monologue()  # Clear any previous
	current_key = key
	var text = monologues[key]
	
	# Try to load audio (priority: ogg > wav > mp3)
	var audio_stream = null
	var extensions = [".ogg", ".wav", ".mp3"]
	for ext in extensions:
		var full_path = audio_folder + key + ext
		if ResourceLoader.exists(full_path):
			audio_stream = load(full_path)
			break
	
	if audio_stream:
		current_audio.stream = audio_stream
		current_audio.volume_db = audio_config["volume_db"]
		current_audio.pitch_scale = audio_config["pitch_scale"]
		current_audio.play()
		is_playing = true
		if subtitles_enabled:
			show_subtitle(text)
		monologue_started.emit(key)
		return true
	else:
		# Text-only mode
		if subtitles_enabled:
			show_subtitle(text)
		monologue_started.emit(key)
		is_playing = true
		
		var duration = calculate_subtitle_duration(text)
		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(_on_text_only_finished.bind(key))
		add_child(timer)
		timer.start()
		return true

func show_subtitle(text: String) -> void:
	var full_text = subtitle_prefix + text
	subtitle_changed.emit(full_text)
	
	# Auto-hide if no audio playing
	if not current_audio.playing:
		var duration = calculate_subtitle_duration(text)
		var timer = Timer.new()
		timer.wait_time = duration
		timer.one_shot = true
		timer.timeout.connect(_hide_subtitle)
		add_child(timer)
		timer.start()

func calculate_subtitle_duration(text: String) -> float:
	var char_count = text.length()
	var duration = char_count * 0.1
	return clamp(duration, 1.5, 15.0)

func _hide_subtitle() -> void:
	subtitle_changed.emit("")

func stop_monologue() -> void:
	if is_playing:
		current_audio.stop()
		is_playing = false
		_hide_subtitle()

func skip_monologue() -> void:
	if is_playing:
		current_audio.stop()
		_on_audio_finished()

func _on_audio_finished() -> void:
	if is_playing:
		is_playing = false
		_hide_subtitle()
		monologue_finished.emit(current_key)
		_play_next_in_queue()

func _on_text_only_finished(key: String) -> void:
	if is_playing and current_key == key:
		is_playing = false
		_hide_subtitle()
		monologue_finished.emit(key)
		_play_next_in_queue()

func _play_next_in_queue() -> void:
	if audio_queue.size() > 0:
		var next_key = audio_queue.pop_front()
		await get_tree().create_timer(0.5).timeout
		play_monologue(next_key)

func play_sequence(keys: Array[String]) -> void:
	if keys.is_empty():
		return
	audio_queue.clear()
	for i in range(1, keys.size()):
		audio_queue.append(keys[i])
	play_monologue(keys[0])

func clear_queue() -> void:
	audio_queue.clear()

func set_volume(volume_db: float) -> void:
	audio_config["volume_db"] = volume_db
	if current_audio:
		current_audio.volume_db = volume_db
