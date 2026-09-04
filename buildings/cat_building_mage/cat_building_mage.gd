extends Building

const PRODUCTION_TIME := 8.0
const CAT_MAGE_SCENE := preload("res://units/cats/cat_mage/cat_mage.tscn")

var production_progress := 0.0


func _process(delta: float) -> void:
	if context == null:
		return

	if context.cats_parent == null:
		return

	if definition == null:
		return

	if not context.production_enabled:
		production_progress = 0.0
		return

	production_progress += delta * get_current_distribution_per_second()

	if production_progress >= 1.0:
		production_progress -= 1.0
		produce_cat()


func produce_cat() -> void:
	var cat := CAT_MAGE_SCENE.instantiate()

	context.cats_parent.add_child(cat)

	var building_size := definition.size
	var spawn_offset := Vector2(
		building_size.x * context.grid.CELL_SIZE / 2.0,
		building_size.y * context.grid.CELL_SIZE + 8
	)

	cat.global_position = global_position + spawn_offset
	cat.setup(context.spatial_index, context.combat_system, context.grid)
