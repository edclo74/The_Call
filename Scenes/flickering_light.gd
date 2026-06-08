extends SpotLight3D

# Base energy level of the spotlight
@export var base_energy: float = 5.0

# Maximum deviation from the base energy
@export var flicker_range: float = 1.5

# Speed of interpolation for smooth flickering
@export var flicker_speed: float = 25.0

var target_energy: float = 2.0

func _ready() -> void:
	target_energy = base_energy

func _process(delta: float) -> void:
	# Randomly change target energy dynamically
	if randf() < 0.15:
		target_energy = base_energy + randf_range(-flicker_range, flicker_range)
	
	# Smoothly transition to the target energy (Fixed property name)
	light_energy = lerp(light_energy, target_energy, flicker_speed * delta)
