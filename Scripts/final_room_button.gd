extends Interactable

var is_loading = false # Add a guard variable

func _ready():
	super._ready()

func perform_interaction():
	# If we are already loading, stop right here!
	if is_loading:
		return
		
	is_loading = true
	
	LoadingScreen.start(3, "Шоутайм!")
	
	# Create a reference to the tree BEFORE the await
	var tree = get_tree()
	
	await tree.create_timer(2.7).timeout
	
	# Safety check: ensure the tree still exists
	if tree:
		tree.change_scene_to_file("res://Scenes/level_editor.tscn")
	
	LoadingScreen.allow_fade_out()
