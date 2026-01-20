extends Node

# UI Elements
@onready var title: Label = $CanvasLayer/ColorRect/Slide1/HBoxContainer/Title
@onready var subtitle: Label = $CanvasLayer/ColorRect/Slide1/HBoxContainer/Subtitle
@onready var copyright: Label = $CanvasLayer/ColorRect/Slide1/HBoxContainer/Copyright

# Slides
@onready var slides: Array[Control] = [
	$CanvasLayer/ColorRect/Slide1,
	$CanvasLayer/ColorRect/Slide2,
	$CanvasLayer/ColorRect/Slide3
]

# Animation settings
const FADE_TIME := 0.6
const DELAY := 0.2

# Current state
var current_slide := 0
var current_child := 0
var is_presentation_active := true
var can_advance := true

func _ready():
	debug_print_scene_tree()
	# Hide everything initially
	_prepare_slide_1()
	_show_slide(0)
	
	# Start the presentation automatically
	await get_tree().create_timer(0.5).timeout  # Brief delay
	await _auto_play_slide_1()
	
	# Set up input
	set_process_input(true)

func _prepare_slide_1():
	# Hide all UI elements initially
	for node in [title, subtitle, copyright]:
		node.modulate.a = 0.0
		# Don't set visible to false here, let them be visible but transparent

func _show_slide(index: int):
	# Show only the requested slide
	for i in slides.size():
		slides[i].visible = (i == index)
		slides[i].modulate.a = 1.0 if (i == index) else 0.0

func _show_child(slide_index: int, child_index: int):
	var slide = slides[slide_index]
	for i in slide.get_child_count():
		var child = slide.get_child(i)
		child.visible = (i == child_index)
		
		# Fade in the child if it has modulate property
		if child.has_method("set_modulate"):
			var tween = create_tween()
			tween.set_trans(Tween.TRANS_SINE)
			tween.set_ease(Tween.EASE_OUT)
			child.modulate.a = 0.0  # Start transparent
			tween.tween_property(child, "modulate:a", 1.0, FADE_TIME)

func _hide_child(slide_index: int, child_index: int):
	var slide = slides[slide_index]
	if child_index < slide.get_child_count():
		var child = slide.get_child(child_index)
		var tween = create_tween()
		tween.set_trans(Tween.TRANS_SINE)
		tween.set_ease(Tween.EASE_OUT)
		tween.tween_property(child, "modulate:a", 0.0, FADE_TIME)
		await tween.finished
		child.visible = false

func _fade_slide(from_slide: Control, to_slide: Control) -> void:
	to_slide.visible = true
	to_slide.modulate.a = 0.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(from_slide, "modulate:a", 0.0, FADE_TIME)
	tween.tween_property(to_slide, "modulate:a", 1.0, FADE_TIME)

	await tween.finished
	from_slide.visible = false

func _input(event):
	if not is_presentation_active or not can_advance:
		return
		
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE, KEY_ENTER, KEY_RIGHT:
				advance_presentation()
			KEY_LEFT:
				go_back()
			KEY_ESCAPE:
				skip_to_end()
	elif event is InputEventMouseButton and event.pressed:
		advance_presentation()

# === AUTO PLAY SLIDE 1 ===
func _auto_play_slide_1() -> void:
	# Fade in title, subtitle, and copyright automatically
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	
	# Start with title
	tween.tween_property(title, "modulate:a", 1.0, FADE_TIME)
	tween.tween_interval(DELAY)
	
	# Then subtitle
	tween.tween_property(subtitle, "modulate:a", 1.0, FADE_TIME)
	tween.tween_interval(DELAY)
	
	# Then copyright
	tween.tween_property(copyright, "modulate:a", 1.0, FADE_TIME)
	
	await tween.finished
	
	# Show first child of slide 1
	_show_child(0, 0)
	
	# Play first monologue automatically
	can_advance = false
	await play_monologue("0a_hello")
	can_advance = true
	print("Slide 1 intro complete. Press SPACE/ENTER/CLICK to continue.")

# === PUBLIC CONTROL FUNCTIONS ===

func advance_presentation():
	if not can_advance:
		return
		
	can_advance = false
	
	match current_slide:
		0:
			await _handle_slide_1()
		1:
			await _handle_slide_2()
		2:
			await _handle_slide_3()
	
	can_advance = true

