extends CharacterBody3D

# Movement
@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.5
@export var fall_acceleration: float = 75.0
# Stamina
@export var max_stamina: float = 100.0
@export var drain_rate: float = 30.0
@export var regen_rate: float = 15.0
# Noise
@export var walk_noise: float = 0.4
@export var sprint_noise: float = 1.0
@export var noise_emit_interval: float = 0.2

# Nodes
@onready var battery = $Battery
@onready var player = $"."
@onready var camera = $Camera3D
@onready var hand = $Hand
@onready var flashlight = $Hand/SpotLight3D
@onready var menu_instance = %PauseMenu
@onready var ray = %SeeCast
@onready var interaction_notifier = $CanvasLayer/InteractionNotifier
@onready var sprint_bar = $CanvasLayer/SprintBar
@onready var locker = preload("res://Scenes/locker_scene.gd")
@onready var flashlight_1 = $Hand/SpotLight3D
@onready var hide_screen = $CanvasLayer/Hide
@onready var fade_black = $CanvasLayer/ColorRect/fade_black
@onready var flashlight_click = $flashlight_click
@onready var animation_player = $"../AnimationPlayer"
@onready var KeyCard = $"../NavigationRegion3D/EDD LOVES NEW VRSIONS/KeyCard"
@onready var flickering_light = $"../flickering_light"
@onready var mesh_1 = $Camera3D/players_hand222
@onready var mesh_2 = $Camera3D/players_hand222/Sketchfab_model
@onready var animation_obj = $Current_Objective_


# State
var mouse_sensitivity: float = 0.002
var menu_on: bool = false
var camera_x_rotation: float = 0.0
var target_velocity: Vector3 = Vector3.ZERO
var pages_collected: int = 0
var current_stamina: float = 100.0
var is_exhausted: bool = false
var is_hiding: bool = false
var just_entered_locker: bool = false

# Noise system
signal noise_emitted(pos: Vector3, level: float)
var _noise_timer: float = 0.0
var noise_level: float = 0.0


func _ready():
	floor_max_angle = deg_to_rad(50.0)
	for light in get_tree().get_nodes_in_group("indoor_lighting"):
		light.visible = false
	menu_instance.resume.connect(unpause)
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	menu_instance.hide()
	hide_screen.visible = false
	current_stamina = max_stamina
	sprint_bar.max_value = max_stamina
	sprint_bar.value = current_stamina

func _unhandled_input(event):
	if is_hiding:
		return
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_x_rotation -= event.relative.y * mouse_sensitivity
		camera_x_rotation = clamp(camera_x_rotation, deg_to_rad(-70), deg_to_rad(80))
		camera.rotation.x = camera_x_rotation

func _process(delta):
	hand.rotation.y = camera_x_rotation
	if is_hiding:
		if just_entered_locker:
			just_entered_locker = false
			return
		if Input.is_action_just_pressed("leave_locker"):
			var lockers = get_tree().get_nodes_in_group("Locker")
			for l in lockers:
				if l.player_ref == self:
					flashlight.exit_locker()
					mesh_1.visible = true
					mesh_2.visible = true
					hand.visible = true
					l.exit(self)
					global_position += -global_transform.basis.z * -2
					break
		if Input.is_action_just_pressed("pause_menu"):
			menu_on = !menu_on
			if menu_on:
				menu_instance.show()
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				menu_instance.hide()
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		return
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
	if is_hiding:
		return
	var collider = ray.get_collider()
	if not ray.is_colliding() or collider == null:
		interaction_notifier.visible = false
		return
	if collider.is_in_group("Batteries"):
		interaction_notifier.visible = true
		if Input.is_action_just_pressed("Use"):
			BatteryScript.battery_current_charge = BatteryScript.battery_max_charge
			BatteryScript.battery_charge_changed.emit(BatteryScript.battery_current_charge)
			flashlight.hidden = false
			BatteryScript.flashlight_on = true
			flashlight_1.update_flashlight()
			collider.queue_free()
			if ObjectiveManager.get_current_objective().get("id") == "obj_1":
				flickering_light.hide()
				ObjectiveManager.complete_current_objective()
				animation_obj.play("animation1")

	elif collider.is_in_group("Keycard"):
		KeyCard.queue_free()
	elif collider.is_in_group("Locker"):
		interaction_notifier.visible = true
		if Input.is_action_just_pressed("Use"):
			fade_black.stop()
			fade_black.play("new_animation")
			flashlight.enter_locker()
			hand.visible = false
			mesh_1.visible = false
			mesh_2.visible = false
			collider.enter(player)
			just_entered_locker = true
			interaction_notifier.visible = false
			camera_x_rotation = 0.0
			camera.rotation.x = 0.0
	elif collider.is_in_group("generator_int"):
		interaction_notifier.visible = true
		if Input.is_action_just_pressed("Use"):
			animation_player.play("light's")
			for light in get_tree().get_nodes_in_group("indoor_lighting"):
				light.visible = true
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
	if is_hiding:
		noise_level = 0.0
		return

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

	if not is_moving:
		noise_level = 0.0
	elif Input.is_action_pressed("move_sprint") and not is_exhausted:
		noise_level = sprint_noise
	else:
		noise_level = walk_noise

	if noise_level > 0.0:
		_noise_timer -= delta
		if _noise_timer <= 0.0:
			_noise_timer = noise_emit_interval
			noise_emitted.emit(global_position, noise_level)

	if is_moving:
		direction = direction.normalized()
		direction = basis * direction
		# Project onto slope so player moves along the surface, not horizontally through it
		if is_on_floor():
			direction = direction.slide(get_floor_normal()).normalized()

	# Compensate speed on slopes so climbing doesn't feel sluggish
	var speed_multiplier = 1.0
	if is_on_floor():
		var floor_angle = get_floor_normal().angle_to(Vector3.UP)
		speed_multiplier = 1.0 + sin(floor_angle) * 0.6

	target_velocity.x = direction.x * current_speed * speed_multiplier
	target_velocity.z = direction.z * current_speed * speed_multiplier

	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	else:
		# Reset vertical accumulation when grounded so gravity doesn't fight uphill movement
		target_velocity.y = 0.0

	velocity = target_velocity
	move_and_slide()
	
func die() -> void:
	queue_free() # or trigger death animation/game over

func _on_pause_menu_quit() -> void:
	get_tree().quit()
