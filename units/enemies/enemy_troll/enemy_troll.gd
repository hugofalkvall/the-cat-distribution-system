class_name EnemyTroll
extends Node2D

const MOVE_SPEED := 18.0
const ACCELERATION := 60.0
const STOP_DISTANCE := 12.0

# Idol is currently 2x2 cells = 32x32 pixels,
# and its position represents its top-left corner.
const IDOL_CENTER_OFFSET := Vector2(16, 16)

var target: Node2D
var velocity := Vector2.ZERO


func setup(new_target: Node2D) -> void:
	target = new_target


func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	move_toward_target(delta)


func move_toward_target(delta: float) -> void:
	var target_position: Vector2 = (
		target.global_position
		+ IDOL_CENTER_OFFSET
	)

	var distance: float = global_position.distance_to(
		target_position
	)

	if distance <= STOP_DISTANCE:
		velocity = velocity.move_toward(
			Vector2.ZERO,
			ACCELERATION * delta
		)
		return

	var direction: Vector2 = global_position.direction_to(
		target_position
	)

	var desired_velocity := direction * MOVE_SPEED

	velocity = velocity.move_toward(
		desired_velocity,
		ACCELERATION * delta
	)

	global_position += velocity * delta
