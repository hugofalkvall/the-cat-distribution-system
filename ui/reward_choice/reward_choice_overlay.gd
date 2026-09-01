class_name RewardChoiceOverlay
extends Control

signal reward_selected(reward: RewardDefinition)
signal reroll_requested
signal skip_requested

const REWARD_CARD_SCENE := preload("res://ui/reward_choice/reward_card.tscn")

@onready var title_label: Label = $CenterContainer/PanelContainer/HeaderPanel/TitleLabel
@onready var options_container: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/OptionsContainer
@onready var reroll_button: Button = $CenterContainer/PanelContainer/MarginContainer2/ButtonContainer/RerollButton
@onready var skip_button: Button = $CenterContainer/PanelContainer/MarginContainer2/ButtonContainer/SkipButton


func _ready() -> void:
	visible = false

	reroll_button.pressed.connect(_on_reroll_pressed)
	skip_button.pressed.connect(_on_skip_pressed)

func _on_reroll_pressed() -> void:
	reroll_requested.emit()


func _on_skip_pressed() -> void:
	skip_requested.emit()

func show_choice(event: ChoiceEventDefinition, options: Array[RewardDefinition]) -> void:
	clear_options()

	title_label.text = event.display_name
	reroll_button.visible = event.allow_reroll
	skip_button.visible = event.allow_skip

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
