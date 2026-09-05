class_name Run
extends Node2D

const CLAW_SWIPE_BEHAVIOR := preload("res://combat/attacks/claw_swipe/claw_swipe.tscn")

enum Phase {
	CHOICE,
	INTERMISSION,
	COMBAT,
	GAME_OVER,
	VICTORY
}

var phase := Phase.INTERMISSION

signal game_over
signal victory
signal wave_finnished
signal cat_count_changed(total_cats: int, current_cats: int)
signal currency_changed(total_currency: int)
signal wave_progress_changed(defeated_enemies: int, total_enemies: int)
signal placed_building_selection_changed(building: Building)
signal available_buildings_changed
signal passives_changed

@export var starting_currency := 20

var available_buildings: Array[BuildingDefinition] = []
var active_passives: Array[PassiveDefinition] = []
var claimed_reward_ids: Dictionary = {}

var passive_distribution_rate_multiplier := 1.0
var passive_extra_cat_lives := 0
var passive_claw_swipe_attack_speed_multiplier := 1.0
var passive_cat_max_health_multiplier := 1.0
var passive_cat_damage_multiplier := 1.0
var passive_cat_attack_range_multiplier := 1.0
var passive_cat_movement_speed_multiplier := 1.0
var passive_enemy_currency_reward_multiplier := 1.0

var enemy_currency_reward_remainder := 0.0

var total_cats_produced := 0
var current_cat_count := 0
var currency := 0
var is_game_over := false

var selected_placed_building: Building
var pending_building_reward: BuildingRewardDefinition

@onready var cats: Node2D = $Arena/Cats
@onready var enemies: Node2D = $Arena/Enemies
@onready var idol: Damageable = $Arena/Idol
@onready var build_placement: BuildPlacement = $Arena/BuildPlacement
@onready var run_ui: RunUI = $RunUI
@onready var wave_director: WaveDirector = $WaveDirector
@onready var arena_pathfinder: ArenaPathfinder = $Arena/Pathfinder
@onready var choice_director: ChoiceDirector = $ChoiceDirector
@onready var run_flow_director: RunFlowDirector = $RunFlowDirector

func _ready() -> void:
	currency = starting_currency

	cats.child_entered_tree.connect(_on_cat_produced)
	enemies.child_entered_tree.connect(_on_enemy_spawned)
	idol.died.connect(_on_idol_died)

	run_ui.start_wave_requested.connect(_on_start_wave_requested)	
	run_ui.building_selected.connect(_on_building_selected)
	
	build_placement.placement_requested.connect(_on_building_placement_requested)
	build_placement.placement_cancelled.connect(_on_building_reward_placement_cancelled)
	build_placement.placed_building_selection_requested.connect(_on_placed_building_selection_requested)

	wave_director.intermission_started.connect(_on_intermission_started)
	wave_director.wave_started.connect(_on_wave_started)
	wave_director.wave_completed.connect(_on_wave_completed)
	wave_director.all_waves_completed.connect(_on_all_waves_completed)
	wave_director.wave_progress_changed.connect(_on_wave_progress_changed)

	for enemy in enemies.get_children():
		_register_enemy(enemy)

	run_ui.setup(self, idol)
	
	choice_director.setup(self)
	run_flow_director.setup(self)

	choice_director.choice_started.connect(_on_choice_started)
	choice_director.choice_completed.connect(_on_choice_completed)
	choice_director.choice_options_changed.connect(_on_choice_options_changed)


	run_ui.reward_selected.connect(_on_reward_selected)
	run_ui.reward_reroll_requested.connect(choice_director.reroll_choice)
	run_ui.reward_skip_requested.connect(choice_director.skip_choice)

	run_flow_director.start_run()


func _on_cat_produced(node: Node) -> void:
	var cat := node as CombatUnit

	if cat == null:
		return

	total_cats_produced += 1
	current_cat_count += 1

	cat.died.connect(_on_cat_died)

	if cat.is_node_ready():
		apply_passives_to_cat(cat)
	else:
		cat.ready.connect(_on_cat_ready.bind(cat), CONNECT_ONE_SHOT)

	cat_count_changed.emit(total_cats_produced, current_cat_count)


func _on_cat_ready(cat: CombatUnit) -> void:
	if not is_instance_valid(cat):
		return

	apply_passives_to_cat(cat)


func _on_cat_died(_cat: Damageable) -> void:
	current_cat_count = maxi(current_cat_count - 1, 0)
	cat_count_changed.emit(total_cats_produced, current_cat_count)

func _on_enemy_spawned(enemy: Node) -> void:
	_register_enemy(enemy)

func _on_wave_progress_changed(defeated_enemies: int, total_enemies: int) -> void:
	wave_progress_changed.emit(defeated_enemies, total_enemies)

func _register_enemy(enemy: Node) -> void:
	if not enemy is EnemyUnit:
		return

	enemy.died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Damageable) -> void:
	if not enemy is EnemyUnit:
		return

	grant_enemy_currency(enemy.currency_reward)


