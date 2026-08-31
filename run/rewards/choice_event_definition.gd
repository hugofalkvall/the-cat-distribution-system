class_name ChoiceEventDefinition
extends Resource

@export var display_name := ""
@export_range(1, 10, 1) var option_count := 3
@export var reward_pool: RewardPoolDefinition
