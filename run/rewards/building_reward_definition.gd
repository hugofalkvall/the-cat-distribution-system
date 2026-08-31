class_name BuildingRewardDefinition
extends RewardDefinition

@export var building: BuildingDefinition


func can_offer(run_state: Run) -> bool:
	if not super.can_offer(run_state):
		return false

	if building == null:
		return false

	return not run_state.has_building_unlocked(building)


func apply(run_state: Run) -> void:
	if run_state == null:
		return

	if building == null:
		return

	run_state.unlock_building(building)
