# objective_manager.gd (set as Autoload named "Objectives")
#extends Node
#
#signal objective_added(objective: Objective)
#signal objective_updated(objective: Objective)
#signal objective_completed(objective: Objective)
#
#var active_objectives: Dictionary = {} # id -> Objective
#
#func add_objective(objective: Objective) -> void:
	#active_objectives[objective.id] = objective
	#objective_added.emit(objective)
#
#func update_progress(id: String, amount: int = 1) -> void:
	#if not active_objectives.has(id):
		#return
	#var obj = active_objectives[id]
	#obj.add_progress(amount)
	#objective_updated.emit(obj)
	#if obj.is_completed:
		#objective_completed.emit(obj)
#
#func get_objective(id: String) -> Objective:
	#return active_objectives.get(id, null)
