extends BaseTrigger

func on_trigger_enter(body: CharacterBody3D):
	body.position.y -= 10
