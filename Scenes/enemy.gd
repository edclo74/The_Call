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

# --- Search wandering (prevents standing still on top of the last known position) ---
@export var search_wander_radius := 8.0     # how far the enemy roams around last_known_position while searching
@export var search_wander_interval := 2.5   # how often it picks a new nearby point while searching

# --- Locker / hiding-spot avoidance (prevents patrol from snapping back to camp it) ---
@export var avoid_radius := 15.0     # patrol points won't be picked within this distance of a recently-searched spot
@export var avoid_duration := 25.0   # how long (seconds) that avoidance lasts after giving up a search

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

# search wander state
var _search_wander_timer: float = 0.0

# avoidance state
var avoid_position: Vector3 = Vector3.ZERO
var avoid_timer: float = 0.0


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
	if avoid_timer > 0.0:
		avoid_timer -= delta
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
				_enter_search()

		State.CHASE:
			if can_see_player:
				lose_sight_timer = lose_sight_time
				last_known_position = player.global_position
				nav_agent.target_position = player.global_position
			else:
				lose_sight_timer -= delta
				if lose_sight_timer <= 0.0:
					_enter_search()

			var dist := global_position.distance_to(player.global_position)
			if dist <= attack_range:
				_try_attack()
			else:
				_move(delta)

		State.SEARCH:
			_update_search_wander(delta)
			_move(delta)
			lose_sight_timer -= delta
			if can_see_player:
				_enter_chase()
			elif lose_sight_timer <= 0.0:
				_leave_search_to_patrol()

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
			_enter_search()
		State.CHASE:
			# Can't path to the player directly (they're behind a locked door, across
			# a gap, whatever) — path to the closest point we CAN reach near them instead.
			var map_rid := nav_agent.get_navigation_map()
			var reachable := NavigationServer3D.map_get_closest_point(map_rid, player.global_position)
			nav_agent.target_position = reachable
			# If even that doesn't help within another grace period, drop to SEARCH.
			last_known_position = reachable
			_enter_search()
		State.SEARCH:
			_pick_search_wander_point()


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


func _enter_search() -> void:
	state = State.SEARCH
	lose_sight_timer = lose_sight_time
	_search_wander_timer = 0.0
	nav_agent.target_position = last_known_position


# Search should look like the enemy actively poking around the area, not
# parking itself on the exact last-known spot (e.g. right next to a locker)
# for the full duration of lose_sight_time.
func _update_search_wander(delta: float) -> void:
	_search_wander_timer -= delta
	if nav_agent.is_navigation_finished() or _search_wander_timer <= 0.0:
		_pick_search_wander_point()


func _pick_search_wander_point() -> void:
	_search_wander_timer = search_wander_interval
	var angle := randf() * TAU
	var radius := randf_range(1.0, search_wander_radius)
	var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	var desired := last_known_position + offset
	var map_rid := nav_agent.get_navigation_map()
	nav_agent.target_position = NavigationServer3D.map_get_closest_point(map_rid, desired)


# When we give up searching, mark this spot as "recently checked" so patrol
# doesn't immediately wander back and re-camp it.
func _leave_search_to_patrol() -> void:
	avoid_position = last_known_position
	avoid_timer = avoid_duration
	state = State.PATROL
	_pick_patrol_point()


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
	var map_rid := nav_agent.get_navigation_map()
	var desired := Vector3.ZERO
	var attempts := 0
	# Retry a handful of times to avoid landing back inside the "recently
	# searched" zone (e.g. right where the player was just hiding in a locker).
	while attempts < 8:
		var angle := randf() * TAU
		var radius := randf_range(2.0, patrol_radius)
		var offset := Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
		desired = origin_position + offset
		attempts += 1
		if avoid_timer <= 0.0 or desired.distance_to(avoid_position) >= avoid_radius:
			break
	# Snap to the closest point actually ON the navmesh so we never target
	# somewhere unreachable in the first place.
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
