class_name RunEventScheduleDefinition
extends Resource

@export var entries: Array[RunEventEntryDefinition] = []


func get_events(
	trigger_type: int,
	wave_number: int
) -> Array[ChoiceEventDefinition]:
	var result: Array[ChoiceEventDefinition] = []

	for entry in entries:
		if entry == null:
			continue

		if entry.trigger != trigger_type:
			continue

		if entry.wave_number != wave_number:
			continue

		if entry.choice_event == null:
			continue

		result.append(entry.choice_event)

	return result
