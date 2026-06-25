extends CharacterBody3D

@export var speed := 3.5
@export var detection_range := 10.0
@export var attack_range := 1.5
@export var attack_damage := 10
@export var attack_cooldown := 1.0

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

var player: Node3D
var attack_timer := 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if not player:
		return

	attack_timer -= delta
	var dist := global_position.distance_to(player.global_position)

	if dist <= detection_range:
		nav_agent.target_position = player.global_position

		if dist <= attack_range:
			_try_attack()
		else:
			_move(delta)

func _move(delta: float) -> void:
	if nav_agent.is_navigation_finished():
		return

	var next_pos := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()
	velocity = direction * speed
	move_and_slide()

func _try_attack() -> void:
	if attack_timer <= 0.0:
		attack_timer = attack_cooldown
		print("Enemy attacks for ", attack_damage)
		# player.take_damage(attack_damage)  # uncomment when ready
