class_name RewardCard
extends TextureButton

signal selected(reward: RewardDefinition)

const ENTER_SCALE := Vector2(0.85, 0.85)
const HOVER_SCALE := Vector2(1.06, 1.06)
const SELECTED_SCALE := Vector2(1.10, 1.10)
const DESELECTED_SCALE := Vector2(0.92, 0.92)

const ENTER_DURATION := 0.30
const HOVER_IN_DURATION := 0.12
const HOVER_OUT_DURATION := 0.10

const SELECTED_TINT := Color(1.0, 0.92, 0.65, 1.0)
const DESELECTED_TINT := Color(1.0, 1.0, 1.0, 0.25)

@onready var reward_title: Label = $RewardTitle
@onready var description_label: Label = $Description
@onready var icon_rect: TextureRect = $Icon

var reward: RewardDefinition
var _animation_tween: Tween
var _is_entering := false


func _ready() -> void:
	pivot_offset = size / 2.0

	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(definition: RewardDefinition) -> void:
	reward = definition

	if reward == null:
		return

	reward_title.text = reward.display_name
	description_label.text = reward.description
	icon_rect.texture = reward.icon
	icon_rect.size = Vector2i(32, 32)


func _on_pressed() -> void:
	if reward == null or disabled:
		return

	selected.emit(reward)


func _on_mouse_entered() -> void:
	if disabled or _is_entering:
		return

	_animate_scale(HOVER_SCALE, HOVER_IN_DURATION)


func _on_mouse_exited() -> void:
	if disabled or _is_entering:
		return

	_animate_scale(Vector2.ONE, HOVER_OUT_DURATION)


func _animate_scale(target_scale: Vector2, duration: float) -> void:
	_kill_animation_tween()

	_animation_tween = create_tween()
	_animation_tween.set_trans(Tween.TRANS_CUBIC)
	_animation_tween.set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(self, "scale", target_scale, duration)


func play_enter_animation(delay: float = 0.0) -> void:
	_kill_animation_tween()

	_is_entering = true
	modulate = Color(1.0, 1.0, 1.0, 0.0)
	scale = ENTER_SCALE

	await get_tree().process_frame

	if not is_inside_tree():
		return

	pivot_offset = size / 2.0

	_animation_tween = create_tween()
	_animation_tween.set_parallel(true)
	_animation_tween.tween_property(self, "modulate:a", 1.0, ENTER_DURATION).set_delay(delay)
	_animation_tween.tween_property(self, "scale", Vector2.ONE, ENTER_DURATION).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await _animation_tween.finished

	_is_entering = false

	if is_hovered() and not disabled:
		_animate_scale(HOVER_SCALE, HOVER_IN_DURATION)


func play_selected_animation() -> void:
	_is_entering = false
	disabled = true

	_kill_animation_tween()

	pivot_offset = size / 2.0

	var normal_texture: Texture2D = texture_normal

	if texture_pressed != null:
		texture_normal = texture_pressed

	_animation_tween = create_tween()
	_animation_tween.tween_property(self, "scale", SELECTED_SCALE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_animation_tween.parallel().tween_property(self, "modulate", SELECTED_TINT, 0.12)
	_animation_tween.tween_property(self, "scale", Vector2(0.98, 0.98), 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_animation_tween.parallel().tween_property(self, "modulate", Color.WHITE, 0.10)
	_animation_tween.tween_property(self, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	await _animation_tween.finished

	texture_normal = normal_texture


func play_deselected_animation() -> void:
	_is_entering = false
	disabled = true

	_kill_animation_tween()

	pivot_offset = size / 2.0

	_animation_tween = create_tween()
	_animation_tween.set_parallel(true)
	_animation_tween.tween_property(self, "scale", DESELECTED_SCALE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_animation_tween.tween_property(self, "modulate", DESELECTED_TINT, 0.22)


func _kill_animation_tween() -> void:
	if _animation_tween != null and _animation_tween.is_valid():
		_animation_tween.kill()
