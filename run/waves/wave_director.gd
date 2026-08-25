class_name WaveDirector
extends Node

signal intermission_started(wave_number: int, total_waves: int, duration: float)
signal wave_started(wave_number: int, total_waves: int, definition: WaveDefinition)
signal wave_completed(wave_number: int, total_waves: int, definition: WaveDefinition)
signal all_waves_completed

enum State {
	IDLE,
	INTERMISSION,
	COMBAT,
	COMPLETE
}

@export var wave_set: WaveSetDefinition
@export var enemy_spawner: EnemySpawner
@export var enemies: Node2D

var state := State.IDLE
var current_wave_index := -1
var intermission_remaining := 0.0

var group_states: Array[Dictionary] = []


func _process(delta: float) -> void:
	match state:
		State.INTERMISSION:
			process_intermission(delta)

		State.COMBAT:
			process_wave(delta)


func start() -> void:
	if wave_set == null:
		push_error("WaveDirector requires a WaveSetDefinition.")
		return

	if wave_set.waves.is_empty():
		push_error("WaveSet contains no waves.")
		return

	begin_intermission(0)


func process_intermission(delta: float) -> void:
	intermission_remaining -= delta

	if intermission_remaining <= 0.0:
		start_current_wave()


func process_wave(delta: float) -> void:
	for group_state in group_states:
		process_spawn_group(group_state, delta)

	if not all_groups_finished():
		return

	if enemies.get_child_count() > 0:
		return

	complete_current_wave()


func process_spawn_group(group_state: Dictionary, delta: float) -> void:
	var definition: WaveSpawnGroupDefinition = group_state["definition"]

	if group_state["spawned"] >= definition.count:
		return

	group_state["elapsed"] += delta

	while group_state["spawned"] < definition.count and group_state["elapsed"] >= group_state["next_spawn_time"]:
		enemy_spawner.spawn_enemy(definition.enemy_scene, definition.spawn_sides)

		group_state["spawned"] += 1
		group_state["next_spawn_time"] += definition.spawn_interval

		if definition.spawn_interval <= 0.0:
			group_state["next_spawn_time"] = group_state["elapsed"]


func begin_intermission(wave_index: int) -> void:
	current_wave_index = wave_index

	var definition := wave_set.waves[current_wave_index]
	var duration := definition.intermission_duration

	if duration < 0.0:
		if current_wave_index == 0:
			duration = wave_set.initial_intermission_duration
		else:
			duration = wave_set.default_intermission_duration

	intermission_remaining = duration
	state = State.INTERMISSION

	intermission_started.emit(
		current_wave_index + 1,
		wave_set.waves.size(),
		duration
	)

	if duration <= 0.0:
		start_current_wave()


func start_current_wave() -> void:
	var definition := wave_set.waves[current_wave_index]

	group_states.clear()

	for spawn_group in definition.spawn_groups:
		if spawn_group == null:
			continue

		group_states.append({
			"definition": spawn_group,
			"spawned": 0,
			"elapsed": 0.0,
			"next_spawn_time": spawn_group.start_delay
		})

	state = State.COMBAT

	wave_started.emit(
		current_wave_index + 1,
		wave_set.waves.size(),
		definition
	)


func all_groups_finished() -> bool:
	for group_state in group_states:
		var definition: WaveSpawnGroupDefinition = group_state["definition"]

		if group_state["spawned"] < definition.count:
			return false

	return true


func complete_current_wave() -> void:
	var definition := wave_set.waves[current_wave_index]

	wave_completed.emit(
		current_wave_index + 1,
		wave_set.waves.size(),
		definition
	)

	var next_wave_index := current_wave_index + 1

	if next_wave_index >= wave_set.waves.size():
		state = State.COMPLETE
		all_waves_completed.emit()
		return

	begin_intermission(next_wave_index)
