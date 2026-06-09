extends SpotLight3D
# Drag your Camera3D node here
@onready var camera = $"../../Camera3D"
@onready var flashlight = $"."
@onready var player = $"../../"

@onready var flashlight_click = $"../../flashlight_click"
var hidden = true

func enter_locker():
	hidden = true

func exit_locker():
	hidden = false

func _ready():
	update_flashlight()

func update_flashlight():
	if Global.flashlight_on:
		flashlight_click.volume_db = 0
		flashlight_click.play()
		flashlight.visible = true
		flashlight.light_energy = 1.0
	else:
		flashlight_click.volume_db = -80
		flashlight.visible = false
		flashlight.light_energy = 0.0
##FIX THIS GARBAGE HOLY I SUCK AT CODING
func _process(_delta):
	if hidden == true:
		flashlight.hide()
	if hidden == false:
		flashlight.show()
	if Input.is_action_just_pressed("flashlight") and not player.is_hiding:
		flashlight_click.play()
		hidden = !hidden
	
	if camera:
		# Make the flashlight look in the same direction as the camera
		global_transform.basis = camera.global_transform.basis
		global_position = camera.global_position
