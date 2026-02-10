# Создайте новый файл SlipperyFloor.gd
extends StaticBody3D

@export var is_slippery: bool = false

func _ready():
	if Settings.settings["misc"]["slippery_world"]:
		make_slippery()

func make_slippery():
	var material = PhysicsMaterial.new()
	material.friction = 0.2  # Низкое трение
	material.rough = true
	physics_material_override = material
