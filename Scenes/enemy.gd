extends CharacterBody3D

@export var speed := 3.5
@export var detection_range := 10.0     # visual cone distance
@export var hearing_range := 15.0       # max distance at which noise is heard at full sprint
@export var attack_range := 1.5
@export var attack_damage := 10
@export var attack_cooldown := 1.0
@export var patrol_radius := 8.0        # how far from origin the enemy wanders
@export var lose_sight_time := 2.5      # seconds before giving up chase after losing LOS

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
# SightCast: RayCast3D child, rotated to face forward (local Z: -1), length = detection_range
@onready var sight_cast: RayCast3D = $SightCast
# PatrolTimer: Timer child, autostart=true, one_shot=false, wait_time=4.0
@onready var patrol_timer: Timer = $PatrolTimer

var player: Node3D
var attack_timer := 0.0

enum State { PATROL, INVESTIGATE, CHASE, SEARCH }
var state: State = State.PATROL

var last_known_position: Vector3 = Vector3.ZERO
var origin_position: Vector3 = Vector3.ZERO
var lose_sight_timer: float = 0.0


func _ready() -> void:
	origin_position = global_position
	player = get_tree().get_first_node_in_group("player")
	patrol_timer.timeout.connect(_pick_patrol_point)
	_pick_patrol_point()

	# Connect to the player's noise signal
	if player and player.has_signal("noise_emitted"):
		player.noise_emitted.connect(_on_player_noise)


func _physics_process(delta: float) -> void:
	if not player:
		return
	attack_timer -= delta

	# Update sight cast to always point toward the player
	var to_player = (player.global_position - global_position)
	sight_cast.target_position = to_player.normalized() * detection_range

	var can_see_player := _check_line_of_sight()

	match state:
		State.PATROL:
			_move(delta)
			if can_see_player:
				_enter_chase()

		State.INVESTIGATE:
			# Walk to the noise position
			nav_agent.target_position = last_known_position
			_move(delta)
			if can_see_player:
				_enter_chase()
			elif nav_agent.is_navigation_finished():
				# Reached noise spot, switch to a short search wander
				state = State.SEARCH
				lose_sight_timer = lose_sight_time

		State.CHASE:
			if can_see_player:
				lose_sight_timer = lose_sight_time
				last_known_position = player.global_position
				nav_agent.target_position = player.global_position
			else:
				lose_sight_timer -= delta
				if lose_sight_timer <= 0.0:
					# Lost the player — go to last known spot then search
					state = State.SEARCH
					nav_agent.target_position = last_known_position

			var dist := global_position.distance_to(player.global_position)
			if dist <= attack_range:
				_try_attack()
			else:
				_move(delta)

		State.SEARCH:
			# Wander near last known position briefly, then resume patrol
			_move(delta)
			lose_sight_timer -= delta
			if can_see_player:
				_enter_chase()
			elif lose_sight_timer <= 0.0:
				state = State.PATROL
				_pick_patrol_point()


func _check_line_of_sight() -> bool:
	if not sight_cast.is_colliding():
		return false
	var dist := global_position.distance_to(player.global_position)
	if dist > detection_range:
		return false
	var hit = sight_cast.get_collider()
	# The ray hit something — only counts as sight if it's the player
	return hit != null and hit == player


func _enter_chase() -> void:
	state = State.CHASE
	lose_sight_timer = lose_sight_time
	last_known_position = player.global_position


func _on_player_noise(noise_pos: Vector3, noise_level: float) -> void:
	# Ignore noise while already chasing visually
	if state == State.CHASE:
		return
	# Ignore if player is in a locker (they emit 0 noise but guard anyway)
	if player.is_hiding:
		return
	# Scale hearing range by noise level (sprint = full range, walk = 40% range)
	var effective_range := hearing_range * noise_level
	var dist := global_position.distance_to(noise_pos)
	if dist <= effective_range:
		last_known_position = noise_pos
		state = State.INVESTIGATE


func _move(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		return
	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	velocity = direction * speed
	move_and_slide()
	# Face movement direction
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)


func _pick_patrol_point() -> void:
	if state != State.PATROL:
		return
	# Pick a random point within patrol_radius of the spawn origin
	var angle := randf() * TAU
	var radius := randf_range(2.0, patrol_radius)
	var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	nav_agent.target_position = origin_position + offset

func _try_attack() -> void:
	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		print("Enemy attacks for ", attack_damage)
		# player.take_damage(attack_damage)  # uncomment when ready
