extends Control

@export var world_env: WorldEnvironment
@onready var test_world_environment: WorldEnvironment = $SubViewportContainer/SubViewport/WorldEnvironment

func _on_h_slider_value_changed(value: float) -> void:
	test_world_environment.environment.ambient_light_energy = value
	Settings.ambient_energy = value
	
func _ready() -> void:
	test_world_environment.environment.ambient_light_energy = Settings.ambient_energy

func _on_button_pressed() -> void:
	SceneManager.load_level("res://Scenes/player_movement.tscn")
