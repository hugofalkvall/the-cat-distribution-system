class_name RunFlowDirector
extends Node

enum State {
	IDLE,
	CHOICE,
	INTERMISSION,
	COMBAT,
	COMPLETE
}

enum Continuation {
	NONE,
	BEGIN_INTERMISSION
}

@export var wave_director: WaveDirector
@export var choice_director: ChoiceDirector
@export var event_schedule: RunEventScheduleDefinition

var state := State.IDLE
var pending_events: Array[ChoiceEventDefinition] = []
var continuation := Continuation.NONE
var is_setup := false


func setup(_run_state: Run) -> void:
	is_setup = false

	if wave_director == null:
		push_error("RunFlowDirector: wave_director is not assigned.")
		return

	if choice_director == null:
		push_error("RunFlowDirector: choice_director is not assigned.")
		return

	if not wave_director.wave_completed.is_connected(_on_wave_completed):
		wave_director.wave_completed.connect(_on_wave_completed)

	if not choice_director.choice_completed.is_connected(_on_choice_completed):
		choice_director.choice_completed.connect(_on_choice_completed)

	is_setup = true


func start_run() -> void:
	if not is_setup:
		push_error("RunFlowDirector: cannot start before setup succeeds.")
		return

	if state != State.IDLE:
		return

	queue_events(
		RunEventEntryDefinition.Trigger.BEFORE_INTERMISSION,
		1
	)

	continuation = Continuation.BEGIN_INTERMISSION

	start_next_event_or_continue()


func request_start_wave() -> void:
	if state != State.INTERMISSION:
		return

	state = State.COMBAT

	wave_director.finish_intermission()


func _on_wave_completed(wave_number: int, total_waves: int, _definition: WaveDefinition) -> void:
	_handle_wave_completed_transition.call_deferred(wave_number, total_waves)


func _handle_wave_completed_transition(wave_number: int, total_waves: int) -> void:
	if wave_number >= total_waves:
		state = State.COMPLETE
		return

	pending_events.clear()

	queue_events(RunEventEntryDefinition.Trigger.AFTER_WAVE, wave_number)
	queue_events(RunEventEntryDefinition.Trigger.BEFORE_INTERMISSION, wave_number + 1)

	continuation = Continuation.BEGIN_INTERMISSION

	start_next_event_or_continue()


func queue_events(trigger_type: int, wave_number: int) -> void:
	if event_schedule == null:
		return

	var events: Array[ChoiceEventDefinition] = event_schedule.get_events(trigger_type, wave_number)

	for event: ChoiceEventDefinition in events:
		pending_events.append(event)


func start_next_event_or_continue() -> void:
	if not pending_events.is_empty():
		state = State.CHOICE

		var event: ChoiceEventDefinition = pending_events.pop_front()
		choice_director.start_choice(event)

		return

	continue_flow()


func _on_choice_completed(_event: ChoiceEventDefinition, _selected_reward: RewardDefinition) -> void:
	start_next_event_or_continue.call_deferred()


func continue_flow() -> void:
	match continuation:
		Continuation.BEGIN_INTERMISSION:
			continuation = Continuation.NONE
			state = State.INTERMISSION
			wave_director.begin_intermission()

		_:
			continuation = Continuation.NONE
