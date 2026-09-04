class_name PassiveDefinition
extends Resource

@export_group("Identity")
@export var passive_id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D

@export_group("Effects")
@export_range(0.0, 10.0, 0.01, "or_greater") var distribution_rate_multiplier := 1.0
@export_range(0, 100, 1, "or_greater") var extra_cat_lives := 0
@export_range(0.01, 10.0, 0.01, "or_greater") var claw_swipe_attack_speed_multiplier := 1.0
