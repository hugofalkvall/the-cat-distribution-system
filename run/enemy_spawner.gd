class_name EnemySpawner
extends Node

const SPAWN_MARGIN := 16.0

const SPAWN_NORTH := 1
const SPAWN_EAST := 2
const SPAWN_WEST := 4

@export var enemies: Node2D
@export var idol: Damageable
@export var grid: ArenaGrid
@export var spatial_index: CombatSpatialIndex
@export var combat_system: CombatSystem


func spawn_enemy(enemy_scene: PackedScene, spawn_sides: int) -> EnemyUnit:
	if enemy_scene == null:
		return null

	var instance := enemy_scene.instantiate()
	var enemy := instance as EnemyUnit

	if enemy == null:
		instance.queue_free()
		push_error("Enemy scene root must extend EnemyUnit.")
		return null

	enemies.add_child(enemy)

	var spawn_position := get_random_spawn_position(spawn_sides)

	enemy.global_position = grid.to_global(spawn_position)
	enemy.setup(idol, spatial_index, combat_system, grid)

	return enemy


func get_random_spawn_position(spawn_sides: int) -> Vector2:
	var available_sides: Array[int] = []

	if (spawn_sides & SPAWN_NORTH) != 0:
		available_sides.append(SPAWN_NORTH)

	if (spawn_sides & SPAWN_EAST) != 0:
		available_sides.append(SPAWN_EAST)

	if (spawn_sides & SPAWN_WEST) != 0:
		available_sides.append(SPAWN_WEST)

	if available_sides.is_empty():
		available_sides = [SPAWN_NORTH, SPAWN_EAST, SPAWN_WEST]

	var side: int = available_sides.pick_random()

	var left := float(grid.GRID_ORIGIN.x)
	var right := float(grid.GRID_ORIGIN.x + grid.GRID_WIDTH * grid.CELL_SIZE)
	var top := float(grid.GRID_ORIGIN.y)
	var bottom := float(grid.GRID_ORIGIN.y + grid.GRID_HEIGHT * grid.CELL_SIZE)

	match side:
		SPAWN_NORTH:
			return Vector2(randf_range(left, right), top - SPAWN_MARGIN)

		SPAWN_EAST:
			return Vector2(right + SPAWN_MARGIN, randf_range(top, bottom))

		_:
			return Vector2(left - SPAWN_MARGIN, randf_range(top, bottom))
