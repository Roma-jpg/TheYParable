extends Control

@onready var interaction_label: Label = $MarginContainer/InteractionLabel

func _ready():
	hide()  # Start hidden

func show_interaction(text: String):
	print("[UI] Showing: ", text)
	interaction_label.text = text
	show()

func hide_interaction():
	print("[UI] Hiding")
	interaction_label.text = ""
	hide()
