class_name RewardChoiceOverlay
extends Control

signal reward_selected(reward: RewardDefinition)

@onready var title_label: Label = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/TitleLabel
@onready var options_container: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/VBoxContainer/OptionsContainer


func _ready() -> void:
	visible = false


func show_choice(event: ChoiceEventDefinition, options: Array[RewardDefinition]) -> void:
	clear_options()

	title_label.text = event.display_name

	for reward in options:
		var button := Button.new()

		button.custom_minimum_size = Vector2(140, 96)
		button.text = (
			reward.display_name
			+ "\n\n"
			+ reward.description
		)

		if reward.icon != null:
			button.icon = reward.icon

		button.pressed.connect(
			_on_reward_pressed.bind(reward)
		)

		options_container.add_child(button)

	visible = true


func hide_choice() -> void:
	visible = false
	clear_options()


func clear_options() -> void:
	for child in options_container.get_children():
		child.queue_free()


func _on_reward_pressed(reward: RewardDefinition) -> void:
	for child in options_container.get_children():
		if child is Button:
			child.disabled = true

	reward_selected.emit(reward)
