class_name CombatUnit
extends Node2D

signal health_changed(unit: CombatUnit, current_health: float, max_health: float)
signal died(unit: CombatUnit)

@export var max_health := 10.0
@export var attack: AttackDefinition

@export_group("Health Bar")
@export var health_bar_width := 14.0
@export var health_bar_height := 2.0
@export var health_bar_offset_y := -10.0
@export var health_bar_always_visible := true

var current_health := 0.0
var attack_cooldown_remaining := 0.0
var is_dead := false


func _ready() -> void:
	current_health = max_health
	queue_redraw()


func tick_combat(delta: float) -> void:
	if attack_cooldown_remaining > 0.0:
		attack_cooldown_remaining = maxf(attack_cooldown_remaining - delta, 0.0)


func try_attack(target: CombatUnit, combat_system: Node) -> bool:
	if is_dead:
		return false

	if attack == null:
		return false

	if combat_system == null:
		return false

	if attack_cooldown_remaining > 0.0:
		return false

	if not is_instance_valid(target):
		return false

	if target.is_dead:
		return false

	combat_system.perform_attack(self, target, attack)
	attack_cooldown_remaining = attack.cooldown

	return true


func take_damage(amount: float) -> void:
	if is_dead:
		return

	if amount <= 0.0:
		return

	current_health = maxf(current_health - amount, 0.0)

	health_changed.emit(self, current_health, max_health)
	queue_redraw()

	if current_health <= 0.0:
		die()


func die() -> void:
	if is_dead:
		return

	is_dead = true
	died.emit(self)
	queue_free()


func _draw() -> void:
	if max_health <= 0.0:
		return

	if not health_bar_always_visible and current_health >= max_health:
		return

	var health_percentage := current_health / max_health
	var bar_position := Vector2(-health_bar_width / 2.0, health_bar_offset_y)

	draw_rect(Rect2(bar_position, Vector2(health_bar_width, health_bar_height)), Color(0.1, 0.1, 0.1, 0.9))

	var health_width := health_bar_width * health_percentage
	draw_rect(Rect2(bar_position, Vector2(health_width, health_bar_height)), Color(0.2, 0.9, 0.2, 1.0))
