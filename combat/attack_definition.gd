class_name AttackDefinition
extends Resource

enum AttackType {
	MELEE,
	RANGED,
	AREA,
	PROJECTILE
}

@export var attack_type: AttackType = AttackType.MELEE
@export var damage := 1.0
@export var range := 8.0
@export var cooldown := 1.0
