class_name WaveSpawnGroupDefinition
extends Resource

@export var enemy_scene: PackedScene
@export_range(1, 10000, 1) var count := 1
@export_range(0.0, 60.0, 0.1) var start_delay := 0.0
@export_range(0.0, 60.0, 0.1) var spawn_interval := 1.0

@export_flags("North", "East", "West") var spawn_sides := 7
