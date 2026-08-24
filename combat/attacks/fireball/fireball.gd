class_name Fireball
extends AttackBehavior

@export var speed := 100.0
@export var hit_distance := 4.0

var destination := Vector2.ZERO


func begin() -> void:
	if not is_instance_valid(attacker):
		queue_free()
		return

	global_position = attacker.get_combat_position()

	if is_instance_valid(target):
		destination = target.get_combat_position()
	else:
		destination = initial_target_position


func _process(delta: float) -> void:
	if is_instance_valid(target):
		destination = target.get_combat_position()

	var distance_to_target := global_position.distance_to(destination)

	if distance_to_target <= hit_distance:
		resolve_impact()
		return

	global_position = global_position.move_toward(destination, speed * delta)


func resolve_impact() -> void:
	var impact_position := destination

	resolve(impact_position)
	queue_free()
