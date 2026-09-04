class_name BuildingDefinition
extends Resource

enum BuildingType {
	CAT_DISTRIBUTOR,
	SUPPORT,
	DEFENSE
}

enum UnitType {
	MELEE,
	RANGED,
	SUPPORT
}

@export_group("Identity")
@export var building_id: StringName
@export var display_name := ""
@export var icon: Texture2D
@export var scene: PackedScene
@export var building_type: BuildingType = BuildingType.CAT_DISTRIBUTOR

@export_group("Placement")
@export var size := Vector2i.ONE
@export var base_cost := 0

@export_group("Distribution")
@export_range(0.0, 10.0, 0.001, "or_greater") var base_distribution_per_second := 0.0
@export var produced_unit_name := ""
@export var produced_unit_type: UnitType = UnitType.MELEE


func get_building_type_name() -> String:
	match building_type:
		BuildingType.CAT_DISTRIBUTOR:
			return "Cat Distributor"
		BuildingType.SUPPORT:
			return "Support"
		BuildingType.DEFENSE:
			return "Defense"

	return "Unknown"


func get_unit_type_name() -> String:
	match produced_unit_type:
		UnitType.MELEE:
			return "Melee"
		UnitType.RANGED:
			return "Ranged"
		UnitType.SUPPORT:
			return "Support"

	return "Unknown"
