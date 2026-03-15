extends Control

@export var speed = 140
@onready var scroll_container: ScrollContainer = $ScrollContainer
@onready var music: AudioStreamPlayer2D = $AudioStreamPlayer2D

func _ready() -> void:
	scroll_container.scroll_vertical = 0
	music.play()

func _process(delta: float) -> void:
	await get_tree().create_timer(3).timeout
	scroll_container.scroll_vertical += speed * delta
	
	if scroll_container.scroll_vertical >= 7860:
		get_tree().quit()
	
