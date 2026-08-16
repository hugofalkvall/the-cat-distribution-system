class_name EnemyTroll
extends CombatUnit

const MOVE_SPEED := 18.0
const ACCELERATION := 60.0
const COLLISION_RADIUS := 4.0

const IDOL_STOP_DISTANCE := 12.0

const DETECTION_RANGE := 80.0
const TARGET_UPDATE_INTERVAL := 0.2

const IDOL_CENTER_OFFSET := Vector2(16, 16)

var idol_target: Node2D
var combat_target: CombatUnit = null

var arena_grid: ArenaGrid
var spatial_index: CombatSpatialIndex
var combat_system: CombatSystem

var velocity := Vector2.ZERO
var target_update_timer := 0.0


func setup(new_idol_target: Node2D, new_spatial_index: CombatSpatialIndex, new_combat_system: CombatSystem, new_arena_grid: ArenaGrid) -> void:
	idol_target = new_idol_target
	spatial_index = new_spatial_index
	combat_system = new_combat_system
	arena_grid = new_arena_grid
	target_update_timer = randf_range(0.0, TARGET_UPDATE_INTERVAL)


func _process(delta: float) -> void:
	if not is_instance_valid(idol_target):
		return

	update_combat_target(delta)

	if is_instance_valid(combat_target) and has_attacks():
		var approach_range := get_approach_range()
		var in_attack_range := move_toward_position(combat_target.global_position, approach_range, delta)

		if in_attack_range:
			try_attack(combat_target, combat_system)
	else:
		move_toward_position(idol_target.global_position + IDOL_CENTER_OFFSET, IDOL_STOP_DISTANCE, delta)


func update_combat_target(delta: float) -> void:
	if spatial_index == null:
		return

	target_update_timer -= delta

	if target_update_timer > 0.0:
		return

	target_update_timer = TARGET_UPDATE_INTERVAL
	combat_target = spatial_index.get_closest_cat(global_position, DETECTION_RANGE) as CombatUnit


func move_toward_position(destination: Vector2, stop_distance: float, delta: float) -> bool:
	var distance := global_position.distance_to(destination)
	var desired_velocity := Vector2.ZERO

	if distance > stop_distance:
		var direction := global_position.direction_to(destination)
		desired_velocity = direction * MOVE_SPEED

	velocity = velocity.move_toward(desired_velocity, ACCELERATION * delta)

	var motion := velocity * delta

	if arena_grid != null:
		var old_position := global_position
		var new_position := arena_grid.move_unit(global_position, motion, COLLISION_RADIUS)
		var actual_motion := new_position - old_position

		if not is_equal_approx(actual_motion.x, motion.x):
			velocity.x = 0.0

		if not is_equal_approx(actual_motion.y, motion.y):
			velocity.y = 0.0

		global_position = new_position
	else:
		global_position += motion

	return distance <= stop_distance
