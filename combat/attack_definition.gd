class_name AttackDefinition
extends Resource

@export var attack_name: StringName = &""
@export var range := 8.0
@export var cooldown := 1.0
@export var behavior_scene: PackedScene
@export var effects: Array[AttackEffectDefinition] = []
