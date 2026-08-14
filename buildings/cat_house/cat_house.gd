extends Node2D

const SIZE := Vector2i(2, 2)
const PRODUCTION_TIME := 2.0

const BASIC_CAT_SCENE := preload(
	"res://units/cats/cat_normal/cat_normal.tscn"
)

var cats_parent: Node2D
var cats_produced:= 0

var production_timer := 0.0


func setup(new_cats_parent: Node2D) -> void:
	cats_parent = new_cats_parent


func _process(delta: float) -> void:
	if cats_parent == null:
		return

	production_timer += delta

	if production_timer >= PRODUCTION_TIME:
		production_timer = 0.0
		produce_cat()


func produce_cat() -> void:
	var cat := BASIC_CAT_SCENE.instantiate()
	cats_produced += 1
	print("cats produced: " + str(cats_produced))
	
	cats_parent.add_child(cat)

	cat.global_position = global_position + Vector2(
		SIZE.x * 16 / 2.0,
		SIZE.y * 16 + 8
	)

	cat.setup()
