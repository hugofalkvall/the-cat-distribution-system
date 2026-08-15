class_name CombatSystem
extends Node


func perform_attack(attacker: Node2D, target: CombatUnit, attack_definition: AttackDefinition) -> void:
	if not is_instance_valid(attacker):
		return

	if not is_instance_valid(target):
		return

	if target.is_dead:
		return

	match attack_definition.attack_type:
		AttackDefinition.AttackType.MELEE:
			target.take_damage(attack_definition.damage)
