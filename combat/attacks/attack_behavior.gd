class_name AttackBehavior
extends Node2D

var attacker: CombatUnit
var target: Damageable
var attack_state: AttackState
var combat_system: CombatSystem

var initial_target_position := Vector2.ZERO


func setup(new_attacker: CombatUnit, new_target: Damageable, new_attack_state: AttackState, new_combat_system: CombatSystem) -> void:
	attacker = new_attacker
	target = new_target
	attack_state = new_attack_state
	combat_system = new_combat_system

	if is_instance_valid(target):
		initial_target_position = target.get_combat_position()
	elif is_instance_valid(attacker):
		initial_target_position = attacker.global_position

	begin()


func begin() -> void:
	pass


func resolve(impact_position: Vector2) -> void:
	if combat_system == null:
		return

	if attack_state == null:
		return

	combat_system.resolve_attack(attacker, target, attack_state, impact_position)
