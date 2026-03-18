extends Node3D

@onready var animation_player: AnimationPlayer = $CanvasLayer/AnimationPlayer

func _ready():
	$CanvasLayer/Control/ColorRect.modulate = Color("ffffff00")
	$CanvasLayer/Control/Sprite2D.visible = false

func _on_area_3d_body_entered(body: CharacterBody3D) -> void:
	if body.is_in_group("player"):
		MonologueSystem.stop_monologue()
		MonologueSystem.clear_queue()
		MonologueSystem.play_monologue("T_good_job")
		await MonologueSystem.monologue_finished
		await get_tree().create_timer(1).timeout
		animation_player.play("fade_in")
		await animation_player.animation_finished
		#await get_tree().create_timer(2).timeout
		await MonologueSystem.play_and_wait_monologues(["outro_final_1", "outro_license_1"])
		$CanvasLayer/Control/Sprite2D.visible = true
		await MonologueSystem.play_and_wait_monologues(["outro_license_2"])
		await get_tree().create_timer(15).timeout
		await MonologueSystem.play_and_wait_monologues(["outro_final_2"])
		await get_tree().create_timer(2).timeout
		get_tree().change_scene_to_file("res://Scenes/credits.tscn")
		