func go_back():
	if not can_advance:
		return
		
	can_advance = false
	
	if current_slide > 0:
		# Go to previous slide
		var old_slide = slides[current_slide]
		var new_slide = slides[current_slide - 1]
		await _fade_slide(old_slide, new_slide)
		current_slide -= 1
		current_child = 0
		_show_child(current_slide, 0)
	elif current_child > 0:
		# Go to previous child in current slide
		await _hide_child(current_slide, current_child)
		current_child -= 1
		_show_child(current_slide, current_child)
	
	can_advance = true

func skip_to_end():
	get_tree().change_scene("res://Scenes/start_room.tscn")

func play_monologue(audio_name: String) -> bool:
	MonologueSystem.play_audio_only(audio_name)
	await MonologueSystem.monologue_finished
	return true

# === SLIDE HANDLERS ===

func _handle_slide_1() -> void:
	var slide = slides[0]
	
	# If we've already shown all children of slide 1, move to next slide
	if current_child >= slide.get_child_count() - 1:  # -1 because we already showed child 0
		# Move to slide 2
		await _transition_to_slide(1)
	else:
		# Show next child
		current_child += 1
		_show_child(0, current_child)
		
		# Play corresponding monologue
		match current_child:
			1:
				await play_monologue("0a_you_will_learn")
			2:
				await play_monologue("0a_but_first_theory")
		
		# If this was the last child, prepare for next slide
		if current_child >= slide.get_child_count() - 1:
			print("Slide 1 complete. Press SPACE to continue to Slide 2")

func _handle_slide_2() -> void:
	var slide = slides[1]
	
	if current_child >= slide.get_child_count():
		await _transition_to_slide(2)
	else:
		_show_child(1, current_child)
		
		match current_child:
			0:
				await play_monologue("0a_engine_is")
			1:
				await play_monologue("0a_90s_graphics")
			2:
				await play_monologue("0a_many_engines_exist")
		
		current_child += 1
		
		if current_child >= slide.get_child_count():
			print("Slide 2 complete. Press SPACE to continue to Slide 3")

func _handle_slide_3() -> void:
	var slide = slides[2]
	
	if current_child >= slide.get_child_count():
		await get_tree().create_timer(2.0).timeout
		skip_to_end()
	else:
		_show_child(2, current_child)
		
		match current_child:
			0:
				await play_monologue("0a_I_chose_godot")
			1:
				await play_monologue("0a_godot_is_simple")
			2:
				await play_monologue("0a_intro_done")
				current_child += 1
				print("Presentation complete. Press SPACE to continue to game.")
		
		if current_child < slide.get_child_count():
			current_child += 1

func _transition_to_slide(new_slide_index: int):
	if current_slide < slides.size() - 1:
		var old_slide = slides[current_slide]
		var new_slide = slides[new_slide_index]
		await _fade_slide(old_slide, new_slide)
		current_slide = new_slide_index
		current_child = 0
		_show_child(current_slide, 0)
# Add to your presentation script for debugging
func debug_print_scene_tree():
	print("\n" + "=".repeat(60))
	print("DEBUG: SCENE TREE HIERARCHY")
	print("=".repeat(60))
	_debug_print_node_recursive(get_tree().current_scene, 0, 0)
	print("=".repeat(60) + "\n")

func _debug_print_node_recursive(node: Node, max_depth: int, current_depth: int, indent: String = ""):
	if current_depth > max_depth:
		return
	
	var node_prefix = "├── "
	if node.get_child_count() == 0:
		node_prefix = "└── "
	
	var visible_str = ""
	if node is CanvasItem:
		visible_str = " [Visible: %s]" % node.visible
		if node.has_method("get_modulate"):
			visible_str += " [Alpha: %.2f]" % node.modulate.a
	
	var node_info = "%s%s%s (%s)%s" % [indent, node_prefix, node.name, node.get_class(), visible_str]
	print(node_info)
	
	for i in range(node.get_child_count()):
		var child = node.get_child(i)
		var is_last = (i == node.get_child_count() - 1)
		var new_indent = indent + ("    " if is_last else "│   ")
		_debug_print_node_recursive(child, max_depth, current_depth + 1, new_indent)
