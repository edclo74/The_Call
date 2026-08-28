extends Control








func _on_button_pressed() -> void:
	Global.flashlight_on = false
	Global.generator_on  = false
	Global.Keycard = false
	Global.Manager_Room = false
	Global.end_door = false
	get_tree().change_scene_to_file("res://Scenes/Main_Menu.tscn")
