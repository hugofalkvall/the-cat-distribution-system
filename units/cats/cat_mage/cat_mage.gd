extends CombatUnit

const MOVE_SPEED := 20.0
const ACCELERATION := 80.0
const COLLISION_RADIUS := 4.0

const WANDER_RADIUS := 120.0
const MIN_TARGET_DISTANCE := 40.0
const TARGET_REACHED_DISTANCE := 5.0
const MAX_WANDER_TARGET_ATTEMPTS := 12

const DETECTION_RANGE := 200.0
const TARGET_UPDATE_INTERVAL := 0.2

const ARENA_MIN := Vector2(128, 32)
const ARENA_MAX := Vector2(512, 352)

var home_position: Vector2
var wander_target_position: Vector2

var arena_grid: ArenaGrid
var spatial_index: CombatSpatialIndex
var combat_system: CombatSystem
var combat_target: CombatUnit = null

var target_update_timer := 0.0
var avoidance_side := 1.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animated_sprite_shader: AnimatedSprite2D = $ShaderSprite

func setup(new_spatial_index: CombatSpatialIndex, new_combat_system: CombatSystem, new_arena_grid: ArenaGrid) -> void:
	spatial_index = new_spatial_index
	combat_system = new_combat_system
	arena_grid = new_arena_grid
	home_position = global_position
	avoidance_side = -1.0 if randf() < 0.5 else 1.0
	target_update_timer = randf_range(0.0, TARGET_UPDATE_INTERVAL)
	choose_new_wander_target()


func _process(delta: float) -> void:
	update_combat_target(delta)

	if is_instance_valid(combat_target) and has_attacks():
		var approach_range := get_approach_range(combat_target)
		var in_attack_range := move_toward_position(combat_target.get_combat_position(), approach_range, delta)

		if in_attack_range:
			try_attack(combat_target, combat_system)
	else:
		wander(delta)
		
	update_sprite_facing()

func update_sprite_facing() -> void:
	if is_moving_left():
		animated_sprite.flip_h = true
	elif is_moving_right():
		animated_sprite.flip_h = false

func _ready() -> void:
	super._ready()

	animated_sprite_shader.pause()
	animated_sprite.frame_changed.connect(sync_shadow_frame)

	animated_sprite.set_frame_and_progress(0, 0.0)
	sync_shadow_frame()
	animated_sprite.play(&"default")


func sync_shadow_frame() -> void:
	animated_sprite_shader.animation = animated_sprite.animation
	animated_sprite_shader.frame = animated_sprite.frame

func update_combat_target(delta: float) -> void:
	if spatial_index == null:
		return

	target_update_timer -= delta

	if target_update_timer > 0.0:
		return

	target_update_timer = TARGET_UPDATE_INTERVAL
	combat_target = spatial_index.get_closest_enemy(global_position, DETECTION_RANGE) as CombatUnit


func wander(delta: float) -> void:
	var reached_target := move_toward_position(wander_target_position, TARGET_REACHED_DISTANCE, delta)

	if reached_target:
		choose_new_wander_target()


func move_toward_position(destination: Vector2, stop_distance: float, delta: float) -> bool:
	var distance := global_position.distance_to(destination)
	var desired_velocity := Vector2.ZERO

	if distance > stop_distance:
		var direction := get_navigation_direction(
			arena_grid,
			destination,
			stop_distance,
			COLLISION_RADIUS,
			delta
		)

		desired_velocity = direction * MOVE_SPEED

	velocity = velocity.move_toward(
		desired_velocity,
		ACCELERATION * delta
	)

	var motion := velocity * delta

	if arena_grid != null:
		var old_position := global_position

		var new_position := arena_grid.move_unit(
			global_position,
			motion,
			COLLISION_RADIUS,
			avoidance_side
		)

		var actual_motion := new_position - old_position

		global_position = new_position

		if delta > 0.0 and not actual_motion.is_zero_approx():
			velocity = actual_motion / delta
		elif actual_motion.is_zero_approx():
			velocity = Vector2.ZERO
	else:
		global_position += motion

	return distance <= stop_distance

func choose_new_wander_target() -> void:
	for attempt in range(MAX_WANDER_TARGET_ATTEMPTS):
		var angle := randf_range(0.0, TAU)
		var distance := randf_range(MIN_TARGET_DISTANCE, WANDER_RADIUS)
		var new_target := home_position + Vector2(cos(angle), sin(angle)) * distance

		new_target.x = clamp(new_target.x, ARENA_MIN.x, ARENA_MAX.x)
		new_target.y = clamp(new_target.y, ARENA_MIN.y, ARENA_MAX.y)

		if arena_grid == null or arena_grid.is_global_position_walkable(new_target, COLLISION_RADIUS):
			wander_target_position = new_target
			return

	wander_target_position = global_position
