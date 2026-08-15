class_name AttackState
extends RefCounted

var definition: AttackDefinition

var ready_at_msec := 0

var damage_multiplier := 1.0
var range_multiplier := 1.0
var cooldown_multiplier := 1.0


func _init(new_definition: AttackDefinition) -> void:
	definition = new_definition


func is_ready() -> bool:
	return Time.get_ticks_msec() >= ready_at_msec


func start_cooldown() -> void:
	ready_at_msec = Time.get_ticks_msec() + int(get_cooldown() * 1000.0)


func get_range() -> float:
	return maxf(definition.range * range_multiplier, 0.0)


func get_cooldown() -> float:
	return maxf(definition.cooldown * cooldown_multiplier, 0.0)
