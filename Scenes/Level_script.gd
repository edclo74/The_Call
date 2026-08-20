extends Node3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var flickering_light = $flickering_light
func _ready() -> void:
	world_environment.environment.adjustment_enabled = true
	world_environment.environment.ambient_light_energy = Settings.ambient_energy
	print("Applied energy = ", world_environment.environment.ambient_light_energy)
	#FORMAT = ObjectiveManager.add_objective(id: String, title: String, description: String = "")
	ObjectiveManager.add_objective("obj_1", "obj_1", "find help")
	ObjectiveManager.add_objective("obj_2", "obj_2", "find generator")
	ObjectiveManager.add_objective("obj_3", "obj_3", "activate generator")
	ObjectiveManager.add_objective("obj_4", "obj_4", "find Contact")
	ObjectiveManager.add_objective("obj_5", "obj_5", "investigate noise")
	

func _on_obj_2_checkpoint_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and ObjectiveManager.get_current_objective().get("id") == "obj_2":
		ObjectiveManager.complete_current_objective()
		
