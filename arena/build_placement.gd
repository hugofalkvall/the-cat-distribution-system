extends Node2D

@export var grid: ArenaGrid
@export var buildings: Node2D
@export var cat_house_scene: PackedScene

var hovered_cell := Vector2i(-1, -1)


func _process(_delta: float) -> void:
	var mouse_position_on_grid := grid.to_local(get_global_mouse_position())
	var new_hovered_cell := grid.world_to_grid(mouse_position_on_grid)

	if new_hovered_cell != hovered_cell:
		hovered_cell = new_hovered_cell
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.pressed
	):
		place_cat_house()


func place_cat_house() -> void:
	var size := Vector2i(2, 2)

	if not grid.can_place(hovered_cell, size):
		return

	var cat_house := cat_house_scene.instantiate()

	buildings.add_child(cat_house)

	var grid_position := grid.grid_to_world(hovered_cell)
	cat_house.global_position = grid.to_global(grid_position)

	grid.occupy_cells(
		hovered_cell,
		size,
		cat_house
	)

	queue_redraw()


func _draw() -> void:
	var size := Vector2i(2, 2)

	if not grid.is_in_bounds(hovered_cell):
		return

	var top_left_on_grid := grid.grid_to_world(hovered_cell)
	var global_top_left := grid.to_global(top_left_on_grid)
	var local_top_left := to_local(global_top_left)

	var preview_size := Vector2(
		size.x * grid.CELL_SIZE,
		size.y * grid.CELL_SIZE
	)

	var preview_color: Color

	if grid.can_place(hovered_cell, size):
		preview_color = Color(0, 1, 0, 0.35)
	else:
		preview_color = Color(1, 0, 0, 0.35)

	draw_rect(
		Rect2(local_top_left, preview_size),
		preview_color,
		true
	)
