class_name Building
extends Node2D

const SELECTED_INDICATOR_TEXTURE := preload("res://buildings/Selected_indicator.png")

const PLACEMENT_DROP_DISTANCE := 60.0
const PLACEMENT_DROP_DURATION := 0.12
const IMPACT_DURATION := 0.06
const REBOUND_DURATION := 0.06
const SETTLE_DURATION := 0.06

const DROP_SCALE := Vector2(0.96, 1.04)
const IMPACT_SCALE := Vector2(1.05, 0.9)
const REBOUND_SCALE := Vector2(1.02, 1.02)

static var dust_texture: Texture2D

var definition: BuildingDefinition
var context: BuildingContext

var selected_indicator: Sprite2D
var placement_sprite: Sprite2D
var placement_tween: Tween

var sprite_rest_position := Vector2.ZERO
var sprite_rest_scale := Vector2.ONE


func setup(new_definition: BuildingDefinition, new_context: BuildingContext) -> void:
	definition = new_definition
	context = new_context

	setup_selected_indicator()
	setup_placement_animation()


func setup_selected_indicator() -> void:
	if selected_indicator != null:
		return

	selected_indicator = Sprite2D.new()
	selected_indicator.name = "SelectedIndicator"
	selected_indicator.texture = SELECTED_INDICATOR_TEXTURE
	selected_indicator.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	selected_indicator.centered = true
	selected_indicator.z_index = 10
	selected_indicator.visible = false

	add_child(selected_indicator)

	var footprint_size := Vector2(definition.size.x * context.grid.CELL_SIZE, definition.size.y * context.grid.CELL_SIZE)

	selected_indicator.position = footprint_size / 2.0

	var texture_size := SELECTED_INDICATOR_TEXTURE.get_size()

	if texture_size.x > 0.0 and texture_size.y > 0.0:
		selected_indicator.scale = footprint_size / texture_size


func setup_placement_animation() -> void:
	placement_sprite = get_node_or_null("Sprite2D") as Sprite2D
	sprite_rest_position = placement_sprite.position
	sprite_rest_scale = placement_sprite.scale


func play_placement_animation() -> void:
	if placement_sprite == null:
		return

	kill_placement_tween()

	var impact_position := get_anchored_sprite_position(IMPACT_SCALE)
	var rebound_position := get_anchored_sprite_position(REBOUND_SCALE)

	placement_sprite.position = sprite_rest_position + Vector2(0.0, -PLACEMENT_DROP_DISTANCE)
	placement_sprite.scale = sprite_rest_scale * DROP_SCALE

	placement_tween = create_tween()

	placement_tween.tween_property(placement_sprite, "position", sprite_rest_position, PLACEMENT_DROP_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	placement_tween.parallel().tween_property(placement_sprite, "scale", sprite_rest_scale, PLACEMENT_DROP_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	#placement_tween.tween_callback(emit_impact_particles)

	placement_tween.tween_property(placement_sprite, "scale", sprite_rest_scale * IMPACT_SCALE, IMPACT_DURATION).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	placement_tween.parallel().tween_property(placement_sprite, "position", impact_position, IMPACT_DURATION).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

	placement_tween.tween_property(placement_sprite, "scale", sprite_rest_scale * REBOUND_SCALE, REBOUND_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	placement_tween.parallel().tween_property(placement_sprite, "position", rebound_position, REBOUND_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	placement_tween.tween_property(placement_sprite, "scale", sprite_rest_scale, SETTLE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	placement_tween.parallel().tween_property(placement_sprite, "position", sprite_rest_position, SETTLE_DURATION).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func get_anchored_sprite_position(scale_factor: Vector2) -> Vector2:
	if placement_sprite == null or placement_sprite.texture == null:
		return sprite_rest_position

	var texture_size := placement_sprite.texture.get_size()
	var rendered_size := Vector2(texture_size.x * absf(sprite_rest_scale.x), texture_size.y * absf(sprite_rest_scale.y))

	if placement_sprite.centered:
		return sprite_rest_position + Vector2(0.0, rendered_size.y * (1.0 - scale_factor.y) * 0.5)

	var horizontal_offset := rendered_size.x * (1.0 - scale_factor.x) * 0.5
	var vertical_offset := rendered_size.y * (1.0 - scale_factor.y)

	return sprite_rest_position + Vector2(horizontal_offset, vertical_offset)


func emit_impact_particles() -> void:
	if definition == null or context == null or context.grid == null:
		return

	var footprint_size := Vector2(definition.size.x * context.grid.CELL_SIZE, definition.size.y * context.grid.CELL_SIZE)
	var particles := CPUParticles2D.new()

	particles.name = "PlacementImpactParticles"
	particles.position = Vector2(footprint_size.x * 0.5, footprint_size.y - 1.0)
	particles.z_index = 20
	particles.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	particles.texture = get_dust_texture()
	particles.emitting = false
	particles.one_shot = true
	particles.amount = 14
	particles.lifetime = 0.30
	particles.explosiveness = 1.0
	particles.local_coords = true
	particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	particles.emission_rect_extents = Vector2(footprint_size.x * 0.40, 1.0)
	particles.direction = Vector2(0.0, -5.0)
	particles.spread = 80.0
	particles.gravity = Vector2(0.0, 80.0)
	particles.initial_velocity_min = 20.0
	particles.initial_velocity_max = 30.0
	particles.scale_amount_min = 0.8
	particles.scale_amount_max = 1.4
	particles.color = Color(250, 250, 250, 0.60)

	add_child(particles)

	particles.emitting = true

	var cleanup_tween := particles.create_tween()
	cleanup_tween.tween_interval(particles.lifetime + 0.1)
	cleanup_tween.tween_callback(particles.queue_free)


func get_dust_texture() -> Texture2D:
	if dust_texture != null:
		return dust_texture

	var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)

	dust_texture = ImageTexture.create_from_image(image)

	return dust_texture


func kill_placement_tween() -> void:
	if placement_tween != null and placement_tween.is_valid():
		placement_tween.kill()

	if placement_sprite != null:
		placement_sprite.position = sprite_rest_position
		placement_sprite.scale = sprite_rest_scale


func set_selected(selected: bool) -> void:
	if selected_indicator != null:
		selected_indicator.visible = selected
