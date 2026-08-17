class_name ArenaGrid
extends Node2D

const CELL_SIZE := 16
const GRID_WIDTH := 24
const GRID_HEIGHT := 20
const GRID_ORIGIN := Vector2(128, 32)

const IDOL_SIZE := Vector2i(2, 2)

const STEERING_ANGLE_STEP := PI / 12.0
const STEERING_STEPS := 6

@export var idol: Sprite2D

var occupied_cells: Dictionary = {}


func _ready() -> void:
	var idol_cell := world_to_grid(to_local(idol.global_position))
	occupy_cells(idol_cell, IDOL_SIZE, idol)


func grid_to_world(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell) * CELL_SIZE


func world_to_grid(position: Vector2) -> Vector2i:
	var local_position := position - GRID_ORIGIN
	return Vector2i(floor(local_position.x / CELL_SIZE), floor(local_position.y / CELL_SIZE))


func is_in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < GRID_WIDTH and cell.y >= 0 and cell.y < GRID_HEIGHT


func is_cell_free(cell: Vector2i) -> bool:
	return is_in_bounds(cell) and not occupied_cells.has(cell)


func can_place(cell: Vector2i, size: Vector2i) -> bool:
	for y in range(size.y):
		for x in range(size.x):
			var checked_cell := cell + Vector2i(x, y)

			if not is_cell_free(checked_cell):
				return false

	return true


func occupy_cells(start_cell: Vector2i, size: Vector2i, placed_object) -> bool:
	if not can_place(start_cell, size):
		return false

	for y in range(size.y):
		for x in range(size.x):
			var cell := start_cell + Vector2i(x, y)
			occupied_cells[cell] = placed_object

	return true


func free_cells(start_cell: Vector2i, size: Vector2i, placed_object) -> void:
	for y in range(size.y):
		for x in range(size.x):
			var cell := start_cell + Vector2i(x, y)

			if occupied_cells.get(cell) == placed_object:
				occupied_cells.erase(cell)


func is_global_position_walkable(global_position: Vector2, radius: float) -> bool:
	var local_position := to_local(global_position)
	var radius_vector := Vector2(radius, radius)

	var min_cell := world_to_grid(local_position - radius_vector)
	var max_cell := world_to_grid(local_position + radius_vector)

	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var cell := Vector2i(x, y)

			if not is_in_bounds(cell):
				continue

			if not occupied_cells.has(cell):
				continue

			var cell_position := grid_to_world(cell)
			var cell_rect := Rect2(cell_position, Vector2(CELL_SIZE, CELL_SIZE))

			var closest_point := Vector2(
				clamp(local_position.x, cell_rect.position.x, cell_rect.end.x),
				clamp(local_position.y, cell_rect.position.y, cell_rect.end.y)
			)

			if local_position.distance_squared_to(closest_point) < radius * radius:
				return false

	return true

func get_global_cell_rect(start_cell: Vector2i, size: Vector2i = Vector2i.ONE) -> Rect2:
	var local_position := grid_to_world(start_cell)
	var global_position := to_global(local_position)
	var pixel_size := Vector2(size.x * CELL_SIZE, size.y * CELL_SIZE)

	return Rect2(global_position, pixel_size)

func move_unit(current_global_position: Vector2, motion: Vector2, radius: float, preferred_side: float) -> Vector2:
	if motion.is_zero_approx():
		return current_global_position

	var direct_candidate := current_global_position + motion

	if is_global_position_walkable(direct_candidate, radius):
		return direct_candidate

	for step in range(1, STEERING_STEPS + 1):
		var angle := STEERING_ANGLE_STEP * step

		var preferred_motion := motion.rotated(angle * preferred_side)
		var preferred_candidate := current_global_position + preferred_motion

		if is_global_position_walkable(preferred_candidate, radius):
			return preferred_candidate

		var opposite_motion := motion.rotated(-angle * preferred_side)
		var opposite_candidate := current_global_position + opposite_motion

		if is_global_position_walkable(opposite_candidate, radius):
			return opposite_candidate

	return current_global_position
