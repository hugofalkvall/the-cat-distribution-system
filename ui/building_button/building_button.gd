class_name BuildingButton
extends Button

signal selected(definition: BuildingDefinition)

var definition: BuildingDefinition


func _ready() -> void:
	pressed.connect(_on_pressed)


func setup(new_definition: BuildingDefinition, cost: int) -> void:
	definition = new_definition

	icon = definition.icon
	text = str(cost)
	tooltip_text = definition.display_name


func update_cost(cost: int) -> void:
	text = str(cost)


func set_affordable(affordable: bool) -> void:
	disabled = not affordable


func _on_pressed() -> void:
	if definition == null:
		return

	selected.emit(definition)
