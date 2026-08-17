class_name Run
extends Node2D

signal game_over
signal cat_count_changed(total_cats: int, current_cats: int)
signal currency_changed(total_currency: int)

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


func _ready() -> void:
	currency = starting_currency

	cats.child_entered_tree.connect(_on_cat_produced)
	enemies.child_entered_tree.connect(_on_enemy_spawned)
	idol.died.connect(_on_idol_died)

	run_ui.building_selected.connect(_on_building_selected)
	build_placement.placement_requested.connect(_on_building_placement_requested)

	for enemy in enemies.get_children():
		_register_enemy(enemy)

	run_ui.setup(self, idol)


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


func _on_building_selected(definition: BuildingDefinition) -> void:
	if not available_buildings.has(definition):
		return

	build_placement.select_building(definition)


func _on_building_placement_requested(definition: BuildingDefinition, cell: Vector2i) -> void:
	if is_game_over:
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

	build_placement.cancel_placement()

	game_over.emit()

	print("GAME OVER")
