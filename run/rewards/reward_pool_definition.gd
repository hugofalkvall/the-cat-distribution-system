class_name RewardPoolDefinition
extends Resource

@export var rewards: Array[RewardDefinition] = []


func get_available_rewards(run_state: Run) -> Array[RewardDefinition]:
	var available: Array[RewardDefinition] = []

	for reward in rewards:
		if reward == null:
			continue

		if reward.can_offer(run_state):
			available.append(reward)

	return available
