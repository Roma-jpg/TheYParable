extends Interactable

@export var interaction_count: int = 0

func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = "[E]Cube"

func perform_interaction():
	# Increment counter
	interaction_count += 1
	
	# Print to console
	print("[CUBE] Interaction #" + str(interaction_count) + " with: ", name)
	print("  Position: ", global_position)
	print("  Parent body: ", get_parent().name if get_parent() else "None")
	
	# Update the UI text
	update_interaction_text()
	
	# Optional: Print more debug info
	var parent_body = get_parent() as RigidBody3D
	if parent_body:
		print("  Parent scale: ", parent_body.scale)
		print("  Parent rotation: ", parent_body.rotation_degrees)
