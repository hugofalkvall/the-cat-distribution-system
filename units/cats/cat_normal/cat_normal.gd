extends Node2D

const MOVE_SPEED := 25.0
const ACCELERATION := 80.0

const WANDER_RADIUS := 48.0
const MIN_TARGET_DISTANCE := 20.0
const TARGET_REACHED_DISTANCE := 5.0

const ARENA_MIN := Vector2(128, 32)
const ARENA_MAX := Vector2(512, 352)

var home_position: Vector2
var target_position: Vector2
var velocity := Vector2.ZERO


func setup() -> void:
	home_position = global_position
	choose_new_target()


func _process(delta: float) -> void:
	move(delta)


func move(delta: float) -> void:
	var direction := global_position.direction_to(target_position)
	var desired_velocity := direction * MOVE_SPEED

	velocity = velocity.move_toward(
		desired_velocity,
		ACCELERATION * delta
	)

	global_position += velocity * delta

	if global_position.distance_to(target_position) <= TARGET_REACHED_DISTANCE:
		choose_new_target()


func choose_new_target() -> void:
	var new_target := home_position

	while new_target.distance_to(home_position) < MIN_TARGET_DISTANCE:
		var angle := randf_range(0.0, TAU)
		var distance := randf_range(
			MIN_TARGET_DISTANCE,
			WANDER_RADIUS
		)

		new_target = home_position + Vector2(
			cos(angle),
			sin(angle)
		) * distance

	new_target.x = clamp(
		new_target.x,
		ARENA_MIN.x,
		ARENA_MAX.x
	)

	new_target.y = clamp(
		new_target.y,
		ARENA_MIN.y,
		ARENA_MAX.y
	)

	target_position = new_target
