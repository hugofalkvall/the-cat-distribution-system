extends Node2D

const CELL_SIZE := 16
const GRID_WIDTH := 24
const GRID_HEIGHT := 20
const GRID_ORIGIN := Vector2(128, 32)

var occupied_cells: Dictionary = {}
var hovered_cell := Vector2i(-1, -1)


func _process(_delta: float) -> void:
	var new_hovered_cell := world_to_grid(get_local_mouse_position())

	if new_hovered_cell != hovered_cell:
		hovered_cell = new_hovered_cell
		queue_redraw()


func _draw() -> void:
	var grid_size := Vector2(
		GRID_WIDTH * CELL_SIZE,
		GRID_HEIGHT * CELL_SIZE
	)

	# Vertical lines
	for x in range(GRID_WIDTH + 1):
		var x_pos := GRID_ORIGIN.x + x * CELL_SIZE
		draw_line(
			Vector2(x_pos, GRID_ORIGIN.y),
			Vector2(x_pos, GRID_ORIGIN.y + grid_size.y),
			Color(1, 1, 1, 0.25)
		)

	# Horizontal lines
	for y in range(GRID_HEIGHT + 1):
		var y_pos := GRID_ORIGIN.y + y * CELL_SIZE
		draw_line(
			Vector2(GRID_ORIGIN.x, y_pos),
			Vector2(GRID_ORIGIN.x + grid_size.x, y_pos),
			Color(1, 1, 1, 0.25)
		)

	# Hovered cell
	if is_in_bounds(hovered_cell):
		draw_rect(
			Rect2(
				grid_to_world(hovered_cell),
				Vector2(CELL_SIZE, CELL_SIZE)
			),
			Color(1, 1, 1, 0.2),
			true
		)


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


func can_place(cell: Vector2i, footprint: Vector2i) -> bool:
	for y in range(footprint.y):
		for x in range(footprint.x):
			var checked_cell := cell + Vector2i(x, y)

			if not is_cell_free(checked_cell):
				return false

	return true


func occupy_cell(cell: Vector2i, building) -> void:
	occupied_cells[cell] = building


func free_cell(cell: Vector2i) -> void:
	occupied_cells.erase(cell)