func grant_enemy_currency(base_reward: int) -> void:
	if base_reward <= 0:
		return

	var exact_reward := (
		float(base_reward) * passive_enemy_currency_reward_multiplier
		+ enemy_currency_reward_remainder
	)

	var whole_reward := floori(exact_reward)
	enemy_currency_reward_remainder = exact_reward - float(whole_reward)

	add_currency(whole_reward)


func add_currency(amount: int) -> void:
	if amount <= 0:
		return

	currency += amount
	currency_changed.emit(currency)


func spend_currency(amount: int) -> bool:
	if amount < 0:
		return false

	if currency < amount:
		return false

	if amount == 0:
		return true

	currency -= amount
	currency_changed.emit(currency)

	return true


func get_building_cost(definition: BuildingDefinition) -> int:
	if definition == null:
		return 0

	var cost := definition.base_cost

	# Future modifiers can be applied here.
	# Example:
	# cost = roundi(cost * building_cost_multiplier)

	return maxi(cost, 0)

func despawn_all_cats() -> void:
	for cat in cats.get_children():
		cat.queue_free()

	current_cat_count = 0
	cat_count_changed.emit(total_cats_produced, current_cat_count)

func _on_start_wave_requested() -> void:
	if phase != Phase.INTERMISSION:
		return

	if is_game_over:
		return

	run_flow_director.request_start_wave()
	
func _on_choice_started(event: ChoiceEventDefinition, options: Array[RewardDefinition]) -> void:
	phase = Phase.CHOICE

	build_placement.set_production_enabled(false)
	pending_building_reward = null
	build_placement.cancel_placement()
	clear_placed_building_selection()

	run_ui.set_start_wave_button_visible(false)
	run_ui.show_reward_choice(event, options)
	
func _on_choice_options_changed(event: ChoiceEventDefinition, options: Array[RewardDefinition]) -> void:
	run_ui.show_reward_choice(event, options)


func _on_reward_selected(reward: RewardDefinition) -> void:
	if phase != Phase.CHOICE:
		return

	var building_reward := reward as BuildingRewardDefinition

	if building_reward == null:
		choice_director.select_reward(reward)
		return

	if building_reward.building == null:
		return

	pending_building_reward = building_reward
	clear_placed_building_selection()
	run_ui.show_building_reward_placement(building_reward.building)
	build_placement.select_building(building_reward.building)


func _on_building_reward_placement_cancelled(definition: BuildingDefinition) -> void:
	if phase != Phase.CHOICE:
		return

	if pending_building_reward == null:
		return

	if pending_building_reward.building != definition:
		return

	pending_building_reward = null

	if choice_director.active_event == null:
		return

	run_ui.show_reward_choice(choice_director.active_event, choice_director.active_options)


func unlock_building(definition: BuildingDefinition) -> void:
	if definition == null:
		return

	if has_building_unlocked(definition):
		return

	available_buildings.append(definition)
	available_buildings_changed.emit()


func has_building_unlocked(definition: BuildingDefinition) -> bool:
	if definition == null:
		return false

	for building in available_buildings:
		if building.building_id == definition.building_id:
			return true

	return false


func add_passive(definition: PassiveDefinition) -> void:
	if definition == null:
		return

	active_passives.append(definition)
	recalculate_passive_modifiers()
	passives_changed.emit()


func has_passive(definition: PassiveDefinition) -> bool:
	if definition == null:
		return false

	for passive in active_passives:
		if passive.passive_id == definition.passive_id:
			return true

	return false


func recalculate_passive_modifiers() -> void:
	passive_distribution_rate_multiplier = 1.0
	passive_extra_cat_lives = 0
	passive_claw_swipe_attack_speed_multiplier = 1.0
	passive_cat_max_health_multiplier = 1.0
	passive_cat_damage_multiplier = 1.0
	passive_cat_attack_range_multiplier = 1.0
	passive_cat_movement_speed_multiplier = 1.0
	passive_enemy_currency_reward_multiplier = 1.0

	for passive in active_passives:
		if passive == null:
			continue

		passive_cat_max_health_multiplier *= maxf(passive.cat_max_health_multiplier, 0.0)
		passive_distribution_rate_multiplier *= maxf(passive.distribution_rate_multiplier, 0.0)
		passive_extra_cat_lives += maxi(passive.extra_cat_lives, 0)
		passive_claw_swipe_attack_speed_multiplier *= maxf(passive.claw_swipe_attack_speed_multiplier, 0.01)
		passive_cat_damage_multiplier *= maxf(passive.cat_damage_multiplier, 0.0)
		passive_cat_attack_range_multiplier *= maxf(passive.cat_attack_range_multiplier, 0.01)
		passive_cat_movement_speed_multiplier *= maxf(passive.cat_movement_speed_multiplier, 0.01)
		passive_enemy_currency_reward_multiplier *= maxf(passive.enemy_currency_reward_multiplier, 0.0)

	build_placement.set_distribution_rate_multiplier(passive_distribution_rate_multiplier)

	for child in cats.get_children():
		var cat := child as CombatUnit

		if cat != null and cat.is_node_ready():
			apply_passives_to_cat(cat)

