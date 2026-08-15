extends Node2D

@export var grid: ArenaGrid
@export var buildings: Node2D
@export var cat_house_scene: PackedScene
@export var cats: Node2D
@export var spatial_index: CombatSpatialIndex
@export var combat_system: CombatSystem

const BUILDING_SIZE := Vector2i(2, 2)
const SNAP_MARGIN := 2.0

var placement_cell := Vector2i(-1, -1)


func _process(_delta: float) -> void:
	var mouse_on_grid: Vector2 = grid.to_local(get_global_mouse_position())
	var mouse_cell: Vector2i = grid.world_to_grid(mouse_on_grid)

	if placement_cell == Vector2i(-1, -1):
		placement_cell = mouse_cell - Vector2i(BUILDING_SIZE.x / 2, BUILDING_SIZE.y / 2)
		queue_redraw()
		return

	var placement_top_left: Vector2 = grid.grid_to_world(placement_cell)
	var placement_size_pixels := Vector2(BUILDING_SIZE.x * grid.CELL_SIZE, BUILDING_SIZE.y * grid.CELL_SIZE)
	var snap_area := Rect2(placement_top_left, placement_size_pixels).grow(SNAP_MARGIN)

	if snap_area.has_point(mouse_on_grid):
		return

	var new_placement_cell := placement_cell

	if mouse_on_grid.x < snap_area.position.x:
		new_placement_cell.x = mouse_cell.x
	elif mouse_on_grid.x >= snap_area.end.x:
		new_placement_cell.x = mouse_cell.x - BUILDING_SIZE.x + 1

	if mouse_on_grid.y < snap_area.position.y:
		new_placement_cell.y = mouse_cell.y
	elif mouse_on_grid.y >= snap_area.end.y:
		new_placement_cell.y = mouse_cell.y - BUILDING_SIZE.y + 1

	if new_placement_cell != placement_cell:
		placement_cell = new_placement_cell
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		place_cat_house()


func place_cat_house() -> void:
	if not grid.can_place(placement_cell, BUILDING_SIZE):
		return

	var cat_house := cat_house_scene.instantiate()

	buildings.add_child(cat_house)

	var grid_position: Vector2 = grid.grid_to_world(placement_cell)
	cat_house.global_position = grid.to_global(grid_position)

	cat_house.setup(cats, spatial_index, combat_system)

	grid.occupy_cells(placement_cell, BUILDING_SIZE, cat_house)

	queue_redraw()


func _draw() -> void:
	if placement_cell == Vector2i(-1, -1):
		return

	var top_left_on_grid: Vector2 = grid.grid_to_world(placement_cell)
	var global_top_left: Vector2 = grid.to_global(top_left_on_grid)
	var local_top_left: Vector2 = to_local(global_top_left)
	var preview_size := Vector2(BUILDING_SIZE.x * grid.CELL_SIZE, BUILDING_SIZE.y * grid.CELL_SIZE)

	var preview_color: Color

	if grid.can_place(placement_cell, BUILDING_SIZE):
		preview_color = Color(0, 1, 0, 0.35)
	else:
		preview_color = Color(1, 0, 0, 0.35)

	draw_rect(Rect2(local_top_left, preview_size), preview_color, true)
