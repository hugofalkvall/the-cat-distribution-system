class_name WaveSetDefinition
extends Resource

@export_range(0.0, 120.0, 0.1) var initial_intermission_duration := 15.0
@export_range(0.0, 120.0, 0.1) var default_intermission_duration := 10.0

@export var waves: Array[WaveDefinition] = []
