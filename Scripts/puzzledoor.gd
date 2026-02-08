extends Node3D

@export var button_path: NodePath
@export var door_animation := "opendoor"

@onready var anim: AnimationPlayer = $AnimationPlayer

func _on_batton_button_pressed() -> void:
	anim.play(door_animation)


func _on_batton_button_depressed() -> void:
	anim.play_backwards(door_animation)
