class_name ClawSwipe
extends AttackBehavior

@export var impact_frame := 2
@export var visual_offset := Vector2.ZERO

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var impact_resolved := false


func _ready() -> void:
	sprite.frame_changed.connect(_on_frame_changed)
	sprite.animation_finished.connect(_on_animation_finished)


func begin() -> void:
	if not is_instance_valid(attacker):
		queue_free()
		return

	var facing_left := is_instance_valid(target) and target.global_position.x < attacker.global_position.x
	var offset := visual_offset

	if facing_left:
		offset.x *= -1.0

	global_position = attacker.global_position + offset

	sprite.flip_h = facing_left
	sprite.play(&"attack")

	try_resolve_impact()


func _on_frame_changed() -> void:
	try_resolve_impact()


func try_resolve_impact() -> void:
	if impact_resolved:
		return

	if sprite.frame < impact_frame:
		return

	resolve_impact()


func resolve_impact() -> void:
	if impact_resolved:
		return

	impact_resolved = true

	var impact_position := initial_target_position

	if is_instance_valid(target):
		impact_position = target.global_position

	resolve(impact_position)


func _on_animation_finished() -> void:
	if sprite.animation != &"attack":
		return

	if not impact_resolved:
		resolve_impact()

	queue_free()
