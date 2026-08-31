class_name RewardDefinition
extends Resource

@export var reward_id: StringName
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D

@export_range(0.0, 1000.0, 0.1) var weight := 1.0
@export var unique := false


func can_offer(run_state: Run) -> bool:
	if run_state == null:
		return false

	if unique and reward_id != &"":
		if run_state.has_claimed_reward(reward_id):
			return false

	return true


func apply(_run_state: Run) -> void:
	pass
