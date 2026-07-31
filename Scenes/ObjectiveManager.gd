extends Node
## Autoload singleton: ObjectiveManager
##
## Tracks a queue of objectives, one "current" objective at a time.
## Completing the current objective automatically advances to the next
## incomplete one. Add this script as an Autoload named "ObjectiveManager"
## in Project Settings > Autoload.

signal objective_changed(objective: Dictionary)
signal objective_completed(objective: Dictionary)
signal all_objectives_completed

const SAVE_PATH := "user://objectives_save.json"

var _objectives: Array[Dictionary] = []
var _current_index: int = -1


func _ready() -> void:
	load_progress()


## Add a new objective to the end of the queue.
## If nothing is currently active, this becomes the current objective.
func add_objective(id: String, title: String, description: String = "") -> void:
	for obj in _objectives:
		if obj["id"] == id:
			push_warning("Objective with id '%s' already exists." % id)
			return

	_objectives.append({
		"id": id,
		"title": title,
		"description": description,
		"completed": false,
	})

	if _current_index == -1:
		_current_index = _objectives.size() - 1
		objective_changed.emit(get_current_objective())


## Returns the current objective dictionary, or {} if none is active.
func get_current_objective() -> Dictionary:
	if _current_index >= 0 and _current_index < _objectives.size():
		return _objectives[_current_index]
	return {}


## Marks the current objective as completed and advances to the next one.
func complete_current_objective() -> void:
	if _current_index == -1:
		return

	var obj := _objectives[_current_index]
	if obj["completed"]:
		return

	obj["completed"] = true
	objective_completed.emit(obj)
	_advance_to_next()


## Jump directly to a specific objective by id (skips others without completing them).
func set_current_objective(id: String) -> bool:
	for i in _objectives.size():
		if _objectives[i]["id"] == id:
			_current_index = i
			objective_changed.emit(get_current_objective())
			return true
	push_warning("Objective id '%s' not found." % id)
	return false


func is_objective_completed(id: String) -> bool:
	for obj in _objectives:
		if obj["id"] == id:
			return obj["completed"]
	return false


## Removes all objectives and resets state (does not touch the save file).
func clear_objectives() -> void:
	_objectives.clear()
	_current_index = -1


## Writes current objective state to disk. Call this whenever your game saves.
func save_progress() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("ObjectiveManager: failed to open save file for writing.")
		return
	var data := {
		"objectives": _objectives,
		"current_index": _current_index,
	}
	file.store_string(JSON.stringify(data))
	file.close()


## Loads objective state from disk, if a save file exists. Called automatically on _ready().
func load_progress() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("ObjectiveManager: failed to open save file for reading.")
		return

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("ObjectiveManager: save file is corrupted.")
		return

	_objectives.clear()
	for obj in parsed.get("objectives", []):
		_objectives.append(obj as Dictionary)
	_current_index = parsed.get("current_index", -1)

	var current := get_current_objective()
	if not current.is_empty():
		objective_changed.emit(current)


## Advances _current_index to the next incomplete objective, or fires
## all_objectives_completed if none remain.
func _advance_to_next() -> void:
	var next_index := _current_index + 1
	while next_index < _objectives.size() and _objectives[next_index]["completed"]:
		next_index += 1

	if next_index < _objectives.size():
		_current_index = next_index
		objective_changed.emit(get_current_objective())
	else:
		_current_index = -1
		all_objectives_completed.emit()
