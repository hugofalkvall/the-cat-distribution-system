class_name RewardCard
extends Control

signal selected(reward: RewardDefinition)

@onready var title_label: Label = $RewardTitle
@onready var description_label: Label = $Description
@onready var icon_rect: TextureRect = $Icon

var reward: RewardDefinition


func setup(definition: RewardDefinition) -> void:
	reward = definition

	title_label.text = reward.display_name
	description_label.text = reward.description
	icon_rect.texture = reward.icon
