class_name EnemyTroll
extends Node2D

const MOVE_SPEED := 18.0
const ACCELERATION := 60.0

const IDOL_STOP_DISTANCE := 12.0
const CAT_STOP_DISTANCE := 8.0

const DETECTION_RANGE := 80.0
const TARGET_UPDATE_INTERVAL := 0.2

const IDOL_CENTER_OFFSET := Vector2(16, 16)

var idol_target: Node2D
var combat_target: Node2D = null

var spatial_index: CombatSpatialIndex

var velocity := Vector2.ZERO
var target_update_timer := 0.0


func setup(new_idol_target: Node2D, new_spatial_index: CombatSpatialIndex) -> void:
	idol_target = new_idol_target
	spatial_index = new_spatial_index
	target_update_timer = randf_range(0.0, TARGET_UPDATE_INTERVAL)


func _process(delta: float) -> void:
	if not is_instance_valid(idol_target):
		return

	update_combat_target(delta)

	if is_instance_valid(combat_target):
		move_toward_position(combat_target.global_position, CAT_STOP_DISTANCE, delta)
	else:
		move_toward_position(idol_target.global_position + IDOL_CENTER_OFFSET, IDOL_STOP_DISTANCE, delta)


func update_combat_target(delta: float) -> void:
	if spatial_index == null:
		return

	target_update_timer -= delta

	if target_update_timer > 0.0:
		return

	target_update_timer = TARGET_UPDATE_INTERVAL
	combat_target = spatial_index.get_closest_cat(global_position, DETECTION_RANGE)


func move_toward_position(destination: Vector2, stop_distance: float, delta: float) -> void:
	var distance := global_position.distance_to(destination)
	var desired_velocity := Vector2.ZERO

	if distance > stop_distance:
		var direction := global_position.direction_to(destination)
		desired_velocity = direction * MOVE_SPEED

	velocity = velocity.move_toward(desired_velocity, ACCELERATION * delta)
	global_position += velocity * delta
