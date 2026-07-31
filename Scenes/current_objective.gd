extends Label

func _ready() -> void:
	ObjectiveManager.objective_changed.connect(_on_objective_changed)
	ObjectiveManager.all_objectives_completed.connect(_on_all_completed)

	# Show whatever's already active when the HUD first loads
	var current := ObjectiveManager.get_current_objective()
	if not current.is_empty():
		text = current["description"]
	else:
		text = ""

func _on_objective_changed(objective: Dictionary) -> void:
	text = objective["description"]

func _on_all_completed() -> void:
	text = "All objectives complete!"
