extends Node2D

const MOVE_SPEED := 25.0
const ACCELERATION := 80.0

const WANDER_RADIUS := 48.0
const MIN_TARGET_DISTANCE := 20.0
const TARGET_REACHED_DISTANCE := 5.0

const DETECTION_RANGE := 80.0
const COMBAT_STOP_DISTANCE := 8.0
const TARGET_UPDATE_INTERVAL := 0.2

const ARENA_MIN := Vector2(128, 32)
const ARENA_MAX := Vector2(512, 352)

var home_position: Vector2
var wander_target_position: Vector2
var velocity := Vector2.ZERO

var spatial_index: CombatSpatialIndex
var combat_target: Node2D = null
var target_update_timer := 0.0


func setup(new_spatial_index: CombatSpatialIndex) -> void:
	spatial_index = new_spatial_index
	home_position = global_position
	target_update_timer = randf_range(0.0, TARGET_UPDATE_INTERVAL)
	choose_new_wander_target()


func _process(delta: float) -> void:
	update_combat_target(delta)

	if is_instance_valid(combat_target):
		move_toward_position(combat_target.global_position, COMBAT_STOP_DISTANCE, delta)
	else:
		wander(delta)


func update_combat_target(delta: float) -> void:
	if spatial_index == null:
		return

	target_update_timer -= delta

	if target_update_timer > 0.0:
		return

	target_update_timer = TARGET_UPDATE_INTERVAL
	combat_target = spatial_index.get_closest_enemy(global_position, DETECTION_RANGE)


func wander(delta: float) -> void:
	var reached_target := move_toward_position(wander_target_position, TARGET_REACHED_DISTANCE, delta)

	if reached_target:
		choose_new_wander_target()


func move_toward_position(destination: Vector2, stop_distance: float, delta: float) -> bool:
	var distance := global_position.distance_to(destination)
	var desired_velocity := Vector2.ZERO

	if distance > stop_distance:
		var direction := global_position.direction_to(destination)
		desired_velocity = direction * MOVE_SPEED

	velocity = velocity.move_toward(desired_velocity, ACCELERATION * delta)
	global_position += velocity * delta

	return distance <= stop_distance


func choose_new_wander_target() -> void:
	var new_target := home_position

	while new_target.distance_to(home_position) < MIN_TARGET_DISTANCE:
		var angle := randf_range(0.0, TAU)
		var distance := randf_range(MIN_TARGET_DISTANCE, WANDER_RADIUS)

		new_target = home_position + Vector2(cos(angle), sin(angle)) * distance

	new_target.x = clamp(new_target.x, ARENA_MIN.x, ARENA_MAX.x)
	new_target.y = clamp(new_target.y, ARENA_MIN.y, ARENA_MAX.y)

	wander_target_position = new_target
