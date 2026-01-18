extends Node

# Preload or instance the white material
var white_material: StandardMaterial3D = null
var original_materials: Dictionary = {}  # MeshInstance3D -> original Material

func _ready():
	white_material = StandardMaterial3D.new()
	white_material.albedo_color = Color.WHITE
	white_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL	# ← this is what you want for pure flat color
	white_material.vertex_color_use_as_albedo = false
	# Optional: disable all maps/textures just in case
	white_material.albedo_texture = null
	white_material.normal_enabled = false
	white_material.roughness = 1.0
	white_material.metallic = 0.0

# Function to apply white override to all non-player meshes
func make_objects_white():
	print("making objects white.")
	if not original_materials.is_empty():
		return	# Already applied; call revert first if needed
	
	var player_nodes = get_tree().get_nodes_in_group("player")
	if player_nodes.is_empty():
		printerr("No player found in group 'player'")
		return
	
	var player = player_nodes[0]	# Assuming one player
	
	var scene_root = get_tree().current_scene
	if not scene_root:
		printerr("No current scene yet!")
		return

	var all_meshes = scene_root.find_children("*", "MeshInstance3D", true, true)
	
	print("Found %d MeshInstance3D nodes" % all_meshes.size())
	
	for mesh in all_meshes:
		# Skip anything that is part of the player (player itself + descendants)
		if player.is_ancestor_of(mesh) or mesh == player:
			print("Skipping player mesh: ", mesh.get_path())
			continue
		
		# Optional: extra safety if player has weird setup
		# if mesh.is_descendant_of(player):	# same as player.is_ancestor_of(mesh)
		#	 continue
		
		original_materials[mesh] = mesh.material_override
		mesh.material_override = white_material
		print("Whitened: ", mesh.get_path())

# Function to revert to originals
func revert_objects():
	for mesh in original_materials.keys():
		mesh.material_override = original_materials[mesh]
	original_materials.clear()
