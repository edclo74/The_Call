extends SpotLight3D

# Drag your Camera3D node here
@onready var base_energy = 3.376
@onready var camera = $"../../Camera3D"
@onready var flashlight = $"."
@onready var player = $"../../"
@onready var flashlight_model = $"../../Camera3D/players_hand222/Sketchfab_model/71578a57ec3f432aae1c5cfd4c8cb237_obj_cleaner_materialmerger_gles/Node3D"
@onready var flashlight_click = $"../../flashlight_click"
@export var flicker_range: float = 1.5
# Speed of interpolation for smooth flickering
@export var flicker_speed: float = 25.0

var hidden = true


var target_energy: float = 2.0


func enter_locker():
	hidden = true

func exit_locker():
	hidden = false

func _ready():
	update_flashlight()
	target_energy = base_energy

func update_flashlight():
	if BatteryScript.flashlight_on:
		flashlight_click.volume_db = 0
		flashlight.visible = true
		flashlight.light_energy = 2.0
	else:
		flashlight_click.volume_db = -80
		flashlight.visible = false
		flashlight.light_energy = 0.0

func _process(_delta):
	# Handle toggle input
	if Input.is_action_just_pressed("flashlight") and not player.is_hiding:
		if hidden and BatteryScript.battery_current_charge <= 0.0:
			# Battery dead, don't allow turning on
			pass
		else:
			flashlight_click.play()
			hidden = !hidden
			BatteryScript.flashlight_on = not hidden
	if BatteryScript.battery_current_charge <= 25:
		target_energy = base_energy + randf_range(-flicker_range, flicker_range)
	light_energy = lerp(light_energy, target_energy, flicker_speed * _delta)

	# Show/hide based on state
	if hidden:
		flashlight.hide()
	else:
		flashlight.show()
		# Drain battery only while flashlight is actually on
		BatteryScript.battery_drain(_delta)
		if BatteryScript.battery_current_charge <= 0.0:
			hidden = true
			BatteryScript.flashlight_on = false
			flashlight.hide()

	if camera:
		# Make the flashlight look in the same direction as the camera
		global_transform.basis = camera.global_transform.basis
		global_position = flashlight_model.global_position
