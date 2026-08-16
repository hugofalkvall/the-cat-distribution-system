class_name CombatSystem
extends Node

@export var spatial_index: CombatSpatialIndex
@export var attack_behaviors_parent: Node2D


func perform_attack(attacker: CombatUnit, target: Damageable, attack_state: AttackState) -> bool:
	if not is_instance_valid(attacker):
		return false

	if not is_instance_valid(target):
		return false

	if attacker.is_dead or target.is_dead:
		return false

	if attack_state == null or attack_state.definition == null:
		return false

	var attack_definition := attack_state.definition

	if attack_definition.behavior_scene != null:
		if attack_behaviors_parent == null:
			resolve_attack(attacker, target, attack_state, target.get_combat_position())
			return true

		var instance := attack_definition.behavior_scene.instantiate()
		var behavior := instance as AttackBehavior

		if behavior == null:
			instance.queue_free()
			resolve_attack(attacker, target, attack_state, target.get_combat_position())
			return true

		attack_behaviors_parent.add_child(behavior)
		behavior.setup(attacker, target, attack_state, self)

		return true

	resolve_attack(attacker, target, attack_state, target.get_combat_position())

	return true


func resolve_attack(attacker, target, attack_state: AttackState, impact_position: Vector2) -> void:
	if attack_state == null or attack_state.definition == null:
		return

	for effect in attack_state.definition.effects:
		if effect == null:
			continue

		effect.apply(attacker, target, attack_state, self, impact_position)
