class_name CombatUnit
extends Damageable

@export var starting_attacks: Array[AttackDefinition] = []

@export_group("Health Bar")
@export var health_bar_width := 14.0
@export var health_bar_height := 2.0
@export var health_bar_offset_y := -10.0
@export var health_bar_always_visible := true

var attacks: Array[AttackState] = []

enum NavigationMode {
	UNKNOWN,
	DIRECT,
	PATH
}

const NAVIGATION_REPATH_INTERVAL := 0.2
const NAVIGATION_WAYPOINT_DISTANCE := 4.0
const INVALID_NAVIGATION_CELL := Vector2i(-1000000, -1000000)

var navigation_mode := NavigationMode.UNKNOWN
var navigation_path := PackedVector2Array()
var navigation_path_index := 0
var navigation_goal_cell := INVALID_NAVIGATION_CELL
var navigation_repath_remaining := 0.0

const MOVEMENT_DIRECTION_THRESHOLD := 0.1

var velocity := Vector2.ZERO

func _ready() -> void:
	super._ready()

	for attack_definition in starting_attacks:
		add_attack(attack_definition)

	queue_redraw()

func get_movement_direction() -> Vector2:
	if velocity.length_squared() <= MOVEMENT_DIRECTION_THRESHOLD * MOVEMENT_DIRECTION_THRESHOLD:
		return Vector2.ZERO

	return velocity.normalized()


func is_moving_left() -> bool:
	return velocity.x < -MOVEMENT_DIRECTION_THRESHOLD


func is_moving_right() -> bool:
	return velocity.x > MOVEMENT_DIRECTION_THRESHOLD

func add_attack(attack_definition: AttackDefinition) -> AttackState:
	if attack_definition == null:
		return null

	var attack_state := AttackState.new(attack_definition)
	attacks.append(attack_state)

	return attack_state


func remove_attack(attack_state: AttackState) -> void:
	attacks.erase(attack_state)


func get_attack_by_name(attack_name: StringName) -> AttackState:
	for attack_state in attacks:
		if attack_state.definition.attack_name == attack_name:
			return attack_state

	return null


func has_attacks() -> bool:
	return not attacks.is_empty()


func get_ready_attack_in_range(target: Damageable) -> AttackState:
	if not is_instance_valid(target):
		return null

	var distance_squared := global_position.distance_squared_to(target.get_combat_position())

	for attack_state in attacks:
		if not attack_state.is_ready():
			continue

		var attack_range := attack_state.get_range() + target.combat_radius

		if distance_squared <= attack_range * attack_range:
			return attack_state

	return null


func get_approach_range(target: Damageable) -> float:
	var largest_ready_range := 0.0
	var largest_range := 0.0

	for attack_state in attacks:
		var attack_range := attack_state.get_range() + target.combat_radius
		largest_range = maxf(largest_range, attack_range)

		if attack_state.is_ready():
			largest_ready_range = maxf(largest_ready_range, attack_range)

	if largest_ready_range > 0.0:
		return largest_ready_range

	return largest_range


func try_attack(target: Damageable, combat_system: CombatSystem) -> bool:
	if is_dead:
		return false

	if combat_system == null:
		return false

	if not is_instance_valid(target):
		return false

	if target.is_dead:
		return false

	var attack_state := get_ready_attack_in_range(target)

	if attack_state == null:
		return false

	if not combat_system.perform_attack(self, target, attack_state):
		return false

	attack_state.start_cooldown()

	return true

func get_navigation_direction(arena_grid: ArenaGrid, destination: Vector2, stop_distance: float, unit_radius: float, delta: float, use_idol_flow: bool = false) -> Vector2:
	if global_position.distance_to(destination) <= stop_distance:
		reset_navigation_route()
		return Vector2.ZERO

	if arena_grid == null or arena_grid.pathfinder == null:
		return global_position.direction_to(destination)

	var pathfinder := arena_grid.pathfinder

	if use_idol_flow:
		reset_navigation_route()

		return pathfinder.get_idol_flow_direction(
			global_position
		)

	navigation_repath_remaining = maxf(
		navigation_repath_remaining - delta,
		0.0
	)

	var goal_cell := pathfinder.get_goal_cell(
		global_position,
		destination,
		stop_distance
	)

	var route_finished := (
		navigation_mode == NavigationMode.PATH
		and navigation_path_index >= navigation_path.size()
	)

	var goal_changed := goal_cell != navigation_goal_cell

	var should_recalculate := (
		navigation_mode == NavigationMode.UNKNOWN
		or route_finished
		or (
			goal_changed
			and navigation_repath_remaining <= 0.0
		)
	)

	if should_recalculate:
		update_navigation_route(
			pathfinder,
			destination,
			stop_distance,
			unit_radius,
			goal_cell
		)

	if navigation_mode == NavigationMode.PATH:
		while (
			navigation_path_index < navigation_path.size()
			and global_position.distance_to(
				navigation_path[navigation_path_index]
			) <= NAVIGATION_WAYPOINT_DISTANCE
		):
			navigation_path_index += 1

		if navigation_path_index < navigation_path.size():
			return global_position.direction_to(
				navigation_path[navigation_path_index]
			)

		navigation_mode = NavigationMode.UNKNOWN

	return global_position.direction_to(destination)


func update_navigation_route(pathfinder: ArenaPathfinder, destination: Vector2, stop_distance: float, unit_radius: float, goal_cell: Vector2i) -> void:
	navigation_goal_cell = goal_cell

	navigation_repath_remaining = (
		NAVIGATION_REPATH_INTERVAL
		+ randf_range(0.0, 0.05)
	)

	if pathfinder.has_clear_path(
		global_position,
		destination,
		unit_radius,
		stop_distance
	):
		navigation_mode = NavigationMode.DIRECT
		navigation_path.clear()
		navigation_path_index = 0
		return

	navigation_path = pathfinder.find_path(
		global_position,
		destination,
		stop_distance,
		unit_radius
	)

	navigation_path_index = 0

	if navigation_path.is_empty():
		navigation_mode = NavigationMode.DIRECT
	else:
		navigation_mode = NavigationMode.PATH


func reset_navigation_route() -> void:
	navigation_mode = NavigationMode.UNKNOWN
	navigation_path.clear()
	navigation_path_index = 0
	navigation_goal_cell = INVALID_NAVIGATION_CELL
	navigation_repath_remaining = 0.0


func on_death() -> void:
	queue_free()


func _draw() -> void:
	if max_health <= 0.0:
		return

	if not health_bar_always_visible and current_health >= max_health:
		return

	var health_percentage := current_health / max_health
	var bar_position := Vector2(-health_bar_width / 2.0, health_bar_offset_y)

	draw_rect(Rect2(bar_position, Vector2(health_bar_width, health_bar_height)), Color(0.1, 0.1, 0.1, 0.9))

	var health_width := health_bar_width * health_percentage
	draw_rect(Rect2(bar_position, Vector2(health_width, health_bar_height)), Color(0.2, 0.9, 0.2, 1.0))
