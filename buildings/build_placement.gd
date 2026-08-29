class_name BuildPlacement
extends Node2D

signal placement_requested(definition: BuildingDefinition, cell: Vector2i)
signal placed_building_selection_requested(building: Building)

@export var grid: ArenaGrid
@export var buildings: Node2D
@export var cats: Node2D
@export var spatial_index: CombatSpatialIndex
@export var combat_system: CombatSystem

const SNAP_MARGIN := 2.0
const INVALID_CELL := Vector2i(-1000000, -1000000)

var selected_building: BuildingDefinition
var placement_cell := INVALID_CELL
var building_context: BuildingContext


func _ready() -> void:
	if grid == null:
		push_error("BuildPlacement: grid is not assigned.")

	if buildings == null:
		push_error("BuildPlacement: buildings is not assigned.")

	if cats == null:
		push_error("BuildPlacement: cats is not assigned.")

	if spatial_index == null:
		push_error("BuildPlacement: spatial_index is not assigned.")

	if combat_system == null:
		push_error("BuildPlacement: combat_system is not assigned.")

	building_context = BuildingContext.new()
	building_context.grid = grid
	building_context.cats_parent = cats
	building_context.spatial_index = spatial_index
	building_context.combat_system = combat_system


func _process(_delta: float) -> void:
	if selected_building == null:
		return

	var building_size := selected_building.size
	var mouse_on_grid: Vector2 = grid.to_local(get_global_mouse_position())
	var mouse_cell: Vector2i = grid.world_to_grid(mouse_on_grid)

	if placement_cell == INVALID_CELL:
		placement_cell = mouse_cell - Vector2i(building_size.x / 2, building_size.y / 2)
		queue_redraw()
		return

	var placement_top_left: Vector2 = grid.grid_to_world(placement_cell)
	var placement_size_pixels := Vector2(building_size.x * grid.CELL_SIZE, building_size.y * grid.CELL_SIZE)
	var snap_area := Rect2(placement_top_left, placement_size_pixels).grow(SNAP_MARGIN)

	if snap_area.has_point(mouse_on_grid):
		return

	var new_placement_cell := placement_cell

	if mouse_on_grid.x < snap_area.position.x:
		new_placement_cell.x = mouse_cell.x
	elif mouse_on_grid.x >= snap_area.end.x:
		new_placement_cell.x = mouse_cell.x - building_size.x + 1

	if mouse_on_grid.y < snap_area.position.y:
		new_placement_cell.y = mouse_cell.y
	elif mouse_on_grid.y >= snap_area.end.y:
		new_placement_cell.y = mouse_cell.y - building_size.y + 1

	if new_placement_cell != placement_cell:
		placement_cell = new_placement_cell
		queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		cancel_placement()
		get_viewport().set_input_as_handled()
		return

	if not event is InputEventMouseButton:
		return

	if not event.pressed:
		return

	if event.button_index == MOUSE_BUTTON_RIGHT:
		cancel_placement()
		get_viewport().set_input_as_handled()
		return

	if event.button_index != MOUSE_BUTTON_LEFT:
		return

	if selected_building == null:
		var placed_object = grid.get_occupied_object_at_global_position(get_global_mouse_position())
		var building := placed_object as Building

		placed_building_selection_requested.emit(building)

		if building != null:
			get_viewport().set_input_as_handled()

		return

	if placement_cell == INVALID_CELL:
		return

	if not can_place_building(selected_building, placement_cell):
		return

	placement_requested.emit(selected_building, placement_cell)
	get_viewport().set_input_as_handled()

	if placement_cell == INVALID_CELL:
		return

	if not can_place_building(selected_building, placement_cell):
		return

	placement_requested.emit(selected_building, placement_cell)
	get_viewport().set_input_as_handled()


func select_building(definition: BuildingDefinition) -> void:
	selected_building = definition
	placement_cell = INVALID_CELL
	queue_redraw()


func cancel_placement() -> void:
	selected_building = null
	placement_cell = INVALID_CELL
	queue_redraw()


func can_place_building(definition: BuildingDefinition, cell: Vector2i) -> bool:
	if definition == null:
		return false

	if definition.scene == null:
		return false
		
	var placement_rect := grid.get_global_cell_rect(cell, definition.size)

	if spatial_index.has_unit_in_rect(placement_rect):
		return false

	if definition.size.x <= 0 or definition.size.y <= 0:
		return false

	return grid.can_place(cell, definition.size)


func place_building(definition: BuildingDefinition, cell: Vector2i) -> bool:
	if not can_place_building(definition, cell):
		return false

	var instance := definition.scene.instantiate()
	var building := instance as Building

	if building == null:
		instance.queue_free()
		push_error("Building scene root must extend Building.")
		return false

	building.setup(definition, building_context)

	buildings.add_child(building)

	var grid_position := grid.grid_to_world(cell)
	building.global_position = grid.to_global(grid_position)

	if not grid.occupy_cells(cell, definition.size, building):
		building.queue_free()
		return false

	queue_redraw()
	selected_building = null
	return true


func _draw() -> void:
	if selected_building == null:
		return

	if placement_cell == INVALID_CELL:
		return

	var building_size := selected_building.size
	var top_left_on_grid := grid.grid_to_world(placement_cell)
	var global_top_left := grid.to_global(top_left_on_grid)
	var local_top_left := to_local(global_top_left)
	var preview_size := Vector2(building_size.x * grid.CELL_SIZE, building_size.y * grid.CELL_SIZE)

	var preview_color: Color

	if can_place_building(selected_building, placement_cell):
		preview_color = Color(0, 1, 0, 0.35)
	else:
		preview_color = Color(1, 0, 0, 0.35)

	draw_rect(Rect2(local_top_left, preview_size), preview_color, true)

func set_production_enabled(enabled: bool) -> void:
	if building_context == null:
		return

	building_context.production_enabled = enabled
