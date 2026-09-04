class_name RewardChoiceOverlay
extends Control

signal reward_selected(reward: RewardDefinition)
signal reroll_requested
signal skip_requested

const REWARD_CARD_SCENE := preload("res://ui/reward_choice/reward_card.tscn")

const CARD_STAGGER := 0.07
const OVERLAY_ENTER_DURATION := 0.25
const OVERLAY_EXIT_DURATION := 0.16

@onready var dimmer: ColorRect = $ColorRect
@onready var panel: TextureRect = $CenterContainer/PanelContainer
@onready var title_label: Label = $CenterContainer/PanelContainer/TitleLabel
@onready var options_container: HBoxContainer = $CenterContainer/PanelContainer/MarginContainer/OptionsContainer
@onready var reroll_button: TextureButton = $RerollButton
@onready var skip_button: TextureButton = $SkipButton
@onready var action_container: Control = $CenterContainer/PanelContainer/MarginContainer2

var _overlay_tween: Tween
var _selection_in_progress := false
var _presentation_version := 0


func _ready() -> void:
	visible = false

	reroll_button.pressed.connect(_on_reroll_pressed)
	skip_button.pressed.connect(_on_skip_pressed)


func _on_reroll_pressed() -> void:
	if _selection_in_progress:
		return

	reroll_requested.emit()


func _on_skip_pressed() -> void:
	if _selection_in_progress:
		return

	skip_requested.emit()


func show_choice(event: ChoiceEventDefinition, options: Array[RewardDefinition]) -> void:
	_presentation_version += 1

	var current_version := _presentation_version
	var show_actions := event.allow_reroll or event.allow_skip
	var cards: Array[RewardCard] = []

	_selection_in_progress = false

	_kill_overlay_tween()
	clear_options()

	title_label.text = event.display_name
	reroll_button.visible = event.allow_reroll
	reroll_button.disabled = false
	skip_button.visible = event.allow_skip
	skip_button.disabled = false

	for reward: RewardDefinition in options:
		var card := REWARD_CARD_SCENE.instantiate() as RewardCard

		if card == null:
			push_error("RewardChoiceOverlay: failed to instantiate RewardCard.")
			continue

		options_container.add_child(card)
		card.setup(reward)
		card.selected.connect(_on_reward_selected)
		cards.append(card)

	dimmer.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.95, 0.95)
	visible = true

	await get_tree().process_frame

	if not is_inside_tree():
		return

	if current_version != _presentation_version:
		return

	panel.pivot_offset = panel.size / 2.0

	_play_overlay_enter_animation()

	for index in range(cards.size()):
		var card := cards[index]

		if is_instance_valid(card):
			card.play_enter_animation(index * CARD_STAGGER)


func hide_choice() -> void:
	_presentation_version += 1
	_selection_in_progress = false

	_kill_overlay_tween()

	visible = false
	clear_options()


func clear_options() -> void:
	for child in options_container.get_children():
		options_container.remove_child(child)
		child.queue_free()


func _on_reward_selected(reward: RewardDefinition) -> void:
	if _selection_in_progress:
		return

	_selection_in_progress = true
	reroll_button.disabled = true
	skip_button.disabled = true

	var selected_card: RewardCard

	for child in options_container.get_children():
		var card := child as RewardCard

		if card == null:
			continue

		card.disabled = true

		if card.reward == reward:
			selected_card = card
		else:
			card.play_deselected_animation()

	if selected_card != null:
		await selected_card.play_selected_animation()

	if not is_inside_tree():
		return

	await _play_overlay_exit_animation()

	if not is_inside_tree():
		return

	visible = false
	_selection_in_progress = false

	reward_selected.emit(reward)


func _play_overlay_enter_animation() -> void:
	_kill_overlay_tween()

	_overlay_tween = create_tween()
	_overlay_tween.set_parallel(true)
	_overlay_tween.tween_property(dimmer, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_overlay_tween.tween_property(panel, "modulate:a", 1.0, 0.20)
	_overlay_tween.tween_property(panel, "scale", Vector2.ONE, OVERLAY_ENTER_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _play_overlay_exit_animation() -> void:
	_kill_overlay_tween()

	_overlay_tween = create_tween()
	_overlay_tween.set_parallel(true)
	_overlay_tween.tween_property(dimmer, "modulate:a", 0.0, OVERLAY_EXIT_DURATION)
	_overlay_tween.tween_property(panel, "modulate:a", 0.0, OVERLAY_EXIT_DURATION)
	_overlay_tween.tween_property(panel, "scale", Vector2(0.80, 0.80), OVERLAY_EXIT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await _overlay_tween.finished


func _kill_overlay_tween() -> void:
	if _overlay_tween != null and _overlay_tween.is_valid():
		_overlay_tween.kill()
