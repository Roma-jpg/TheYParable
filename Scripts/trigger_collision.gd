extends BaseTrigger
@onready var playa_stopper: CollisionShape3D = $"../../../StaticBody3D3/playa_stopper"

func _ready() -> void:
	super._ready()
	one_shot = true
	pass

func on_trigger_enter(body: CharacterBody3D) -> void:
	playa_stopper.disabled = false
	await MonologueSystem.play_and_wait_monologues(["collision_expl1", 
	"collision_expl2", 
	"collision_expl3", 
	"collision_expl4", 
	"collision_expl5", 
	"collision_expl7"])
	playa_stopper.disabled = true
	await get_tree().create_timer(1.0).timeout
	
	
