class_name RewardCard
extends TextureButton

signal selected(reward: RewardDefinition)

@onready var reward_title: Label = $RewardTitle
@onready var description_label: Label = $Description
@onready var icon_rect: TextureRect = $Icon

var reward: RewardDefinition


func setup(definition: RewardDefinition) -> void:
	reward = definition

	if reward == null:
		return

	reward_title.text = reward.display_name
	#reward_title.label_settings.font_size = 8
	#reward_title.position = Vector2i (10,10)

	description_label.text = reward.description
	#description_label.label_settings.font_size = 7
	#description_label.position = Vector2i (12, 85)
	
	icon_rect.texture = reward.icon
	icon_rect.size = Vector2i(32, 32)


func _ready() -> void:
	pivot_offset = size / 2.0
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_pressed() -> void:
	if reward == null:
		return

	selected.emit(reward)
	
func _on_mouse_entered() -> void:
	animate_scale(Vector2(1.04, 1.04))

func _on_mouse_exited() -> void:
	animate_scale(Vector2(1, 1))

func animate_scale(target_scale: Vector2) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", target_scale, 0.08)
	
func play_enter_animation(delay: float = 0.0) -> void:
	modulate.a = 0.0
	scale = Vector2(0.85, 0.85)

	await get_tree().process_frame

	pivot_offset = size / 2.0

	var tween := create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_delay(delay)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_delay(delay)
