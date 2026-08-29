class_name ArenaPathfinder
extends Node

const INVALID_CELL := Vector2i(-1000000, -1000000)

const CARDINAL_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1)
]

const ALL_DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),
	Vector2i(-1, 0),
	Vector2i(0, 1),
	Vector2i(0, -1),
	Vector2i(1, 1),
	Vector2i(1, -1),
	Vector2i(-1, 1),
	Vector2i(-1, -1)
]

@export var grid: ArenaGrid
@export var idol: Damageable

var astar: AStarGrid2D = AStarGrid2D.new()
var navigation_dirty := true

var idol_flow_directions: Dictionary = {}


func _ready() -> void:
	if grid == null:
		push_error("ArenaPathfinder: grid is not assigned.")
		return

	if idol == null:
		push_error("ArenaPathfinder: idol is not assigned.")
		return

	grid.navigation_changed.connect(mark_dirty)


func mark_dirty() -> void:
	navigation_dirty = true


func rebuild_if_dirty() -> void:
	if not navigation_dirty:
		return

	rebuild_navigation()


func rebuild_navigation() -> void:
	if grid == null:
		return

	astar = AStarGrid2D.new()
	astar.region = Rect2i(
		0,
		0,
		grid.GRID_WIDTH,
		grid.GRID_HEIGHT
	)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.update()

	for cell_variant in grid.occupied_cells.keys():
		var cell: Vector2i = cell_variant

		if grid.is_in_bounds(cell):
			astar.set_point_solid(cell, true)

	build_idol_flow_field()

	navigation_dirty = false


func global_to_cell(global_position: Vector2) -> Vector2i:
	var local_position := grid.to_local(global_position)
	return grid.world_to_grid(local_position)


func cell_to_global_center(cell: Vector2i) -> Vector2:
	var local_position := grid.grid_to_world(cell)
	local_position += Vector2(grid.CELL_SIZE, grid.CELL_SIZE) / 2.0

	return grid.to_global(local_position)


func clamp_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(cell.x, 0, grid.GRID_WIDTH - 1),
		clampi(cell.y, 0, grid.GRID_HEIGHT - 1)
	)


func is_walkable_cell(cell: Vector2i) -> bool:
	if not grid.is_in_bounds(cell):
		return false

	return not astar.is_point_solid(cell)


func get_goal_cell(from_global_position: Vector2, destination: Vector2, stop_distance: float) -> Vector2i:
	var adjusted_destination := destination
	var distance := from_global_position.distance_to(destination)

	if stop_distance > 0.0 and distance > stop_distance:
		adjusted_destination = destination + destination.direction_to(
			from_global_position
		) * stop_distance

	var target_cell := clamp_cell(global_to_cell(adjusted_destination))

	if is_walkable_cell(target_cell):
		return target_cell

	return find_nearest_walkable_cell(target_cell)


func find_nearest_walkable_cell(origin: Vector2i) -> Vector2i:
	var best_cell := INVALID_CELL
	var best_distance_squared := INF

	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var candidate := Vector2i(x, y)

			if not is_walkable_cell(candidate):
				continue

			var difference := candidate - origin
			var distance_squared := (
				difference.x * difference.x
				+ difference.y * difference.y
			)

			if distance_squared >= best_distance_squared:
				continue

			best_distance_squared = distance_squared
			best_cell = candidate

	return best_cell


func find_path(from_global_position: Vector2, destination: Vector2, stop_distance: float, unit_radius: float) -> PackedVector2Array:
	var start_cell := clamp_cell(global_to_cell(from_global_position))

	if not is_walkable_cell(start_cell):
		start_cell = find_nearest_walkable_cell(start_cell)

	var goal_cell := get_goal_cell(
		from_global_position,
		destination,
		stop_distance
	)

	if start_cell == INVALID_CELL or goal_cell == INVALID_CELL:
		return PackedVector2Array()

	var id_path := astar.get_id_path(
		start_cell,
		goal_cell,
		true
	)

	if id_path.is_empty():
		return PackedVector2Array()

	var raw_path := PackedVector2Array()

	for index in range(1, id_path.size()):
		raw_path.append(cell_to_global_center(id_path[index]))

	return simplify_path(
		from_global_position,
		raw_path,
		unit_radius
	)


