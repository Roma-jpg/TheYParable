extends CanvasLayer

@onready var animation_player = $AnimationPlayer
@onready var dismiss_button = $BGDimmer/DismissButton

# Signals this slide can emit
signal slide_closed(closed_by_next)
signal next_requested()

# Configuration - set from outside
var closable: bool = true
var allow_next: bool = false
var is_sequence_slide: bool = false

var is_closing = false

func _ready():
	# Connect the dismiss button
	if dismiss_button:
		dismiss_button.pressed.connect(_on_dismiss_pressed)
		dismiss_button.visible = closable and not is_sequence_slide
	
	# Start fade in animation
	if animation_player:
		animation_player.play("fade_in")
	
	# Make sure our UI processes even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Connect animation finished signal
	if animation_player:
		animation_player.animation_finished.connect(_on_animation_finished)

func configure_slide(is_closable: bool, can_go_next: bool = false, in_sequence: bool = false):
	closable = is_closable
	allow_next = can_go_next
	is_sequence_slide = in_sequence
	
	if dismiss_button:
		dismiss_button.visible = closable and not is_sequence_slide

func _on_dismiss_pressed():
	# Prevent multiple calls
	if is_closing:
		return
	
	if not closable:
		return
	
	is_closing = true
	
	# Play fade out animation
	if animation_player:
		animation_player.play("fade_out")
	slide_closed.emit(false)  # false = not closed by next button

func close_slide(by_next: bool = false):
	if is_closing:
		return
	
	is_closing = true
	
	# Play fade out animation
	if animation_player:
		animation_player.play("fade_out")
	slide_closed.emit(by_next)

func _on_animation_finished(anim_name):
	if anim_name == "fade_out":
		# Remove the slide after fade out
		queue_free()

func _input(event):
	# Check for Escape key press (close)
	if event.is_action_pressed("ui_cancel") and not is_closing:
		if closable:
			_on_dismiss_pressed()
			get_viewport().set_input_as_handled()
	
	# Check for Next action (space/enter/gamepad button)
	if allow_next and event.is_action_pressed("ui_accept") and not is_closing:
		if is_sequence_slide:
			close_slide(true)  # true = closed by next button
			next_requested.emit()
		elif closable:
			close_slide(true)

# Also handle gamepad and other inputs
func _process(delta):
	# Check for Escape key
	if Input.is_action_just_pressed("ui_cancel") and not is_closing:
		if closable:
			_on_dismiss_pressed()
	
	# Check for Next action
	if allow_next and Input.is_action_just_pressed("ui_accept") and not is_closing:
		if is_sequence_slide:
			close_slide(true)
			next_requested.emit()
		elif closable:
			close_slide(true)
