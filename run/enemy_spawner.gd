extends Node

const SPAWN_TIME := 10.0
const SPAWN_MARGIN := 16.0

@export var enemy_scene: PackedScene
@export var enemies: Node2D
@export var idol: Damageable
@export var grid: ArenaGrid
@export var spatial_index: CombatSpatialIndex
@export var combat_system: CombatSystem

@onready var timer: Timer = $Timer


func _ready() -> void:
	timer.wait_time = SPAWN_TIME
	timer.timeout.connect(spawn_enemy)
	timer.start()


func spawn_enemy() -> void:
	var enemy := enemy_scene.instantiate() as EnemyTroll

	if enemy == null:
		return

	enemies.add_child(enemy)

	var spawn_position := get_random_spawn_position()

	enemy.global_position = grid.to_global(spawn_position)
	enemy.setup(idol, spatial_index, combat_system, grid)


func get_random_spawn_position() -> Vector2:
	var left := float(grid.GRID_ORIGIN.x)
	var right := float(grid.GRID_ORIGIN.x + grid.GRID_WIDTH * grid.CELL_SIZE)
	var top := float(grid.GRID_ORIGIN.y)
	var bottom := float(grid.GRID_ORIGIN.y + grid.GRID_HEIGHT * grid.CELL_SIZE)

	var side := randi_range(0, 2)

	match side:
		0:
			return Vector2(randf_range(left, right), top - SPAWN_MARGIN)

		1:
			return Vector2(right + SPAWN_MARGIN, randf_range(top, bottom))

		_:
			return Vector2(left - SPAWN_MARGIN, randf_range(top, bottom))
