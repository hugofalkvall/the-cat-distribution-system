class_name Run
extends Node2D

enum Phase {
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

@export var starting_currency := 20
@export var available_buildings: Array[BuildingDefinition] = []

var total_cats_produced := 0
var current_cat_count := 0
var currency := 0
var is_game_over := false

@onready var cats: Node2D = $Arena/Cats
@onready var enemies: Node2D = $Arena/Enemies
@onready var idol: Damageable = $Arena/Idol
@onready var build_placement: BuildPlacement = $Arena/BuildPlacement
@onready var run_ui: RunUI = $RunUI
@onready var wave_director: WaveDirector = $WaveDirector

func _ready() -> void:
	currency = starting_currency

	cats.child_entered_tree.connect(_on_cat_produced)
	enemies.child_entered_tree.connect(_on_enemy_spawned)
	idol.died.connect(_on_idol_died)

	run_ui.start_wave_requested.connect(_on_start_wave_requested)	
	run_ui.building_selected.connect(_on_building_selected)
	
	build_placement.placement_requested.connect(_on_building_placement_requested)

	wave_director.intermission_started.connect(_on_intermission_started)
	wave_director.wave_started.connect(_on_wave_started)
	wave_director.wave_completed.connect(_on_wave_completed)
	wave_director.all_waves_completed.connect(_on_all_waves_completed)
	wave_director.wave_progress_changed.connect(_on_wave_progress_changed)

	for enemy in enemies.get_children():
		_register_enemy(enemy)

	run_ui.setup(self, idol)

	wave_director.start()


func _on_cat_produced(cat: Node) -> void:
	if not cat is CombatUnit:
		return

	total_cats_produced += 1
	current_cat_count += 1

	cat.died.connect(_on_cat_died)

	cat_count_changed.emit(total_cats_produced, current_cat_count)


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

	add_currency(enemy.currency_reward)


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

	wave_director.finish_intermission()

func _on_building_selected(definition: BuildingDefinition) -> void:
	
	if phase != Phase.INTERMISSION:
		print("Cannot build during a wave")
		return
	
	if not available_buildings.has(definition):
		return

	build_placement.select_building(definition)


func _on_building_placement_requested(definition: BuildingDefinition, cell: Vector2i) -> void:
	if is_game_over:
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


func _on_idol_died(_idol: Damageable) -> void:
	if is_game_over:
		return

	is_game_over = true
	phase = Phase.GAME_OVER

	build_placement.set_production_enabled(false)
	run_ui.set_start_wave_button_visible(false)
	build_placement.cancel_placement()

	game_over.emit()

	print("GAME OVER")

func _on_intermission_started(wave_number: int, total_waves: int, duration: float) -> void:
	print("Preparing wave ", wave_number, "/", total_waves)
	
	build_placement.set_production_enabled(false)
	phase = Phase.INTERMISSION
	run_ui.set_start_wave_button_visible(true)

func _on_wave_started(wave_number: int, total_waves: int, definition: WaveDefinition) -> void:
	print("Wave ", wave_number, "/", total_waves, ": ", definition.display_name)

	phase = Phase.COMBAT

	build_placement.set_production_enabled(true)
	build_placement.cancel_placement()
	run_ui.set_start_wave_button_visible(false)

func _on_wave_completed(_wave_number: int, _total_waves: int, definition: WaveDefinition) -> void:
	build_placement.set_production_enabled(false)
	add_currency(definition.completion_reward)
	despawn_all_cats()
	wave_finnished.emit()
	print("Wave completed")

func _on_all_waves_completed() -> void:
	phase = Phase.VICTORY
	build_placement.set_production_enabled(false)
	run_ui.set_start_wave_button_visible(false)
	build_placement.cancel_placement()
	victory.emit()

	print("ALL WAVES COMPLETED")
