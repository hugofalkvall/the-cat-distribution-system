class_name ArenaGrid
extends Node2D

const CELL_SIZE := 16
const GRID_WIDTH := 24
const GRID_HEIGHT := 20
const GRID_ORIGIN := Vector2(128, 32)

const IDOL_SIZE := Vector2i(2, 2)

@export var idol: Sprite2D

var occupied_cells: Dictionary = {}


func _ready() -> void:
	var idol_cell := world_to_grid(to_local(idol.global_position))
	occupy_cells(idol_cell, IDOL_SIZE, idol)


func grid_to_world(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell) * CELL_SIZE


func world_to_grid(position: Vector2) -> Vector2i:
	var local_position := position - GRID_ORIGIN

	return Vector2i(
		floor(local_position.x / CELL_SIZE),
		floor(local_position.y / CELL_SIZE)
	)


func is_in_bounds(cell: Vector2i) -> bool:
	return (
		cell.x >= 0
		and cell.x < GRID_WIDTH
		and cell.y >= 0
		and cell.y < GRID_HEIGHT
	)


func is_cell_free(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and not occupied_cells.has(cell)


func can_place(cell: Vector2i, size: Vector2i) -> bool:
	for y in range(size.y):
		for x in range(size.x):
			var checked_cell := cell + Vector2i(x, y)

			if not is_cell_free(checked_cell):
				return false

	return true


func occupy_cells(
	start_cell: Vector2i,
	size: Vector2i,
	placed_object
) -> bool:
	if not can_place(start_cell, size):
		return false

	for y in range(size.y):
		for x in range(size.x):
			var cell := start_cell + Vector2i(x, y)
			occupied_cells[cell] = placed_object

	return true


func free_cells(
	start_cell: Vector2i,
	size: Vector2i,
	placed_object
) -> void:
	for y in range(size.y):
		for x in range(size.x):
			var cell := start_cell + Vector2i(x, y)

			if occupied_cells.get(cell) == placed_object:
				occupied_cells.erase(cell)
