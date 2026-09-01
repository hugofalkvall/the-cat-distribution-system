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
	reward_title.label_settings.font_size = 8
	reward_title.position = Vector2i (10,10)

	description_label.text = reward.description
	description_label.label_settings.font_size = 7
	description_label.position = Vector2i (12, 85)
	
	icon_rect.texture = reward.icon
	icon_rect.size = Vector2i(32, 32)


func _ready() -> void:
	pressed.connect(_on_pressed)


func _on_pressed() -> void:
	if reward == null:
		return

	selected.emit(reward)
