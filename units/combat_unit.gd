class_name CombatUnit
extends Node2D

signal health_changed(unit: CombatUnit, current_health: float, max_health: float)
signal died(unit: CombatUnit)

@export var max_health := 10.0
@export var attack: AttackDefinition

var current_health := 0.0
var attack_cooldown_remaining := 0.0
var is_dead := false


func _ready() -> void:
	current_health = max_health


func tick_combat(delta: float) -> void:
	if attack_cooldown_remaining > 0.0:
		attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)


func try_attack(target: CombatUnit, combat_system: Node) -> bool:
	if is_dead:
		return false

	if attack == null:
		return false

	if combat_system == null:
		return false

	if attack_cooldown_remaining > 0.0:
		return false

	if not is_instance_valid(target):
		return false

	if target.is_dead:
		return false

	combat_system.perform_attack(self, target, attack)
	attack_cooldown_remaining = attack.cooldown

	return true


func take_damage(amount: float) -> void:
	if is_dead:
		return

	if amount <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)
	health_changed.emit(self, current_health, max_health)

	if current_health <= 0.0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	died.emit(self)
	queue_free()
