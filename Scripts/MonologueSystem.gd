extends Node

## Система управления монологами с аудио и субтитрами
## Использование: MonologueSystem.play_monologue("intro_1a")

# Сигналы системы
signal monologue_started(key)
signal monologue_finished(key)
signal subtitle_changed(text)
signal audio_progress(progress, duration)

# Настройки
var subtitle_prefix: String = "Диктор: "
var audio_folder: String = "res://Assets/Audio/Monologues/"
var subtitles_enabled: bool = true
var auto_advance: bool = true

# Текущий монолог
var current_key: String = ""
var current_audio: AudioStreamPlayer
var is_playing: bool = false

# Словари для данных
var monologues: Dictionary = {}
var audio_queue: Array = []

# Настройки формата субтитров
var subtitle_settings = {
	"font_size": 24,
	"font_color": Color.WHITE,
	"background_color": Color(0, 0, 0, 0.7),
	"duration_multiplier": 1.2, # Множитель длительности для текста
}

# Конфигурация аудио
var audio_config = {
	"volume_db": -5.0,
	"pitch_scale": 1.0,
	"bus": "Master"
}

func _ready():
	setup_audio_player()
	load_monologues()
	
func setup_audio_player():
	"""Настройка аудиоплеера"""
	current_audio = AudioStreamPlayer.new()
	current_audio.name = "MonologueAudioPlayer"
	current_audio.bus = audio_config["bus"]
	current_audio.finished.connect(_on_audio_finished)
	add_child(current_audio)

func load_monologues():
	"""Загрузка монологов (можно переопределить)"""
	# Пример заполнения - можно загружать из JSON или других источников
	monologues = {
		"1a_now_you_can_move": "Вот, теперь ты можешь двигаться.",
		"1a_no_anim": "А, точно, у тебя же еще нету анимации. Секунду.",
		"1a_Y_wake_up": "Игрик, просыпайся. У нас сегодня много дел.",
		"1a_see_that_camera": "Видишь вон ту камеру на тумбочке? Подойди к ней и надень ее на голову."
	}
	print("Монологи загружены: ", monologues.size(), " записей")

func add_monologue(key: String, text: String):
	"""Добавить монолог вручную"""
	monologues[key] = text

func remove_monologue(key: String):
	"""Удалить монолог"""
	monologues.erase(key)

func play_monologue(key: String, force: bool = false) -> bool:
	"""Воспроизвести монолог по ключу"""
	
	if not monologues.has(key):
		push_error("Монолог с ключом '%s' не найден!" % key)
		return false
	
	if is_playing and not force:
		# Добавляем в очередь или прерываем в зависимости от настроек
		if auto_advance:
			audio_queue.append(key)
			print("Добавлено в очередь: ", key)
			return true
		else:
			stop_monologue()
	
	current_key = key
	var text = monologues[key]
	var audio_path = audio_folder + key
	
	# Поиск аудиофайла с различными расширениями
	var audio_extensions = [".wav", ".mp3", ".ogg"]
	var audio_stream = null
	
	for ext in audio_extensions:
		var full_path = audio_path + ext
		if ResourceLoader.exists(full_path):
			audio_stream = load(full_path)
			break
	
	if audio_stream:
		current_audio.stream = audio_stream
		current_audio.volume_db = audio_config["volume_db"]
		current_audio.pitch_scale = audio_config["pitch_scale"]
		current_audio.play()
		is_playing = true
		
		# Показываем субтитры
		if subtitles_enabled:
			show_subtitle(text)
		
		monologue_started.emit(key)
		print("Воспроизведение: ", key)
		return true
	else:
		push_warning("Аудиофайл не найден для ключа: %s" % key)
		# Воспроизводим только текст, если нет аудио
		if subtitles_enabled:
			show_subtitle(text)
		monologue_started.emit(key)
		monologue_finished.emit(key)
		return true

func show_subtitle(text: String):
	"""Показать субтитры с префиксом"""
	var full_text = subtitle_prefix + text
	subtitle_changed.emit(full_text)
	
	# Автоматическое скрытие через время (если нет аудио)
	if not current_audio.playing:
		var duration = calculate_subtitle_duration(text)
		create_timer(duration).timeout.connect(_hide_subtitle, CONNECT_ONE_SHOT)

func calculate_subtitle_duration(text: String) -> float:
	"""Рассчитать длительность показа субтитра на основе текста"""
	var words = text.split(" ").size()
	var base_time = words * 0.5	# 0.5 секунды на слово
	return clamp(base_time * subtitle_settings["duration_multiplier"], 2.0, 10.0)

func create_timer(duration: float) -> Timer:
	"""Создать одноразовый таймер"""
	var timer = Timer.new()
	timer.wait_time = duration
	timer.one_shot = true
	add_child(timer)
	timer.start()
	return timer

func stop_monologue():
	"""Остановить текущий монолог"""
	if is_playing:
		current_audio.stop()
		is_playing = false
		_hide_subtitle()
		print("Монолог остановлен: ", current_key)

func skip_monologue():
	"""Пропустить текущий монолог"""
	if is_playing:
		current_audio.stop()
		_on_audio_finished()

func pause_monologue():
	"""Приостановить монолог"""
	if current_audio.playing:
		current_audio.stream_paused = true

func resume_monologue():
	"""Возобновить монолог"""
	if is_playing and current_audio.stream_paused:
		current_audio.stream_paused = false

func _on_audio_finished():
	"""Обработчик завершения аудио"""
	if is_playing:
		is_playing = false
		_hide_subtitle()
		monologue_finished.emit(current_key)
		print("Монолог завершен: ", current_key)
		
		# Воспроизвести следующий из очереди
		if audio_queue.size() > 0:
			var next_key = audio_queue.pop_front()
			await get_tree().create_timer(0.5).timeout
			play_monologue(next_key)

func _hide_subtitle():
	"""Скрыть субтитры"""
	subtitle_changed.emit("")

func play_sequence(keys: Array):
	"""Воспроизвести последовательность монологов"""
	if keys.size() == 0:
		return
	
	audio_queue.clear()
	
	# Добавляем все, кроме первого, в очередь
	for i in range(1, keys.size()):
		audio_queue.append(keys[i])
	
	# Запускаем первый
	play_monologue(keys[0])

func get_remaining_time() -> float:
	"""Получить оставшееся время текущего монолога"""
	if not is_playing or not current_audio.stream:
		return 0.0
	return current_audio.stream.get_length() - current_audio.get_playback_position()

func set_volume(volume_db: float):
	"""Установить громкость"""
	audio_config["volume_db"] = volume_db
	if current_audio:
		current_audio.volume_db = volume_db

func is_monologue_available(key: String) -> bool:
	"""Проверить, доступен ли монолог"""
	return monologues.has(key)

func clear_queue():
	"""Очистить очередь воспроизведения"""
	audio_queue.clear()

# Функции для дебага
func print_all_monologues():
	"""Вывести все доступные монологи"""
	print("=== Доступные монологи ===")
	for key in monologues.keys():
		print("%s: %s" % [key, monologues[key]])
	print("==========================")

func _process(_delta):
	"""Отслеживание прогресса воспроизведения"""
	if is_playing and current_audio.stream:
		var progress = current_audio.get_playback_position()
		var duration = current_audio.stream.get_length()
		audio_progress.emit(progress, duration)
