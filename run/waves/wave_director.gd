class_name WaveDirector
extends Node

signal intermission_started(wave_number: int, total_waves: int, duration: float)
signal wave_started(wave_number: int, total_waves: int, definition: WaveDefinition)
signal wave_completed(wave_number: int, total_waves: int, definition: WaveDefinition)
signal wave_progress_changed(defeated_enemies: int, total_enemies: int)
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

var current_wave_total_enemies := 0
var last_reported_defeated_enemies := -1

var group_states: Array[Dictionary] = []


func _process(delta: float) -> void:
	match state:
		State.INTERMISSION:
			pass

		State.COMBAT:
			process_wave(delta)


func start() -> void:
	if wave_set == null:
		push_error("WaveDirector requires a WaveSetDefinition.")
		return

	if wave_set.waves.is_empty():
		push_error("WaveSet contains no waves.")
		return

	begin_intermission()


func process_wave(delta: float) -> void:
	for group_state in group_states:
		process_spawn_group(group_state, delta)

	report_wave_progress()

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
		var enemy := enemy_spawner.spawn_enemy(
			definition.enemy_scene,
			definition.spawn_sides
		)

		if enemy == null:
			push_error("WaveDirector failed to spawn enemy.")
			return

		group_state["spawned"] += 1
		group_state["next_spawn_time"] += definition.spawn_interval

		if definition.spawn_interval <= 0.0:
			group_state["next_spawn_time"] = group_state["elapsed"]


func begin_intermission() -> void:
	var next_wave_index := current_wave_index + 1
	var definition := wave_set.waves[next_wave_index]
	var duration := definition.intermission_duration

	if duration < 0.0:
		if next_wave_index == 0:
			duration = wave_set.initial_intermission_duration
		else:
			duration = wave_set.default_intermission_duration

	intermission_remaining = duration
	state = State.INTERMISSION

	intermission_started.emit(
		next_wave_index + 1,
		wave_set.waves.size(),
		duration
	)

	if duration <= 0.0:
		start_current_wave()


func start_current_wave() -> void:
	current_wave_index += 1

	var definition := wave_set.waves[current_wave_index]

	group_states.clear()

	current_wave_total_enemies = 0
	last_reported_defeated_enemies = -1

	for spawn_group in definition.spawn_groups:
		if spawn_group == null:
			continue

		current_wave_total_enemies += spawn_group.count

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

	report_wave_progress()

func get_unspawned_enemy_count() -> int:
	var unspawned := 0

	for group_state in group_states:
		var definition: WaveSpawnGroupDefinition = group_state["definition"]
		var spawned: int = group_state["spawned"]

		unspawned += definition.count - spawned

	return unspawned


func get_defeated_enemy_count() -> int:
	var unspawned := get_unspawned_enemy_count()
	var alive := enemies.get_child_count()

	return maxi(current_wave_total_enemies - unspawned - alive, 0)


func report_wave_progress() -> void:
	if current_wave_total_enemies <= 0:
		return

	var defeated := get_defeated_enemy_count()

	if defeated == last_reported_defeated_enemies:
		return

	last_reported_defeated_enemies = defeated

	wave_progress_changed.emit(
		defeated,
		current_wave_total_enemies
	)

func all_groups_finished() -> bool:
	for group_state in group_states:
		var definition: WaveSpawnGroupDefinition = group_state["definition"]

		if group_state["spawned"] < definition.count:
			return false

	return true


func complete_current_wave() -> void:
	var definition := wave_set.waves[current_wave_index]

	last_reported_defeated_enemies = current_wave_total_enemies

	wave_progress_changed.emit(
		current_wave_total_enemies,
		current_wave_total_enemies
	)

	wave_completed.emit(
		current_wave_index + 1,
		wave_set.waves.size(),
		definition
	)

	if current_wave_index + 1 >= wave_set.waves.size():
		state = State.COMPLETE
		all_waves_completed.emit()
		return

	begin_intermission()
