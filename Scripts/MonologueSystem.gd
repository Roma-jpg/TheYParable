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
		"starting_animation_1": "Так-так-так, хорошо. Секунду, компилирую шейдеры, кэширую данные.",
		"starting_animation_2": "Ничего не трогай!",
		"starting_animation_3": "Если увидишь чёрный экран - это нормально.",
		"starting_animation_4": "Фуух, пронесло.",
		"starting_animation_5": "Первый запуск всегда волнительный!",
		"its_alive_1": "Ха-ха, смотрите! Оно живёт! Оно подпрыгивает!",
		"its_alive_2": "Пусть это и просто цикл из трёх кадров анимации, но в этот момент",
		"its_alive_3": "между объектом и создателем рождается связь.",
		"its_alive_4": "Вы теперь - не просто наблюдатель, вы - причина.",
		"its_alive_5": "Запомните это чувство.",
		"1a_Y_wake_up": "Игрик, просыпайся. У нас сегодня много дел.",
		"what_if_u_died_1": "Блиин, а вдруг ты умер? Прямо сейчас ты лежишь с головой на клавиатуре, и тебе никто не может помочь?",
		"what_if_u_died_2": "Блиин, охх.",
		"what_if_u_died_3": "Слушай, просыпайся, просыпайся.",
		"what_if_u_died_4": "Я волнуюсь.",
		"1a_no_anim": "А, точно, у тебя же ещё нет анимации. Секунду.",
		"1a_now_you_can_move": "Вот, теперь ты можешь двигаться.",
		"wow_you_jumped_1": "Вот это да! Ты... прыгнул!",
		"wow_you_jumped_2": "А знаешь, что сейчас только что произошло?",
		"wow_you_jumped_3": "Ты нажал клавишу, ну или кнопку на геймпаде,",
		"wow_you_jumped_4": "и эта команда была привязана к функции jump внутри твоего персонажа.",
		"wow_you_jumped_5": "Функция проверила, находишься ли ты на земле,",
		"wow_you_jumped_6": "и если да, то применила импульс вверх. Физика, Игрик! Не магия, а физика.",
		"are_u_testing_gravity": "Аа, тестируешь гравитацию? Не буду отвлекать.",
		"1a_see_that_camera": "Видишь вон ту камеру на тумбочке? Подойди к ней и надень её на голову.",
		"2a_just_look_at_that": "Ну ты только посмотри на это... Вся твоя комната белая!",
		"2a_adult_joke": "Представить не могу, что ты такого вчера делал, что всё покрылось чем-то белым...",
		"2a_being_serious_now": "Ну а теперь серьёзно.",
		"2a_now_we_will_meet_aspect": "Сейчас мы с вами познакомимся с одним из самых важных аспектов разработки игр - материалами!",
		"2a_materials_expl1": "Материалы, а также их папа - текстуры, выполняют чуть ли не самую важную часть в игре - визуал.",
		"2a_materials_expl2": "Текстуры - это картинки, натянутые на модель, а материалы - процедурно генерируемые объекты.",
		"2a_materials_expl3": "(Если по-простому, то у текстур есть границы, а у материалов нет), но у каждого свои плюсы и минусы.",
		"painting_1": "А вот это - текстура той статуи сзади тебя.",
		"painting_2": "А ты думал, как достигают таких деталей?",
		"painting_3": "Конечно, натягивая 2D-изображение на 3D-фигурку.",
		"error_arthouse_1": "О, а вот это - мой любимый артхаусный материал.",
		"error_arthouse_2": "Эстетика незавершённости...",
		"error_arthouse_3": "Очень модно.",
		"error_arthouse_4": "Хотя, скорее всего, Рома просто забыл перетащить файл в папку.",
		"collision_expl1": "Смотри-ка, Игрик, твой путь преграждают коробки!",
		"collision_expl2": "А знаешь ли ты, почему именно эти коробки не дают тебе пройти?",
		"collision_expl3": "Всё дело в коллизиях!",
		"collision_expl4": "Это такой элемент в играх, который определяет, можешь ли ты пройти куда-либо или нет.",
		"collision_expl5": "Мало кто хочет взять, пройти сквозь стену и упасть в бесконечную бездну.",
		"collision_expl7": "Ну ладно, перепрыгни через коробки.",
		"T_corridor_to_the_left": "Здесь налево.",
		"T_corridor_we_dont_have_a_lot_of_time": "Нет, Игрик, у нас очень мало времени.",
		"T_you_should_stop": "Игрик, тебе пора остановиться. Терпения у меня немного.",
		"T_last_warning": "Игрик, предупреждаю в последний раз, иди налево.",
		"T_youre_cooked": "Ну всё, мне это надоело.",
		"T_good_job": "Молодец, Игрик.",
		"t_corridor_idle_1": "Знаешь, Игрик, левел-дизайн - это искусство лёгкого принуждения.",
		"t_corridor_idle_2": "Мы не запираем дверь. Мы просто ставим здесь яркий фонарь, приятную музыку...",
		"t_corridor_idle_3": "и... ох, смотри-ка, внезапный обрыв справа.",
		"t_corridor_idle_4": "Совершенно случайно, конечно.",
		"t_corridor_idle_5": "Иди налево, Игрик. Налево - к знаниям. Направо - к багу,",
		"t_corridor_idle_6": "из-за которого ты провалишься сквозь текстуры в пустоту.",
		"puzzle_room_intro_1": "Смотри, Игрик. Это - комната-головоломка.",
		"puzzle_room_intro_2": "Здесь тебе нужно взять этот куб и положить его на кнопку, чтобы открыть дверь.",
		"puzzle_room_intro_3": "Здесь используется сразу несколько концептов, которые я хочу тебе объяснить, а пока приступай.",
		"button_pressed_with_player_1": "Смотри-ка, а хорошо ты это придумал! Однако дверь закроется в тот же момент, когда ты уйдёшь с кнопки.",
		"button_pressed_with_player_2": "Думаю, здесь лучше подойдёт кубик.",
		"puzzle_room_well_done_1": "Отличная работа, Игрик! Давай я постараюсь объяснить, что вообще произошло.",
		"puzzle_room_well_done_2": "Когда ты положил кубик на кнопку, кубик коснулся поля кнопки, так называемый Area3D.",
		"puzzle_room_well_done_3": "И скрипт кнопки понял, какой предмет находится на кнопке, и послал сигнал двери, чтобы та открылась через менеджер анимаций.",
		"puzzle_room_well_done_4": "Умно, правда? Ну давай не будем терять времени. В следующую комнату.",
		"puzzle_room_outro_1": "Что же, не хочу врать, Игрик. У нас остаётся очень мало времени. У нас на всё про всё 15 минут, из которых большую часть мы уже потратили.",
		"puzzle_room_outro_2": "Давай я впущу тебя в финальную комнату и... на этом разойдёмся?",
		"puzzle_room_outro_3": "Не бойся, на конец я оставил тебе кое-что очень классное.",
		"somewhat_of_a_redactor_1": "Добро пожаловать в самое святое - подобие редактора.",
		"somewhat_of_a_redactor_2": "Здесь можно попробовать себя в роли Ромы и создать что-то своё.",
		"somewhat_of_a_redactor_3": "Перед вами - редактор уровня.",
		"somewhat_of_a_redactor_4": "Да, базовый, да, без огромной кучи функций, но он сделан с душой.",
		"somewhat_of_a_redactor_5": "Когда закончите, нажмите на кнопку Play, и вы сможете протестировать ваш уровень.",
		"debug_room_1": "Игрик, представляю твоему вниманию. Это - комната тестирования.",
		"debug_room_2": "Это реальный инструмент, который Рома использовал для создания этой игры.",
		"debug_room_3": "Тут вот такие кубики, с которыми можно взаимодействовать,",
		"debug_room_4": "а ещё толкать.",
		"debug_room_5": "Ну и типа там ещё треугольнички разного размера.",
		"final_room_intro1":"Вот, Игрик, ознакомься.",
		"final_room_intro2":"По готовности нажми на красную кнопку сзади тебя и мы начнём.",
		"statue": "Смотри, какая интересная статуя. Я её точно не украл из 3D-маркетплейса.",
		"this_plant_is_so_huge": "Это растение настолько разрослось, что пробило потолок.",
		"try_to_kill_yourself": "А кстати, попробуй упасть вниз!",
		"you_cant_die_in_this_game": "Видал? Ты не можешь умереть в этой игре, поэтому эта игра с рейтингом 0+!",
		"dont_touch_this_closet_1": "Я... не знаю, зачем здесь этот огромный шкаф,",
		"dont_touch_this_closet_2": "но я тебе очень рекомендую его проигнорировать. Пожалуйста.",
		"idle_1": "Игрик, на что ты теоретически можешь смотреть непрерывно 15 минут и не двигаться?",
		"how_could_you_lose_a_cube": "Господи, ну как можно было потерять кубик? Да и ладно, держи ещё один.",
		"anyone_at_the_computer": "Ау, есть кто у компьютера?",
		"u_should_explore_1": "Я, конечно, всё объясняю, но ты тоже не стесняйся экспериментировать.",
		"u_should_explore_2": "Самое интересное в играх - это пробовать делать то, чего от тебя не ждут.",
		"u_should_explore_3": "Иногда это ломает сценарий,",
		"u_should_explore_4": "а иногда открывает секретные комнаты.",
		"penis": "Пенис.",
		"we_should_replace_the_mic_for_real": "Господи, когда мы уже поменяем микрофон? У меня уши кровоточат.",
		"interrupt_oh": "Ох...",
		"as_i_was_saying": "Ну, как я уже говорил...",
		"test_no_audio": "Этот монолог не имеет аудиофайла и будет показываться только в виде субтитров."
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
		load_monologues_from_json(path)
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

	stop_monologue()
	current_key = key
	var text = monologues[key]

	# Try to load audio
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
		# Text-only
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
	# Сначала ждем полсекунды
	await get_tree().create_timer(0.5).timeout
	if is_playing:
		return
	if audio_queue.size() > 0:
		var next_key = audio_queue.pop_front()
		play_monologue(next_key)

func play_sequence(keys: Array[String]) -> void:
	if keys.is_empty():
		return
	audio_queue.clear()
	for i in range(1, keys.size()):
		audio_queue.append(keys[i])
	play_monologue(keys[0])

# НОВАЯ УДОБНАЯ ФУНКЦИЯ — используй её для цепочек
func play_and_wait_monologues(keys: Array[String]) -> void:
	if keys.is_empty():
		return
	audio_queue.clear()
	for i in range(1, keys.size()):
		audio_queue.append(keys[i])
	play_monologue(keys[0])
	for x in range(keys.size()):
		await monologue_finished

func clear_queue() -> void:
	audio_queue.clear()

func set_volume(volume_db: float) -> void:
	audio_config["volume_db"] = volume_db
	if current_audio:
		current_audio.volume_db = volume_db
