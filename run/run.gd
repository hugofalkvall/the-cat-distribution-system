class_name Run
extends Node2D

signal game_over
signal cat_count_changed(total_cats: int)
signal currency_changed(total_currency: int)

var total_cats_produced := 0
var currency := 0
var is_game_over := false

@onready var cats: Node2D = $Arena/Cats
@onready var enemies: Node2D = $Arena/Enemies
@onready var idol: Damageable = $Arena/Idol
@onready var run_ui: RunUI = $RunUI


func _ready() -> void:
	cats.child_entered_tree.connect(_on_cat_produced)
	enemies.child_entered_tree.connect(_on_enemy_spawned)
	idol.died.connect(_on_idol_died)

	for enemy in enemies.get_children():
		_register_enemy(enemy)

	run_ui.setup(self, idol)


func _on_cat_produced(_cat: Node) -> void:
	total_cats_produced += 1
	cat_count_changed.emit(total_cats_produced)

func _on_cat_erased(cat: Node) -> void:
	cat_count_changed.emit(total_cats_produced, 1)

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
	if amount <= 0:
		return false

	if currency < amount:
		return false

	currency -= amount
	currency_changed.emit(currency)

	return true


func _on_idol_died(_idol: Damageable) -> void:
	if is_game_over:
		return

	is_game_over = true
	game_over.emit()

	print("GAME OVER")
