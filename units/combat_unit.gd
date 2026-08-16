class_name CombatUnit
extends Damageable

@export var starting_attacks: Array[AttackDefinition] = []

@export_group("Health Bar")
@export var health_bar_width := 14.0
@export var health_bar_height := 2.0
@export var health_bar_offset_y := -10.0
@export var health_bar_always_visible := true

var attacks: Array[AttackState] = []


func _ready() -> void:
	super._ready()

	for attack_definition in starting_attacks:
		add_attack(attack_definition)

	queue_redraw()


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