func simplify_path(from_global_position: Vector2, raw_path: PackedVector2Array, unit_radius: float) -> PackedVector2Array:
	if raw_path.size() <= 1:
		return raw_path

	var result := PackedVector2Array()
	var anchor := from_global_position
	var index := 0

	while index < raw_path.size():
		var furthest_visible_index := index

		for candidate_index in range(
			raw_path.size() - 1,
			index,
			-1
		):
			if has_clear_path(
				anchor,
				raw_path[candidate_index],
				unit_radius
			):
				furthest_visible_index = candidate_index
				break

		result.append(raw_path[furthest_visible_index])
		anchor = raw_path[furthest_visible_index]
		index = furthest_visible_index + 1

	return result


func has_clear_path(from_global_position: Vector2, destination: Vector2, unit_radius: float,stop_distance: float = 0.0) -> bool:
	var distance := from_global_position.distance_to(destination)
	var travel_distance := maxf(distance - stop_distance, 0.0)

	if travel_distance <= 0.0:
		return true

	var direction := from_global_position.direction_to(destination)
	var step_size := float(grid.CELL_SIZE) * 0.25
	var sample_count := maxi(
		ceili(travel_distance / step_size),
		1
	)

	for index in range(1, sample_count + 1):
		var sample_distance := minf(
			float(index) * step_size,
			travel_distance
		)

		var sample_position := (
			from_global_position
			+ direction * sample_distance
		)

		if not grid.is_global_position_walkable(
			sample_position,
			unit_radius
		):
			return false

	return true


func build_idol_flow_field() -> void:
	idol_flow_directions.clear()

	if idol == null:
		return

	var distances: Dictionary = {}
	var queue: Array[Vector2i] = []

	for cell_variant in grid.occupied_cells.keys():
		var idol_cell: Vector2i = cell_variant

		if grid.occupied_cells[idol_cell] != idol:
			continue

		for direction in CARDINAL_DIRECTIONS:
			var neighbor := idol_cell + direction

			if not is_walkable_cell(neighbor):
				continue

			if distances.has(neighbor):
				continue

			distances[neighbor] = 0
			queue.append(neighbor)

	var queue_index := 0

	while queue_index < queue.size():
		var current := queue[queue_index]
		queue_index += 1

		var current_distance: int = distances[current]

		for direction in CARDINAL_DIRECTIONS:
			var neighbor := current + direction

			if not is_walkable_cell(neighbor):
				continue

			if distances.has(neighbor):
				continue

			distances[neighbor] = current_distance + 1
			queue.append(neighbor)

	for y in range(grid.GRID_HEIGHT):
		for x in range(grid.GRID_WIDTH):
			var cell := Vector2i(x, y)

			if not distances.has(cell):
				continue

			var current_distance: int = distances[cell]
			var best_neighbor := cell
			var best_distance := current_distance

			for direction in ALL_DIRECTIONS:
				var neighbor := cell + direction

				if not can_flow_step(cell, neighbor):
					continue

				if not distances.has(neighbor):
					continue

				var neighbor_distance: int = distances[neighbor]

				if neighbor_distance >= best_distance:
					continue

				best_distance = neighbor_distance
				best_neighbor = neighbor

			if best_neighbor == cell:
				idol_flow_directions[cell] = Vector2.ZERO
				continue

			var difference := best_neighbor - cell

			idol_flow_directions[cell] = Vector2(
				difference.x,
				difference.y
			).normalized()


func can_flow_step(from_cell: Vector2i, to_cell: Vector2i) -> bool:
	if not is_walkable_cell(to_cell):
		return false

	var difference := to_cell - from_cell

	if absi(difference.x) == 1 and absi(difference.y) == 1:
		var horizontal := from_cell + Vector2i(difference.x, 0)
		var vertical := from_cell + Vector2i(0, difference.y)

		if not is_walkable_cell(horizontal):
			return false

		if not is_walkable_cell(vertical):
			return false

	return true


func get_idol_flow_direction(global_position: Vector2) -> Vector2:
	var cell := global_to_cell(global_position)

	if not grid.is_in_bounds(cell):
		var entry_cell := clamp_cell(cell)
		return global_position.direction_to(
			cell_to_global_center(entry_cell)
		)

	if idol_flow_directions.has(cell):
		var direction: Vector2 = idol_flow_directions[cell]

		if not direction.is_zero_approx():
			return direction

	if idol != null:
		return global_position.direction_to(
			idol.get_combat_position()
		)

	return Vector2.ZERO
