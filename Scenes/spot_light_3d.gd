extends SpotLight3D
# Drag your Camera3D node here
@onready var camera = $"../../Camera3D"
@onready var flashlight = $"."
@onready var player = $"../../"
@onready var flashlight_model = $"../../Camera3D/players_hand222/Sketchfab_model/71578a57ec3f432aae1c5cfd4c8cb237_obj_cleaner_materialmerger_gles/Node3D"
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
		flashlight.visible = true
		flashlight.light_energy = 2.0
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
		global_position = flashlight_model.global_position
