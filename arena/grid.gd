extends Node2D

const CELL_SIZE := 16
const GRID_WIDTH := 24
const GRID_HEIGHT := 20
const GRID_ORIGIN := Vector2(128, 32)

var occupied_cells: Dictionary = {}

# Translate grid values to real engine x,y pos
func grid_to_world(cell: Vector2i) -> Vector2:
	return GRID_ORIGIN + Vector2(cell) * CELL_SIZE

# Translate real engine x,y values to grid pos
func world_to_grid(position: Vector2) -> Vector2i:
	var local_position := position - GRID_ORIGIN

	return Vector2i(
		floor(local_position.x / CELL_SIZE),
		floor(local_position.y / CELL_SIZE)
	)

# Check if element exsists in current x,y pos 
func is_cell_free(cell: Vector2i) -> bool:
	return not occupied_cells.has(cell)

# Add element to a x,y cell
func occupy_cell(cell: Vector2i, building) -> void:
	occupied_cells[cell] = building

# Remove element from a x,y cell 
func free_cell(cell: Vector2i) -> void:
	occupied_cells.erase(cell)
