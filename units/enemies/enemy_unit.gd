class_name EnemyUnit
extends CombatUnit

@export var currency_reward := 1

var idol_target: Damageable
var arena_grid: ArenaGrid
var spatial_index: CombatSpatialIndex
var combat_system: CombatSystem


func setup(new_idol_target: Damageable, new_spatial_index: CombatSpatialIndex, new_combat_system: CombatSystem, new_arena_grid: ArenaGrid) -> void:
	idol_target = new_idol_target
	spatial_index = new_spatial_index
	combat_system = new_combat_system
	arena_grid = new_arena_grid

	on_enemy_setup()


func on_enemy_setup() -> void:
	pass
