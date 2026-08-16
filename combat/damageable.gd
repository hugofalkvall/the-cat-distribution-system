class_name Damageable
extends Node2D

signal health_changed(damageable: Damageable, current_health: float, max_health: float)
signal died(damageable: Damageable)

@export var max_health := 10.0
@export var combat_radius := 0.0
@export var combat_position_offset := Vector2.ZERO

var current_health := 0.0
var is_dead := false


func _ready() -> void:
	current_health = max_health


func get_combat_position() -> Vector2:
	return global_position + combat_position_offset


func take_damage(amount: float) -> void:
	if is_dead:
		return

	if amount <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)

	health_changed.emit(self, current_health, max_health)
	queue_redraw()

	if current_health <= 0.0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	died.emit(self)
	on_death()


func on_death() -> void:
	pass
