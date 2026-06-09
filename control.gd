extends Control


signal resume
signal quit
signal main_menu
func _on_resume_pressed() -> void:
	emit_signal("resume")
	pass # Replace with function body.



func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_main_menu_pressed() -> void:
	emit_signal("main_menu")

func _on_quit_pressed() -> void:
	emit_signal("quit")
