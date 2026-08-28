class_name RunUI
extends CanvasLayer

signal building_selected(definition: BuildingDefinition)
signal start_wave_requested

const BUILDING_BUTTON_SCENE := preload("res://ui/building_button/building_button.tscn")

@onready var idol_health_label: Label = $HUD/StatContainer/IdolHealthLabel
@onready var idol_health_bar: ProgressBar = $HUD/StatContainer/IdolHealthProgressBar

@onready var total_cat_count_label: Label = $HUD/StatContainer/CatCountTotalLabel
@onready var current_cat_count_label: Label = $HUD/StatContainer/CatCountLabel

@onready var currency_label: Label = $HUD/StatContainer/Currency
@onready var building_container: VBoxContainer = $HUD/BuildingContainer

@onready var game_over_label: Label = $Overlays/GameOverLabel
@onready var victory_label: Label = $Overlays/VictoryLabel
@onready var start_wave_button: Button = $HUD/StartWaveButton

var run_state: Run
var building_buttons: Array[BuildingButton] = []


func setup(new_run: Run, idol: Damageable) -> void:
	run_state = new_run

	idol.health_changed.connect(_on_idol_health_changed)
	run_state.game_over.connect(_on_game_over)
	run_state.victory.connect(_on_victory)
	run_state.cat_count_changed.connect(_on_cat_count_changed)
	run_state.currency_changed.connect(_on_currency_changed)

	start_wave_button.pressed.connect(_on_start_wave_button_pressed)
	start_wave_button.visible = false

	idol_health_bar.max_value = idol.max_health
	idol_health_bar.value = idol.current_health

	update_cat_count_label(run_state.total_cats_produced)
	update_current_cat_count_label(run_state.current_cat_count)
	update_currency_label(run_state.currency)

	populate_building_buttons()

	game_over_label.visible = false
	victory_label.visible = false


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


func _on_building_button_selected(definition: BuildingDefinition) -> void:
	building_selected.emit(definition)


func _on_idol_health_changed(_idol: Damageable, current_health: float, max_health: float) -> void:
	idol_health_bar.max_value = max_health
	idol_health_bar.value = current_health
	update_idol_health_label(current_health, max_health)
	
func _on_start_wave_button_pressed() -> void:
	start_wave_requested.emit()


func set_start_wave_button_visible(visible: bool) -> void:
	start_wave_button.visible = visible


func update_idol_health_label(_current_health: float, _max_health: float) -> void:
	idol_health_label.text = "Health"


func _on_game_over() -> void:
	game_over_label.visible = true

	for button in building_buttons:
		button.disabled = true

func _on_victory() -> void:
	victory_label.visible = true
	
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
