extends Node

# Dictionary to store your overlay scenes
# Format: {"slide_name": preload("res://path.tscn")}
var slide_library = {}

# Reference to the current slide being shown
var current_slide = null

func _ready():
	# Preload your slides here, or register them from elsewhere
	register_slide("materials", preload("res://Scenes/Overlays/how_materials_work.tscn"))
	# Add all your slides here

# Public function to register slides dynamically
func register_slide(slide_name: String, slide_scene: PackedScene):
	slide_library[slide_name] = slide_scene

# Main function to show a slide
func show_slide(slide_name: String):
	# Check if slide exists
	if not slide_name in slide_library:
		push_error("Slide not found: ", slide_name)
		return
	
	# Don't show if already showing one
	if current_slide != null:
		return
	
	# Pause the game
	get_tree().paused = true
	
	# Instantiate the slide
	var slide_scene = slide_library[slide_name]
	var slide_instance = slide_scene.instantiate()
	
	# Add to scene tree
	get_tree().root.add_child(slide_instance)
	current_slide = slide_instance
	
	# Connect to its closed signal
	slide_instance.slide_closed.connect(_on_slide_closed.bind(slide_instance))

# When slide is closed
func _on_slide_closed(slide_instance):
	# Unpause the game
	get_tree().paused = false
	
	# Remove reference
	if current_slide == slide_instance:
		current_slide = null

# Helper function to check if a slide is showing
func is_showing() -> bool:
	return current_slide != null

# Force close current slide (emergency)
func close_current_slide():
	if current_slide:
		current_slide._on_dismiss_pressed()
