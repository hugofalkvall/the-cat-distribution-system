class_name Building
extends Node2D

const SELECTED_INDICATOR_TEXTURE := preload("res://buildings/Selected_indicator.png")

var definition: BuildingDefinition
var context: BuildingContext

var selected_indicator: Sprite2D


func setup(new_definition: BuildingDefinition, new_context: BuildingContext) -> void:
	definition = new_definition
	context = new_context

	setup_selected_indicator()


func setup_selected_indicator() -> void:
	if selected_indicator != null:
		return

	selected_indicator = Sprite2D.new()
	selected_indicator.name = "SelectedIndicator"
	selected_indicator.texture = SELECTED_INDICATOR_TEXTURE
	selected_indicator.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	selected_indicator.centered = true
	selected_indicator.z_index = 10
	selected_indicator.visible = false

	add_child(selected_indicator)

	var footprint_size := Vector2(
		definition.size.x * context.grid.CELL_SIZE,
		definition.size.y * context.grid.CELL_SIZE
	)

	selected_indicator.position = footprint_size / 2.0

	var texture_size := SELECTED_INDICATOR_TEXTURE.get_size()

	if texture_size.x > 0.0 and texture_size.y > 0.0:
		selected_indicator.scale = footprint_size / texture_size


func set_selected(selected: bool) -> void:
	selected_indicator.visible = selected
