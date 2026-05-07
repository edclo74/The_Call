extends Control


signal resume


func _on_resume_pressed() -> void:
	emit_signal("resume")
	pass # Replace with function body.


func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_main_menu_pressed() -> void:
#get_tree().change_scene_to_file()
	pass

func _on_quit_pressed() -> void:
	pass
