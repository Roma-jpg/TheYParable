extends Interactable

@export var interaction_count: int = 0

func _ready():
	super._ready()
	update_interaction_text()

func update_interaction_text():
	interaction_text = interaction_text

func perform_interaction():
	LoadingScreen.start(
	4.0,
	"Совет: Чтобы идти вперёд, идите вперёд."
	)
	await get_tree().create_timer(5.2).timeout
	LoadingScreen.allow_fade_out()
