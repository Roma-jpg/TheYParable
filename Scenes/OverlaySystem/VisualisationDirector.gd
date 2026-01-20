extends Node

# Dictionary to store your overlay scenes
var slide_library = {}

# Reference to the current slide being shown
var current_slide = null

# Sequence management
var current_sequence: Array = []
var sequence_index: int = -1
var sequence_closable: bool = true

func _ready():
	# Preload your slides here, or register them from elsewhere
	register_slide("materials", preload("res://Scenes/Overlays/how_materials_work.tscn"))
	#register_slide("textures", preload("res://Scenes/Overlays/texture_tutorial.tscn"))
	#register_slide("importance-of-both", preload("res://Scenes/Overlays/importance_of_both.tscn"))
	# Add all your slides here

# Public function to register slides dynamically
func register_slide(slide_name: String, slide_scene: PackedScene):
	slide_library[slide_name] = slide_scene

# Main function to show a slide - now supports both single slide and sequence
func show_slide(slide_name, closable: bool = true, allow_next: bool = false):
	# Check if it's a sequence (array) or single slide
	if slide_name is Array:
		_show_sequence(slide_name, closable)
	else:
		_show_single_slide(slide_name, closable, allow_next)

# Show a single slide
func _show_single_slide(slide_name: String, closable: bool = true, allow_next: bool = false):
	# Check if slide exists
	if not slide_name in slide_library:
		push_error("Slide not found: ", slide_name)
		return
	
	# Don't show if already showing one (unless it's part of a sequence)
	if current_slide != null and sequence_index == -1:
		return
	
	# Pause the game
	get_tree().paused = true
	
	# Instantiate the slide
	var slide_scene = slide_library[slide_name]
	var slide_instance = slide_scene.instantiate()
	
	# Configure the slide
	slide_instance.configure_slide(closable, allow_next, false)
	
	# Add to scene tree
	get_tree().root.add_child(slide_instance)
	current_slide = slide_instance
	
	# Connect to its closed signal
	slide_instance.slide_closed.connect(_on_slide_closed.bind(slide_instance))

# Show a sequence of slides
func _show_sequence(slide_names: Array, closable: bool = true):
	if slide_names.is_empty():
		return
	
	# Initialize sequence
	current_sequence = slide_names
	sequence_index = 0
	sequence_closable = closable
	
	# Show first slide in sequence
	var first_slide = slide_names[0]
	_show_sequence_slide(first_slide, 0 == slide_names.size() - 1)

func _show_sequence_slide(slide_name: String, is_last: bool):
	if not slide_name in slide_library:
		push_error("Slide not found in sequence: ", slide_name)
		_advance_sequence()
		return
	
	# Instantiate the slide
	var slide_scene = slide_library[slide_name]
	var slide_instance = slide_scene.instantiate()
	
	# Configure slide for sequence:
	# - If it's the last slide, respect the original closable setting
	# - Otherwise, only closable if sequence_closable is true
	# - Allow next button unless it's the last slide with closable=false
	var slide_closable = sequence_closable
	var allow_next = true
	
	if is_last:
		slide_closable = sequence_closable
		allow_next = sequence_closable  # Only allow next if closable
	
	slide_instance.configure_slide(slide_closable, allow_next, not is_last)
	
	# Add to scene tree
	get_tree().root.add_child(slide_instance)
	current_slide = slide_instance
	
	# Connect signals
	slide_instance.slide_closed.connect(_on_slide_closed.bind(slide_instance))
	
	# If not last slide, also connect next_requested
	if not is_last:
		slide_instance.next_requested.connect(_advance_sequence)

# When slide is closed
func _on_slide_closed(closed_by_next: bool, slide_instance):
	# If this was a sequence slide and we closed by next button, advance
	if sequence_index >= 0 and closed_by_next:
		_advance_sequence()
	else:
		# Otherwise, just clean up
		_cleanup_slide(slide_instance)

func _advance_sequence():
	if sequence_index >= 0:
		sequence_index += 1
		
		if sequence_index < current_sequence.size():
			# Show next slide in sequence
			var next_slide_name = current_sequence[sequence_index]
			var is_last = (sequence_index == current_sequence.size() - 1)
			_show_sequence_slide(next_slide_name, is_last)
		else:
			# End of sequence
			_cleanup_sequence()

func _cleanup_slide(slide_instance):
	# Unpause the game
	get_tree().paused = false
	
	# Remove reference
	if current_slide == slide_instance:
		current_slide = null

func _cleanup_sequence():
	sequence_index = -1
	current_sequence = []
	get_tree().paused = false
	current_slide = null

# Helper function to check if a slide is showing
func is_showing() -> bool:
	return current_slide != null

# Force close current slide (emergency)
func close_current_slide():
	if current_slide:
		current_slide.close_slide()
		_cleanup_sequence()

# Skip to next slide in sequence
func next_in_sequence():
	if sequence_index >= 0 and current_slide:
		current_slide.close_slide(true)

# Jump to specific slide in current sequence
func jump_to_sequence_index(index: int):
	if sequence_index >= 0 and index >= 0 and index < current_sequence.size():
		# Close current slide without advancing
		if current_slide:
			current_slide.queue_free()
			current_slide = null
		
		sequence_index = index
		var is_last = (sequence_index == current_sequence.size() - 1)
		_show_sequence_slide(current_sequence[sequence_index], is_last)
