class_name PassiveRewardDefinition
extends RewardDefinition

@export var passive: PassiveDefinition


func can_offer(run_state: Run) -> bool:
	if not super.can_offer(run_state):
		return false

	if passive == null:
		return false

	return not run_state.has_passive(passive)


func apply(run_state: Run) -> void:
	if run_state == null:
		return

	if passive == null:
		return

	run_state.add_passive(passive)
