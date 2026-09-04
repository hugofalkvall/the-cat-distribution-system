class_name BuildingRewardDefinition
extends RewardDefinition

@export var building: BuildingDefinition


func can_offer(run_state: Run) -> bool:
	if not super.can_offer(run_state):
		return false

	if building == null:
		return false

	return not run_state.has_building_unlocked(building)


func apply(_run_state: Run) -> void:
	# Run places this building before ChoiceDirector completes the reward.
	# Completing it must not unlock repeat purchases in the building shop.
	pass
