class_name RunEventEntryDefinition
extends Resource

enum Trigger {
	BEFORE_INTERMISSION,
	AFTER_WAVE
}

@export_enum("Before Intermission", "After Wave") var trigger: int = Trigger.AFTER_WAVE
@export_range(1, 100, 1) var wave_number := 1
@export var choice_event: ChoiceEventDefinition
