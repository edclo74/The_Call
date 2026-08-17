extends CharacterBody3D

@export var speed := 7
@export var detection_range := 30     # visual cone distance
@export var hearing_range := 50       # max distance at which noise is heard at full sprint
@export var attack_range := 1.5
@export var attack_damage := 10
@export var attack_cooldown := 1.0
@export var patrol_radius := 100     # was 100000000000 — that's why patrol targets were unreachable
@export var lose_sight_time := 10      # seconds before giving up chase after losing LOS

# --- Stuck detection ---
@export var stuck_check_interval := 0.5   # how often we sample position
@export var stuck_distance_threshold := 0.3  # must move at least this far per interval or we're "stuck"
@export var stuck_grace_time := 1.5       # how many seconds of being stuck before we react
@onready var kill_cast = $KillCast
@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var sight_cast: RayCast3D = $SightCast
@onready var patrol_timer: Timer = $PatrolTimer
var player: Node3D
var attack_timer := 0.0

enum State { PATROL, INVESTIGATE, CHASE, SEARCH }
var state: State = State.PATROL

var last_known_position: Vector3 = Vector3.ZERO
var origin_position: Vector3 = Vector3.ZERO
var lose_sight_timer: float = 0.0

# stuck tracking state
var _stuck_check_timer: float = 0.0
var _last_check_position: Vector3 = Vector3.ZERO
var _stuck_timer: float = 0.0


func _ready() -> void:
	origin_position = global_position
	_last_check_position = global_position
	player = get_tree().get_first_node_in_group("player")
	patrol_timer.timeout.connect(_pick_patrol_point)
	_pick_patrol_point()

	if player and player.has_signal("noise_emitted"):
		player.noise_emitted.connect(_on_player_noise)


func _physics_process(delta: float) -> void:
	if _check_kill_cast():
		_kill_player()
		return
	if not player:
		return
	attack_timer -= delta
	_draw_debug_path()
	_update_stuck_check(delta)

	var to_player = (player.global_position - global_position)
	sight_cast.target_position = to_player.normalized() * detection_range

	var can_see_player := _check_line_of_sight()

	match state:
		State.PATROL:
			_move(delta)
			if can_see_player:
				_enter_chase()

		State.INVESTIGATE:
			nav_agent.target_position = last_known_position
			_move(delta)
			if can_see_player:
				_enter_chase()
			elif nav_agent.is_navigation_finished():
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
					state = State.SEARCH
					nav_agent.target_position = last_known_position

			var dist := global_position.distance_to(player.global_position)
			if dist <= attack_range:
				_try_attack()
			else:
				_move(delta)

		State.SEARCH:
			_move(delta)
			lose_sight_timer -= delta
			if can_see_player:
				_enter_chase()
			elif lose_sight_timer <= 0.0:
				state = State.PATROL
				_pick_patrol_point()

func _kill_player() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://Scenes/poo.tscn")

# --- Stuck watchdog ---
# Every `stuck_check_interval` seconds, check how far we've actually moved.
# If we're barely moving while navigation thinks we're not done, we're stuck
# on geometry or chasing an unreachable point — so bail out and pick something new.
func _update_stuck_check(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		_stuck_timer = 0.0
		return

	_stuck_check_timer += delta
	if _stuck_check_timer < stuck_check_interval:
		return
	_stuck_check_timer = 0.0

	var moved := global_position.distance_to(_last_check_position)
	_last_check_position = global_position

	if moved < stuck_distance_threshold:
		_stuck_timer += stuck_check_interval
	else:
		_stuck_timer = 0.0

	if _stuck_timer >= stuck_grace_time:
		_stuck_timer = 0.0
		_handle_stuck()


func _handle_stuck() -> void:
	match state:
		State.PATROL:
			_pick_patrol_point()
		State.INVESTIGATE:
			# Can't reach the noise location — give up and search around here instead
			state = State.SEARCH
			lose_sight_timer = lose_sight_time
		State.CHASE:
			# Can't path to the player directly (they're behind a locked door, across
			# a gap, whatever) — path to the closest point we CAN reach near them instead.
			var map_rid := nav_agent.get_navigation_map()
			var reachable := NavigationServer3D.map_get_closest_point(map_rid, player.global_position)
			nav_agent.target_position = reachable
			# If even that doesn't help within another grace period, drop to SEARCH.
			state = State.SEARCH
			last_known_position = reachable
			lose_sight_timer = lose_sight_time
		State.SEARCH:
			_pick_patrol_point()
			state = State.SEARCH


func _check_line_of_sight() -> bool:
	if not sight_cast.is_colliding():
		return false
	var dist := global_position.distance_to(player.global_position)
	if dist > detection_range:
		return false
	var hit = sight_cast.get_collider()
	return hit != null and hit == player


func _enter_chase() -> void:
	state = State.CHASE
	lose_sight_timer = lose_sight_time
	last_known_position = player.global_position


func _on_player_noise(noise_pos: Vector3, noise_level: float) -> void:
	if state == State.CHASE:
		return
	if player.is_hiding:
		return
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

	var flat_direction := Vector3(direction.x, 0.0, direction.z)
	if flat_direction.length() > 0.1:
		look_at(global_position + flat_direction, Vector3.UP)


func _pick_patrol_point() -> void:
	if state != State.PATROL and state != State.SEARCH:
		return
	var angle := randf() * TAU
	var radius := randf_range(2.0, patrol_radius)
	var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	var desired := origin_position + offset
	# Snap to the closest point actually ON the navmesh so we never target
	# somewhere unreachable in the first place.
	var map_rid := nav_agent.get_navigation_map()
	nav_agent.target_position = NavigationServer3D.map_get_closest_point(map_rid, desired)


func _draw_debug_path() -> void:
	if not OS.is_debug_build():
		return
	var points := nav_agent.get_current_navigation_path()
	if points.size() < 2:
		return
		
func _check_kill_cast() -> bool:
	if not kill_cast.is_colliding():
		return false
	var hit = kill_cast.get_collider()
	return hit != null and hit == player


func _try_attack() -> void:
	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		print("Enemy attacks for ", attack_damage)
		# player.take_damage(attack_damage)  # uncomment when ready
