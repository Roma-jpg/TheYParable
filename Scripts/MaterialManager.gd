extends Node

var white_material: StandardMaterial3D = null
var original_materials: Dictionary = {}  # MeshInstance3D -> original override

func _ready():
	white_material = StandardMaterial3D.new()
	white_material.albedo_color = Color.WHITE
	white_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	white_material.roughness = 1.0
	white_material.metallic = 0.0

func make_objects_white():
	if not original_materials.is_empty():
		return  # Already applied
	
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.is_empty():
		printerr("No player in group 'player'")
		return
	var player = player_nodes[0]
	
	var scene_root = get_tree().current_scene
	if not scene_root:
		printerr("No current scene")
		return
	
	var all_meshes = scene_root.find_children("*", "MeshInstance3D", true, true)
	for mesh in all_meshes:
		if player.is_ancestor_of(mesh):
			continue
		original_materials[mesh] = mesh.material_override
		mesh.material_override = white_material

func revert_objects():
	for mesh in original_materials.keys():
		mesh.material_override = original_materials[mesh]
	original_materials.clear()
