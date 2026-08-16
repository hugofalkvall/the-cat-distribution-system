class_name EnemyTroll
extends CombatUnit

const MOVE_SPEED := 18.0
const ACCELERATION := 60.0
const COLLISION_RADIUS := 4.0

const DETECTION_RANGE := 80.0
const TARGET_UPDATE_INTERVAL := 0.2

var idol_target: Damageable
var combat_target: Damageable = null

var arena_grid: ArenaGrid
var spatial_index: CombatSpatialIndex
var combat_system: CombatSystem

var velocity := Vector2.ZERO
var target_update_timer := 0.0
var avoidance_side := 1.0


func setup(new_idol_target: Damageable, new_spatial_index: CombatSpatialIndex, new_combat_system: CombatSystem, new_arena_grid: ArenaGrid) -> void:
	idol_target = new_idol_target
	spatial_index = new_spatial_index
	combat_system = new_combat_system
	arena_grid = new_arena_grid
	avoidance_side = -1.0 if randf() < 0.5 else 1.0
	target_update_timer = randf_range(0.0, TARGET_UPDATE_INTERVAL)


func _process(delta: float) -> void:
	if not is_instance_valid(idol_target):
		return

	update_combat_target(delta)

	if not is_instance_valid(combat_target):
		return

	if combat_target.is_dead:
		return

	if not has_attacks():
		return

	var approach_range := get_approach_range(combat_target)
	var target_position := combat_target.get_combat_position()
	var in_attack_range := move_toward_position(target_position, approach_range, delta)

	if in_attack_range:
		try_attack(combat_target, combat_system)


func update_combat_target(delta: float) -> void:
	target_update_timer -= delta

	if target_update_timer > 0.0:
		return

	target_update_timer = TARGET_UPDATE_INTERVAL

	var nearby_cat: CombatUnit = null

	if spatial_index != null:
		nearby_cat = spatial_index.get_closest_cat(global_position, DETECTION_RANGE) as CombatUnit

	if is_instance_valid(nearby_cat):
		combat_target = nearby_cat
	else:
		combat_target = idol_target


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
		var new_position := arena_grid.move_unit(global_position, motion, COLLISION_RADIUS, avoidance_side)
		var actual_motion := new_position - old_position

		global_position = new_position

		if delta > 0.0 and not actual_motion.is_zero_approx():
			velocity = actual_motion / delta
		elif actual_motion.is_zero_approx():
			velocity = Vector2.ZERO
	else:
		global_position += motion

	return distance <= stop_distance