func apply_passives_to_cat(cat: CombatUnit) -> void:
	if not is_instance_valid(cat):
		return

	cat.set_max_health_multiplier(passive_cat_max_health_multiplier)
	cat.set_extra_lives(passive_extra_cat_lives)
	cat.passive_movement_speed_multiplier = passive_cat_movement_speed_multiplier

	var claw_cooldown_multiplier := 1.0 / maxf(passive_claw_swipe_attack_speed_multiplier, 0.01)

	for attack_state in cat.attacks:
		if attack_state == null or attack_state.definition == null:
			continue

		attack_state.passive_damage_multiplier = passive_cat_damage_multiplier
		attack_state.passive_range_multiplier = passive_cat_attack_range_multiplier

		if attack_state.definition.behavior_scene == CLAW_SWIPE_BEHAVIOR:
			attack_state.passive_cooldown_multiplier = claw_cooldown_multiplier

func claim_reward(reward_id: StringName) -> void:
	if reward_id == &"":
		return

	claimed_reward_ids[reward_id] = true


func has_claimed_reward(reward_id: StringName) -> bool:
	if reward_id == &"":
		return false

	return claimed_reward_ids.has(reward_id)


func _on_choice_completed(_event: ChoiceEventDefinition, _selected_reward: RewardDefinition) -> void:
	pending_building_reward = null
	run_ui.hide_reward_choice()


func _on_placed_building_selection_requested(building: Building) -> void:
	if building == selected_placed_building:
		return

	if is_instance_valid(selected_placed_building):
		selected_placed_building.set_selected(false)

	selected_placed_building = building

	if is_instance_valid(selected_placed_building):
		selected_placed_building.set_selected(true)

	placed_building_selection_changed.emit(selected_placed_building)

func clear_placed_building_selection() -> void:
	if is_instance_valid(selected_placed_building):
		selected_placed_building.set_selected(false)

	selected_placed_building = null
	placed_building_selection_changed.emit(null)

func _on_building_selected(definition: BuildingDefinition) -> void:
	
	if phase != Phase.INTERMISSION:
		print("Cannot build during a wave")
		return
	
	if not available_buildings.has(definition):
		return

	clear_placed_building_selection()
	build_placement.select_building(definition)


func _on_building_placement_requested(definition: BuildingDefinition, cell: Vector2i) -> void:
	if is_game_over:
		return

	if phase == Phase.CHOICE:
		_place_pending_building_reward(definition, cell)
		return

	if phase != Phase.INTERMISSION:
		return

	if not available_buildings.has(definition):
		return

	var cost := get_building_cost(definition)

	if currency < cost:
		return

	if not build_placement.place_building(definition, cell):
		return

	spend_currency(cost)


func _place_pending_building_reward(definition: BuildingDefinition, cell: Vector2i) -> void:
	var reward := pending_building_reward

	if reward == null:
		return

	if reward.building != definition:
		return

	if not build_placement.place_building(definition, cell):
		return

	pending_building_reward = null
	choice_director.select_reward(reward)


func _on_idol_died(_idol: Damageable) -> void:
	if is_game_over:
		return

	is_game_over = true
	phase = Phase.GAME_OVER

	build_placement.set_production_enabled(false)
	clear_placed_building_selection()
	run_ui.set_start_wave_button_visible(false)
	build_placement.cancel_placement()

	game_over.emit()

	print("GAME OVER")

func _on_intermission_started(wave_number: int, total_waves: int, duration: float) -> void:
	print("Preparing wave ", wave_number, "/", total_waves)
	
	build_placement.set_production_enabled(false)
	clear_placed_building_selection()
	phase = Phase.INTERMISSION
	run_ui.set_start_wave_button_visible(true)
	run_ui.update_next_wave(wave_number, total_waves)

func _on_wave_started(wave_number: int, total_waves: int, definition: WaveDefinition) -> void:
	arena_pathfinder.rebuild_if_dirty()

	print("Wave ",wave_number,"/",total_waves,": ",definition.display_name)

	phase = Phase.COMBAT

	build_placement.set_production_enabled(true)
	build_placement.cancel_placement()
	run_ui.set_start_wave_button_visible(false)

func _on_wave_completed(_wave_number: int, _total_waves: int, definition: WaveDefinition) -> void:
	build_placement.set_production_enabled(false)
	add_currency(definition.completion_reward)
	clear_placed_building_selection()
	despawn_all_cats()
	wave_finnished.emit()
	print("Wave completed")

func _on_all_waves_completed() -> void:
	phase = Phase.VICTORY
	clear_placed_building_selection()
	build_placement.set_production_enabled(false)
	run_ui.set_start_wave_button_visible(false)
	build_placement.cancel_placement()
	victory.emit()

	print("ALL WAVES COMPLETED")
