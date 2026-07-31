extends Node3D

func _ready() -> void:
	#FORMAT = ObjectiveManager.add_objective(id: String, title: String, description: String = "")
	ObjectiveManager.add_objective("obj_1", "obj_1", "pick up batteries")
	ObjectiveManager.add_objective("obj_2", "obj_2", "find generator?")
	ObjectiveManager.add_objective("obj_3", "obj_3", "activate generator")
	ObjectiveManager.add_objective("obj_4", "obj_4", "find Contact?")
	ObjectiveManager.add_objective("obj_5", "obj_5", "investigate noise")


func _on_obj_2_checkpoint_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		ObjectiveManager.complete_current_objective()
