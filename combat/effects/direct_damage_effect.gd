class_name DirectDamageEffect
extends AttackEffectDefinition

@export var damage := 1.0


func apply(attacker, target, attack_state: AttackState, combat_system: CombatSystem, impact_position: Vector2) -> void:
	if not is_instance_valid(target):
		return

	if not target is Damageable:
		return

	if target.is_dead:
		return

	var final_damage := damage * attack_state.damage_multiplier
	target.take_damage(final_damage)
