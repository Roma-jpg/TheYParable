extends CanvasLayer

@onready var animation_player = $AnimationPlayer
@onready var dismiss_button = $BGDimmer/DismissButton

# Signals this slide can emit
signal slide_closed

var is_closing = false

func _ready():
	# Connect the dismiss button
	dismiss_button.pressed.connect(_on_dismiss_pressed)
	
	# Start fade in animation
	animation_player.play("fade_in")
	
	# Make sure our UI processes even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS  # Changed to ALWAYS
	
	# Connect animation finished signal
	animation_player.animation_finished.connect(_on_animation_finished)

func _on_dismiss_pressed():
	# Prevent multiple calls
	if is_closing:
		return
	
	is_closing = true
	
	# Play fade out animation
	animation_player.play("fade_out")
	slide_closed.emit()

func _on_animation_finished(anim_name):
	if anim_name == "fade_out":
		# Remove the slide after fade out
		queue_free()

# Use _input instead of _unhandled_input to catch ALL input
func _input(event):
	# Check for Escape key press
	if event.is_action_pressed("ui_cancel") and not is_closing:
		_on_dismiss_pressed()
		# Mark the input as handled to prevent other systems from using it
		get_viewport().set_input_as_handled()

# Also handle gamepad and other inputs
func _process(delta):
	# Check for any "cancel" input each frame (more reliable)
	if Input.is_action_just_pressed("ui_cancel") and not is_closing:
		_on_dismiss_pressed()

# Optional: Also close on Escape key
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):  # Escape key
		_on_dismiss_pressed()
		get_viewport().set_input_as_handled()
