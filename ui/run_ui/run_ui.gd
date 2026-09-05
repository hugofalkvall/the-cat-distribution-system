class_name RunUI
extends CanvasLayer

signal building_selected(definition: BuildingDefinition)
signal start_wave_requested
signal reward_selected(reward: RewardDefinition)
signal reward_reroll_requested
signal reward_skip_requested

const BUILDING_BUTTON_SCENE := preload("res://ui/building_button/building_button.tscn")

@onready var idol_health_label: Label = $HUD/HBoxContainer/IdolHealthLabel
@onready var idol_health_bar: ProgressBar = $HUD/HBoxContainer/IdolHealthProgressBar
@onready var total_cat_count_label: Label = $HUD/StatContainer/CatCountTotalLabel
@onready var current_cat_count_label: Label = $HUD/StatContainer/CatCountLabel
@onready var currency_label: Label = $HUD/StatContainer/Currency
@onready var building_container: VBoxContainer = $HUD/BuildingContainer
@onready var game_over_phase_label: Label = $Overlays/GameOverPhaseLabel
@onready var victory_phase_label: Label = $Overlays/VictoryPhaseLabel
@onready var intermission_phase_label: Label = $Overlays/IntermissionPhaseLabel
@onready var wave_progress_container: HBoxContainer = $Overlays/HBoxContainer
@onready var wave_progress_label: Label = $Overlays/HBoxContainer/WaveProgressLabel
@onready var wave_progress_bar: ProgressBar = $Overlays/HBoxContainer/WaverogressBar
@onready var start_wave_button: Button = $HUD/StartWaveButton
@onready var arena_reference: Sprite2D = $ArenaReference
@onready var reward_choice_overlay: RewardChoiceOverlay = $RewardChoiceOverlay
@onready var HUD: Control = $HUD
@onready var building_stats: VBoxContainer = $Overlays/BuildingStats
@onready var building_name_label: Label = $Overlays/BuildingStats/BuildingName
@onready var building_type_label: Label = $Overlays/BuildingStats/BuildingType
@onready var distribution_rate_label: Label = $Overlays/BuildingStats/CDSCount
@onready var unit_information_label: Label = $Overlays/BuildingStats/UnitInformation

var run_state: Run
var building_buttons: Array[BuildingButton] = []
var intermission_phase_text := ""


func setup(new_run: Run, idol: Damageable) -> void:
	run_state = new_run
	intermission_phase_text = intermission_phase_label.text
	arena_reference.visible = false
	building_stats.visible = false

	idol.health_changed.connect(_on_idol_health_changed)
	run_state.game_over.connect(_on_game_over)
	run_state.victory.connect(_on_victory)
	run_state.wave_finnished.connect(_on_wave_finnished)
	run_state.cat_count_changed.connect(_on_cat_count_changed)
	run_state.currency_changed.connect(_on_currency_changed)
	run_state.wave_progress_changed.connect(_on_wave_progress_changed)
	run_state.available_buildings_changed.connect(populate_building_buttons)
	run_state.placed_building_selection_changed.connect(_on_placed_building_selection_changed)
	run_state.passives_changed.connect(_on_passives_changed)

	reward_choice_overlay.reward_selected.connect(_on_reward_selected)
	reward_choice_overlay.reroll_requested.connect(_on_reward_reroll_requested)
	reward_choice_overlay.skip_requested.connect(_on_reward_skip_requested)
	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	start_wave_button.visible = false

	idol_health_bar.max_value = idol.max_health
	idol_health_bar.value = idol.current_health

	update_cat_count_label(run_state.total_cats_produced)
	update_current_cat_count_label(run_state.current_cat_count)
	update_currency_label(run_state.currency)

	populate_building_buttons()

	game_over_phase_label.visible = false
	victory_phase_label.visible = false
	intermission_phase_label.visible = false

	wave_progress_container.visible = false
	wave_progress_bar.min_value = 0
	wave_progress_bar.max_value = 100
	wave_progress_bar.value = 0

func _on_reward_reroll_requested() -> void:
	reward_reroll_requested.emit()

func _on_reward_skip_requested() -> void:
	reward_skip_requested.emit()
	
func populate_building_buttons() -> void:
	for child in building_container.get_children():
		child.queue_free()

	building_buttons.clear()

	for definition in run_state.available_buildings:
		if definition == null:
			continue

		var button := BUILDING_BUTTON_SCENE.instantiate() as BuildingButton

		if button == null:
			continue

		building_container.add_child(button)

		var cost := run_state.get_building_cost(definition)

		button.setup(definition, cost)
		button.set_affordable(run_state.currency >= cost)
		button.selected.connect(_on_building_button_selected)
		
		building_buttons.append(button)

