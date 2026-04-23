extends CharacterBody3D
var player_view
@export var speed = 5
@export var fall_acceleration = 75
@onready var camera = $Camera3D
@onready var hand = $Hand
@onready var flashlight = $Hand/SpotLight3D
var sprint_speed = 2
var mouse_sensitivity = 0.002

var camera_x_rotation = 0.0
var target_velocity = Vector3.ZERO
func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate body horizontally, camera vertically
		rotate_y(-event.relative.x * mouse_sensitivity) #
		# Accumulate and clamp vertical rotation
		camera_x_rotation -= event.relative.y * mouse_sensitivity
		camera_x_rotation = clamp(camera_x_rotation, deg_to_rad(-70), deg_to_rad(80))
		camera.rotation.x = camera_x_rotation
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(delta):
	hand.rotation.y = camera_x_rotation
func _physics_process(delta):
	var direction = Vector3.ZERO
	if Input.is_action_pressed("move_right"):
		direction.x -= 1
	if Input.is_action_pressed("move_left"):
		direction.x += 1
	if Input.is_action_pressed("move_back"):
		direction.z -= 1
	if Input.is_action_pressed("move_forward"):
		direction.z += 1
	
	if direction != Vector3.ZERO:
		direction = direction.normalized() 
		direction = basis * direction
		if Input.is_action_pressed("move_sprint"):
			direction *= sprint_speed
	
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	velocity = target_velocity
	move_and_slide()
