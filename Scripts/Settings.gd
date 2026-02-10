extends Node

const CONFIG_PATH := "user://settings.cfg"

var default_settings := {
	"graphics": {
		"resolution": "1920x1080",
		"fullscreen": "Оконный",
		"vsync": true,
		"fps_limit": 60
	},
	"sound": {
		"volume": 1.0,
		"mute": false
	},
	"misc": {
		"monday_mode": false,
		"slippery_world": false,
		"gravity": "Нормальная",
		"temperature": "26с"
	}
}

var settings := {}
var slippery_physics_material: PhysicsMaterial # Новое: материал для скользкого мира
var original_physics_materials: Dictionary = {}

func _ready():
	load_settings()
	apply_all_settings()
	
	slippery_physics_material = PhysicsMaterial.new()
	slippery_physics_material.friction = 0.1  # Очень низкое трение
	slippery_physics_material.rough = true    # Включить грубость поверхности
	slippery_physics_material.bounce = 0.05   # Минимальный отскок

# -------------------
# Load / Save
# -------------------

func load_settings():
	var cfg := ConfigFile.new()
	var err := cfg.load(CONFIG_PATH)

	settings = default_settings.duplicate(true)

	if err != OK:
		return

	for section in cfg.get_sections():
		for key in cfg.get_section_keys(section):
			settings[section][key] = cfg.get_value(section, key)

func save_settings():
	var cfg := ConfigFile.new()

	for section in settings.keys():
		for key in settings[section].keys():
			cfg.set_value(section, key, settings[section][key])

	cfg.save(CONFIG_PATH)

# -------------------
# Apply all
# -------------------

func apply_all_settings():
	apply_graphics()
	apply_sound()
	apply_misc()

# -------------------
# Graphics
# -------------------

func apply_graphics():
	var res: String = settings["graphics"]["resolution"]
	var fullscreen_mode: String = settings["graphics"]["fullscreen"]
	var vsync_enabled: bool = settings["graphics"]["vsync"]
	var fps_limit = settings["graphics"]["fps_limit"]

	var parts = res.split("x")
	if parts.size() == 2:
		var w = int(parts[0])
		var h = int(parts[1])
		DisplayServer.window_set_size(Vector2i(w, h))

	match fullscreen_mode:
		"Полноэкранный":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		"Оконный":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		"Безрамочный":
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync_enabled else DisplayServer.VSYNC_DISABLED
	)


	if typeof(fps_limit) == TYPE_STRING and fps_limit == "Нет лимита":
		Engine.max_fps = 0
	else:
		Engine.max_fps = int(fps_limit)


# -------------------
# Sound
# -------------------

func apply_sound():
	var volume = settings["sound"]["volume"]
	var mute = settings["sound"]["mute"]

	var bus_index := AudioServer.get_bus_index("Master")

	AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume))
	AudioServer.set_bus_mute(bus_index, mute)

# -------------------
# Misc
# -------------------

func apply_misc():
	if settings["misc"]["monday_mode"]:
		print("Monday mode ON")

	if settings["misc"]["slippery_world"]:
		print("Slippery world ON")

	match settings["misc"]["gravity"]:
		"Низкая":
			ProjectSettings.set_setting("physics/3d/default_gravity", 200)
		"Нормальная":
			ProjectSettings.set_setting("physics/3d/default_gravity", 400)
		"Солнце":
			ProjectSettings.set_setting("physics/3d/default_gravity", 1200)
		"Переменная":
			ProjectSettings.set_setting("physics/3d/default_gravity", randi() % 1200)

	print("Температура: ", settings["misc"]["temperature"])
	for p in get_tree().get_nodes_in_group("player"):
		if p.has_method("apply_misc_settings"):
			p.apply_misc_settings()
