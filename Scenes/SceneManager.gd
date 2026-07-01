extends Node

# Path to your loading screen UI scene
const LOADING_SCREEN_PATH = "res://Scenes/loading_screen.tscn"

func load_level(target_path: String) -> void:
	# Instantiate the loading screen
	var loading_screen_instance = load(LOADING_SCREEN_PATH).instantiate()
	
	# Pass the target scene path over to the loading screen
	loading_screen_instance.target_scene_path = target_path
	
	# Add the loading screen directly to the root of the active scene tree
	get_tree().root.add_child(loading_screen_instance)
