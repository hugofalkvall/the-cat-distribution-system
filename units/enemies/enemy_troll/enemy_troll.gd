class_name EnemyTroll
extends EnemyUnit

const MOVE_SPEED := 18.0
const ACCELERATION := 60.0
const COLLISION_RADIUS := 4.0

const DETECTION_RANGE := 80.0
const TARGET_UPDATE_INTERVAL := 0.2

var combat_target: Damageable = null

var target_update_timer := 0.0
var avoidance_side := 1.0


func on_enemy_setup() -> void:
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
	var use_idol_flow := combat_target == idol_target

	var in_attack_range := move_toward_position(
		target_position,
		approach_range,
		delta,
		use_idol_flow
	)

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


func move_toward_position(destination: Vector2, stop_distance: float, delta: float, use_idol_flow: bool = false) -> bool:
	var distance := global_position.distance_to(destination)
	var desired_velocity := Vector2.ZERO

	if distance > stop_distance:
		var direction := get_navigation_direction(
			arena_grid,
			destination,
			stop_distance,
			COLLISION_RADIUS,
			delta,
			use_idol_flow
		)

		desired_velocity = direction * MOVE_SPEED

	velocity = velocity.move_toward(
		desired_velocity,
		ACCELERATION * delta
	)

	var motion := velocity * delta

	if arena_grid != null:
		var old_position := global_position

		var new_position := arena_grid.move_unit(
			global_position,
			motion,
			COLLISION_RADIUS,
			avoidance_side
		)

		var actual_motion := new_position - old_position

		global_position = new_position

		if delta > 0.0 and not actual_motion.is_zero_approx():
			velocity = actual_motion / delta
		elif actual_motion.is_zero_approx():
			velocity = Vector2.ZERO
	else:
		global_position += motion

	return distance <= stop_distance
