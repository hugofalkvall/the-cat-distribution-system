extends Node2D

const SIZE := Vector2i(2, 2)
const PRODUCTION_TIME := 10.0

const BASIC_CAT_SCENE := preload("res://units/cats/cat_normal/cat_normal.tscn")

var cats_parent: Node2D
var spatial_index: CombatSpatialIndex
var combat_system: CombatSystem
var arena_grid: ArenaGrid
var production_timer := 0.0


func setup(new_cats_parent: Node2D, new_spatial_index: CombatSpatialIndex, new_combat_system: CombatSystem, new_arena_grid: ArenaGrid) -> void:
	cats_parent = new_cats_parent
	spatial_index = new_spatial_index
	combat_system = new_combat_system
	arena_grid = new_arena_grid


func _process(delta: float) -> void:
	if cats_parent == null:
		return

	production_timer += delta

	if production_timer >= PRODUCTION_TIME:
		production_timer = 0.0
		produce_cat()


func produce_cat() -> void:
	var cat := BASIC_CAT_SCENE.instantiate()

	cats_parent.add_child(cat)
	cat.global_position = global_position + Vector2(SIZE.x * 16 / 2.0, SIZE.y * 16 + 8)
	cat.setup(spatial_index, combat_system, arena_grid)
