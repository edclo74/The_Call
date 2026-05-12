extends CharacterBody3D
var player_view
@export var speed : float = 5
@export var fall_acceleration = 75
@onready var camera = $Camera3D
@onready var hand = $Hand
@onready var flashlight = $Hand/SpotLight3D
var sprint_speed = 2
var mouse_sensitivity = 0.002
@onready var menu_instance = %PauseMenu
var menu_on = false
var camera_x_rotation = 0.0
var target_velocity = Vector3.ZERO

var pages_collected = 0
@onready var ray = $Camera3D/SeeCast
@onready var interaction_notifier = $CanvasLayer/InteractionNotifier
@onready var collection_tracker = $CanvasLayer/BoxContainer/CollectionTracker

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_x_rotation -= event.relative.y * mouse_sensitivity
		camera_x_rotation = clamp(camera_x_rotation, deg_to_rad(-70), deg_to_rad(80))
		camera.rotation.x = camera_x_rotation

func _ready():
	menu_instance.resume.connect(unpause)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	menu_instance.hide()

func unpause():
	menu_instance.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
func _process(delta):

	hand.rotation.y = camera_x_rotation
	if Input.is_action_just_pressed("pause_menu"):
		menu_on = !menu_on
		if menu_on:
			menu_instance.show()
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			menu_instance.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
 

func _on_button_pressed():
	print("Button was pressed!")
func check_ray_hit():
	if ray.is_colliding():
		if ray.get_collider().is_in_group("Pickup"):
			interaction_notifier.visible = true
		if Input.is_action_just_pressed("Use"):
			ray.get_collider().gueue_free()
			pages_collected += 1
	else:
		interaction_notifier.visible = false
func _physics_process(delta):
	check_ray_hit()
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
func interact():
	print("Interacted!")

	
