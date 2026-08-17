class_name Building
extends Node2D

var definition: BuildingDefinition
var context: BuildingContext


func setup(new_definition: BuildingDefinition, new_context: BuildingContext) -> void:
	definition = new_definition
	context = new_context
