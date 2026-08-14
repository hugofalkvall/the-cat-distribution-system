extends Node2D

var total_cats_produced := 0

@onready var cats: Node2D = $Arena/Cats


func _ready() -> void:
	cats.child_entered_tree.connect(_on_cat_produced)


func _on_cat_produced(cat: Node) -> void:
	total_cats_produced += 1

	print("Total cats produced: ", total_cats_produced)