func _on_placed_building_selection_changed(_building: Building) -> void:
	refresh_selected_building_stats()


func _on_passives_changed() -> void:
	refresh_selected_building_stats()
	update_building_button_affordability(run_state.currency)


func refresh_selected_building_stats() -> void:
	var building := run_state.selected_placed_building

	if not is_instance_valid(building) or building.definition == null:
		building_stats.visible = false
		return

	var definition := building.definition
	var distribution_rate := snappedf(building.get_current_distribution_per_second(), 0.001)

	building_name_label.text = definition.display_name
	building_type_label.text = "Type: " + definition.get_building_type_name()
	distribution_rate_label.text = "Distribution: " + str(distribution_rate) + " cats/s"
	unit_information_label.text = "Distributes: " + definition.produced_unit_name
	building_stats.visible = true
	
func _on_building_button_selected(definition: BuildingDefinition) -> void:
	building_selected.emit(definition)

func _on_idol_health_changed(_idol: Damageable, current_health: float, max_health: float) -> void:
	idol_health_bar.max_value = max_health
	idol_health_bar.value = current_health
	update_idol_health_label(current_health, max_health)

func _on_wave_progress_changed(defeated_enemies: int, total_enemies: int) -> void:
	if total_enemies <= 0:
		wave_progress_bar.value = 0
		return

	var progress := float(defeated_enemies) / float(total_enemies)

	wave_progress_bar.value = progress * 100.0

func show_wave_progress() -> void:
	wave_progress_container.visible = true
	wave_progress_bar.value = 0

func hide_wave_progress() -> void:
	wave_progress_container.visible = false
	
func _on_start_wave_button_pressed() -> void:
	intermission_phase_label.visible = false
	show_wave_progress() 
	start_wave_requested.emit()

func _on_wave_finnished() -> void:
	intermission_phase_label.text = intermission_phase_text
	intermission_phase_label.visible = true
	hide_wave_progress()

func set_start_wave_button_visible(visible: bool) -> void:
	start_wave_button.visible = visible

func update_next_wave(next_wave_number: int, _total_waves: int) -> void:
	if next_wave_number == 1:
		start_wave_button.text = "Start"
	else:
		start_wave_button.text = "Next wave"

func update_idol_health_label(_current_health: float, _max_health: float) -> void:
	idol_health_label.text = "Health"


func _on_game_over() -> void:
	game_over_phase_label.visible = true
	intermission_phase_label.visible = false

	for button in building_buttons:
		button.disabled = true

func _on_victory() -> void:
	victory_phase_label.visible = true
	intermission_phase_label.visible = false
	
	for button in building_buttons:
		button.disabled = true


func _on_cat_count_changed(total_cats: int, current_cats: int) -> void:
	update_cat_count_label(total_cats)
	update_current_cat_count_label(current_cats)


func update_cat_count_label(total_cats: int) -> void:
	total_cat_count_label.text = "Total cats distributed: " + str(total_cats)


func update_current_cat_count_label(current_cats: int) -> void:
	current_cat_count_label.text = "Current cats: " + str(current_cats)


func _on_currency_changed(total_currency: int) -> void:
	update_currency_label(total_currency)
	update_building_button_affordability(total_currency)


func update_currency_label(total_currency: int) -> void:
	currency_label.text = "Currency: " + str(total_currency)


func update_building_button_affordability(total_currency: int) -> void:
	for button in building_buttons:
		if button.definition == null:
			continue

		var cost := run_state.get_building_cost(button.definition)

		button.update_cost(cost)
		button.set_affordable(total_currency >= cost)
		
func show_reward_choice(event: ChoiceEventDefinition, options: Array[RewardDefinition]) -> void:
	intermission_phase_label.text = intermission_phase_text
	intermission_phase_label.visible = false
	HUD.hide()
	reward_choice_overlay.show_choice(event, options)


func show_building_reward_placement(definition: BuildingDefinition) -> void:
	reward_choice_overlay.hide_choice()
	HUD.show()
	intermission_phase_label.text = "Place " + definition.display_name
	intermission_phase_label.visible = true


func hide_reward_choice() -> void:
	reward_choice_overlay.hide_choice()
	intermission_phase_label.text = intermission_phase_text
	intermission_phase_label.visible = true
	HUD.show()
	


func _on_reward_selected(reward: RewardDefinition) -> void:
	reward_selected.emit(reward)
