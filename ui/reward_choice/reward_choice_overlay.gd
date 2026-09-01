class_name RewardChoiceOverlay
extends Control

signal reward_selected(reward: RewardDefinition)

const REWARD_CARD_SCENE := preload("res://ui/reward_choice/reward_card.tscn")

@onready var title_label: Label = $CenterContainer/PanelContainer/HeaderPanel/TitleLabel
@onready var options_container: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/OptionsContainer


func _ready() -> void:
	visible = false


func show_choice(event: ChoiceEventDefinition, options: Array[RewardDefinition]) -> void:
	clear_options()

	title_label.text = event.display_name

	for reward: RewardDefinition in options:
		var card := REWARD_CARD_SCENE.instantiate() as RewardCard

		if card == null:
			push_error("RewardChoiceOverlay: failed to instantiate RewardCard.")
			continue

		options_container.add_child(card)
		card.setup(reward)
		card.selected.connect(_on_reward_selected)

	visible = true


func hide_choice() -> void:
	visible = false
	clear_options()


func clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()


func _on_reward_selected(reward: RewardDefinition) -> void:
	for child in options_container.get_children():
		var card := child as RewardCard

		if card != null:
			card.disabled = true

	reward_selected.emit(reward)
