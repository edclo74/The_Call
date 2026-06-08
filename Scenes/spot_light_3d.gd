extends SpotLight3D
# Drag your Camera3D node here
@onready var camera = $"../../Camera3D"
@onready var flashlight = $"."
@onready var player = $"../../"
var hidden = true

func enter_locker():
	hidden = true

func exit_locker():
	hidden = false

func _process(_delta):
	if Global.flashlight_on == false:
		spot_range = 0
	elif Global.flashlight_on == true:
		spot_range = 12.895
	if hidden == true:
		flashlight.hide()
	if hidden == false:
		flashlight.show()
	if Input.is_action_just_pressed("flashlight") and not player.is_hiding:
		hidden = !hidden
	
	if camera:
		# Make the flashlight look in the same direction as the camera
		global_transform.basis = camera.global_transform.basis
		global_position = camera.global_position
