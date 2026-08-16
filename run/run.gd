class_name Run
extends Node2D

signal game_over
signal cat_count_changed(total_cats: int)

var total_cats_produced := 0
var is_game_over := false

@onready var cats: Node2D = $Arena/Cats
@onready var idol: Damageable = $Arena/Idol
@onready var run_ui: RunUI = $RunUI


func _ready() -> void:
	cats.child_entered_tree.connect(_on_cat_produced)
	idol.died.connect(_on_idol_died)

	run_ui.setup(self, idol)
	
func _on_idol_damaged(_damageable: Damageable, current_health: float, _max_health: float) -> void:
	pass

func _on_cat_produced(cat: Node) -> void:
	total_cats_produced += 1
	cat_count_changed.emit(total_cats_produced)


func _on_idol_died(_idol: Damageable) -> void:
	if is_game_over:
		return

	is_game_over = true
	game_over.emit()

	print("GAME OVER")
