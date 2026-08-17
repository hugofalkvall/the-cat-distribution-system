class_name RunUI
extends CanvasLayer

@onready var idol_health_label: Label = $HUD/StatContainer/IdolHealthLabel
@onready var idol_health_bar: ProgressBar = $HUD/StatContainer/IdolHealthProgressBar

@onready var total_cat_count_label: Label = $HUD/StatContainer/CatCountTotalLabel
@onready var current_cat_count_label: Label = $HUD/StatContainer/CatCountLabel

@onready var game_over_label: Label = $Overlays/GameOverLabel

@onready var currency_label: Label = $HUD/StatContainer/Currency


func setup(run: Run, idol: Damageable) -> void:
	idol.health_changed.connect(_on_idol_health_changed)
	run.game_over.connect(_on_game_over)
	run.cat_count_changed.connect(_on_cat_count_changed)
	run.currency_changed.connect(_on_currency_changed)

	idol_health_bar.max_value = idol.max_health
	idol_health_bar.value = idol.current_health

	update_cat_count_label(run.total_cats_produced)
	update_current_cat_count_label(run.current_cat_count)
	update_currency_label(run.currency)

	game_over_label.visible = false


func _on_idol_health_changed(_idol: Damageable, current_health: float, max_health: float) -> void:
	idol_health_bar.max_value = max_health
	idol_health_bar.value = current_health
	update_idol_health_label(current_health, max_health)


func update_idol_health_label(current_health: float, max_health: float) -> void:
	idol_health_label.text = "Health"


func _on_game_over() -> void:
	print("UI should show game over")
	game_over_label.visible = true


func _on_cat_count_changed(total_cats: int, current_cats: int) -> void:
	update_cat_count_label(total_cats)
	update_current_cat_count_label(current_cats)


func update_cat_count_label(total_cats: int) -> void:
	total_cat_count_label.text = "Total cats distributed: " + str(total_cats)


func update_current_cat_count_label(current_cats: int) -> void:
	current_cat_count_label.text = "Current cats: " + str(current_cats)


func _on_currency_changed(total_currency: int) -> void:
	update_currency_label(total_currency)


func update_currency_label(total_currency: int) -> void:
	currency_label.text = "Currency: " + str(total_currency)
