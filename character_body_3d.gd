extends CharacterBody3D

# Movement
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var fall_acceleration: float = 75.0

# Stamina
@export var max_stamina: float = 100.0
@export var drain_rate: float = 30.0
@export var regen_rate: float = 15.0

# Nodes
@onready var camera = $Camera3D
@onready var hand = $Hand
@onready var flashlight = $Hand/SpotLight3D
@onready var menu_instance = %PauseMenu
@onready var ray = %SeeCast
@onready var interaction_notifier = $CanvasLayer/InteractionNotifier
@onready var collection_tracker = $CanvasLayer/BoxContainer/CollectionTracker
@onready var sprint_bar = $CanvasLayer/SprintBar

# State
var mouse_sensitivity: float = 0.002
var menu_on: bool = false
var camera_x_rotation: float = 0.0
var target_velocity: Vector3 = Vector3.ZERO
var pages_collected: int = 0
var current_stamina: float = 100.0
var is_exhausted: bool = false


func _ready():
	menu_instance.resume.connect(unpause)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	menu_instance.hide()
	current_stamina = max_stamina
	sprint_bar.max_value = max_stamina
	sprint_bar.value = current_stamina


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_x_rotation -= event.relative.y * mouse_sensitivity
		camera_x_rotation = clamp(camera_x_rotation, deg_to_rad(-70), deg_to_rad(80))
		camera.rotation.x = camera_x_rotation


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


func unpause():
	menu_instance.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func check_ray_hit():
	var collider = ray.get_collider()
	print(collider)
	if ray.is_colliding() and collider != null and collider.is_in_group("Batteries"):
		interaction_notifier.visible = true
		if Input.is_action_just_pressed("Use"):
			collider.queue_free()
			Global.flashlight_on = true
	else:
		interaction_notifier.visible = false
	if ray.is_colliding() and collider != null and collider.is_in_group("Locker"):
		interaction_notifier.visible = true
		if Input.is_action_just_pressed("Use"):
			pass
####ADD STUFF HERE YOU BASTARD######
	else:
		interaction_notifier.visible = false


func _handle_stamina(delta: float, is_moving: bool) -> float:
	var current_speed = walk_speed

	if Input.is_action_pressed("move_sprint") and not is_exhausted and is_moving:
		current_speed = sprint_speed
		current_stamina -= drain_rate * delta
		if current_stamina <= 0:
			current_stamina = 0.0
			is_exhausted = true
	else:
		current_stamina += regen_rate * delta
		if current_stamina >= max_stamina:
			current_stamina = max_stamina
		if is_exhausted and current_stamina >= (max_stamina * 0.2):
			is_exhausted = false

	sprint_bar.value = current_stamina
	return current_speed


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

	var is_moving = direction != Vector3.ZERO
	var current_speed = _handle_stamina(delta, is_moving)

	if is_moving:
		direction = direction.normalized()
		direction = basis * direction

	target_velocity.x = direction.x * current_speed
	target_velocity.z = direction.z * current_speed

	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)

	velocity = target_velocity
	move_and_slide()
