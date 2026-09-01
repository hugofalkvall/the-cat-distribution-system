class_name ChoiceDirector
extends Node

signal choice_started(event: ChoiceEventDefinition, options: Array[RewardDefinition])
signal choice_completed(event: ChoiceEventDefinition, selected_reward: RewardDefinition)
signal choice_options_changed(event: ChoiceEventDefinition, options: Array[RewardDefinition])

var run_state: Run

var active_event: ChoiceEventDefinition
var active_options: Array[RewardDefinition] = []


func setup(new_run_state: Run) -> void:
	run_state = new_run_state


func start_choice(event: ChoiceEventDefinition) -> void:
	if event == null:
		push_error("ChoiceDirector: event is null.")
		return

	if event.reward_pool == null:
		push_error("ChoiceDirector: event has no reward pool.")
		return

	if active_event != null:
		push_error("ChoiceDirector: a choice is already active.")
		return

	var candidates := event.reward_pool.get_available_rewards(run_state)

	active_options = generate_options(
		candidates,
		event.option_count
	)

	if active_options.is_empty():
		push_warning(
			"ChoiceDirector: no valid rewards for event: "
			+ event.display_name
		)

		choice_completed.emit(event, null)
		return

	active_event = event

	choice_started.emit(
		active_event,
		active_options
	)


func select_reward(reward: RewardDefinition) -> void:
	if active_event == null:
		return

	if reward == null:
		return

	if not active_options.has(reward):
		return

	var completed_event := active_event

	reward.apply(run_state)

	if reward.unique and reward.reward_id != &"":
		run_state.claim_reward(reward.reward_id)

	active_event = null
	active_options.clear()

	choice_completed.emit(
		completed_event,
		reward
	)


func generate_options(candidates: Array[RewardDefinition], option_count: int) -> Array[RewardDefinition]:
	var remaining: Array[RewardDefinition] = []
	var options: Array[RewardDefinition] = []

	for candidate in candidates:
		remaining.append(candidate)

	var count := mini(
		option_count,
		remaining.size()
	)

	for _index in range(count):
		var reward := pick_weighted_reward(remaining)

		if reward == null:
			break

		options.append(reward)
		remaining.erase(reward)

	return options


func pick_weighted_reward(rewards: Array[RewardDefinition]) -> RewardDefinition:
	if rewards.is_empty():
		return null

	var total_weight := 0.0

	for reward in rewards:
		total_weight += maxf(reward.weight, 0.0)

	if total_weight <= 0.0:
		return rewards.pick_random()

	var roll := randf() * total_weight

	for reward in rewards:
		roll -= maxf(reward.weight, 0.0)

		if roll <= 0.0:
			return reward

	return rewards.back()

func reroll_choice() -> void:
	if active_event == null:
		return

	if not active_event.allow_reroll:
		return

	var candidates: Array[RewardDefinition] = active_event.reward_pool.get_available_rewards(run_state)

	if candidates.size() <= active_options.size():
		return

	var new_options: Array[RewardDefinition] = []

	for _attempt in range(10):
		new_options = generate_options(candidates, active_event.option_count)

		if not contains_same_rewards(active_options, new_options):
			break

	if contains_same_rewards(active_options, new_options):
		return

	active_options = new_options

	choice_options_changed.emit(active_event, active_options)


func skip_choice() -> void:
	if active_event == null:
		return

	if not active_event.allow_skip:
		return

	var completed_event: ChoiceEventDefinition = active_event

	active_event = null
	active_options.clear()

	choice_completed.emit(completed_event, null)


func contains_same_rewards(first: Array[RewardDefinition], second: Array[RewardDefinition]) -> bool:
	if first.size() != second.size():
		return false

	for reward: RewardDefinition in first:
		if not second.has(reward):
			return false

	return true
