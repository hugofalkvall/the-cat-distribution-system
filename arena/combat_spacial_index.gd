class_name CombatSpatialIndex
extends Node

const BUCKET_SIZE := 64.0
const UPDATE_INTERVAL := 0.1

@export var cats_parent: Node2D
@export var enemies_parent: Node2D

var cats_by_bucket: Dictionary = {}
var enemies_by_bucket: Dictionary = {}

var update_timer := 0.0


func _process(delta: float) -> void:
	update_timer += delta

	if update_timer >= UPDATE_INTERVAL:
		update_timer = 0.0
		rebuild()
	
	print(cats_by_bucket)
	print(enemies_by_bucket)


func rebuild() -> void:
	cats_by_bucket.clear()
	enemies_by_bucket.clear()

	for cat in cats_parent.get_children():
		add_to_bucket(cats_by_bucket,cat)

	for enemy in enemies_parent.get_children():
		add_to_bucket(enemies_by_bucket,enemy)


func add_to_bucket(buckets: Dictionary, unit: Node2D) -> void:
	var bucket := position_to_bucket(unit.global_position)

	if not buckets.has(bucket):
		buckets[bucket] = []

	buckets[bucket].append(unit)


func position_to_bucket(position: Vector2) -> Vector2i:
	return Vector2i(
		floor(position.x / BUCKET_SIZE),
		floor(position.y / BUCKET_SIZE)
	)
