class_name Run
extends Node2D

signal game_over

var total_cats_produced := 0
var is_game_over := false

@onready var cats: Node2D = $Arena/Cats
@onready var idol: Damageable = $Arena/Idol


func _ready() -> void:
	cats.child_entered_tree.connect(_on_cat_produced)
	idol.died.connect(_on_idol_died)
	idol.health_changed.connect(_on_idol_damaged)
	
func _on_idol_damaged(_damageable: Damageable, current_health: float, _max_health: float) -> void:
	print("Current Idol HP: " + str(current_health))


func _on_cat_produced(cat: Node) -> void:
	total_cats_produced += 1
	print("Total cats produced: ", total_cats_produced)


func _on_idol_died(_idol: Damageable) -> void:
	if is_game_over:
		return

	is_game_over = true
	game_over.emit()

	print("GAME OVER")
