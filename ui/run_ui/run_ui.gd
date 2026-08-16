class_name RunUI
extends CanvasLayer

@onready var idol_health_label: Label = $HUD/IdolHealthLabel
@onready var idol_health_bar: ProgressBar = $HUD/IdolHealthBar


func setup(run: Run, idol: Damageable) -> void:
	idol.health_changed.connect(_on_idol_health_changed)
	run.game_over.connect(_on_game_over)

	idol_health_bar.max_value = idol.max_health
	idol_health_bar.value = idol.current_health
	update_idol_health_label(idol.current_health, idol.max_health)


func _on_idol_health_changed(_idol: Damageable, current_health: float, max_health: float) -> void:
	idol_health_bar.max_value = max_health
	idol_health_bar.value = current_health
	update_idol_health_label(current_health, max_health)


func _on_game_over() -> void:
	print("UI should show game over")


func update_idol_health_label(current_health: float, max_health: float) -> void:
	idol_health_label.text = "%d / %d" % [current_health, max_health]
