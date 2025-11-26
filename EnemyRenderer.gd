## EnemyRenderer.gd
## Renders enemy sprites on the hex grid with health bars
## Similar to CharacterRenderer but includes health bar display
##
## Usage:
##   enemy_renderer.setup(hex_tilemap, tile_map_layer)
##   enemy_renderer.add_enemy(enemy)
##   enemy_renderer.update_health_bar(enemy)

class_name EnemyRenderer
extends Node2D

## Reference to the hex tilemap for coordinate conversion
var hex_tilemap: HexTilemap = null

## Reference to tile map layer for position calculations
var tile_map_layer: TileMapLayer = null

## Dictionary of enemy_id -> Sprite2D
var enemy_sprites: Dictionary = {}

## Dictionary of enemy_id -> ProgressBar (health bars)
var enemy_health_bars: Dictionary = {}

## Dictionary of enemy_id -> Node2D (container for sprite + health bar)
var enemy_containers: Dictionary = {}

## Dictionary of enemy_id -> Enemy
var enemies: Dictionary = {}

## Target size for enemy sprites (in pixels)
const TARGET_SIZE = 70.0  # Match character size

## Health bar settings
const HEALTH_BAR_WIDTH = 50.0
const HEALTH_BAR_HEIGHT = 6.0
const HEALTH_BAR_OFFSET_Y = -40.0  # Above the sprite

const DEBUG_MODE = true
const DEBUG_PREFIX = "[EnemyRenderer]"


## Setup the renderer with tilemap references
## @param p_hex_tilemap: Reference to HexTilemap
## @param p_tile_map_layer: Reference to TileMapLayer
func setup(p_hex_tilemap: HexTilemap, p_tile_map_layer: TileMapLayer) -> void:
	hex_tilemap = p_hex_tilemap
	tile_map_layer = p_tile_map_layer
	_debug_log("Enemy renderer setup complete")


## Add an enemy and create its visual representation
## @param enemy: The Enemy instance to render
func add_enemy(enemy: Enemy) -> void:
	if enemy == null:
		push_error("%s Cannot add null enemy" % DEBUG_PREFIX)
		return

	if enemies.has(enemy.id):
		push_warning("%s Enemy %s already rendered" % [DEBUG_PREFIX, enemy.id])
		return

	# Store enemy reference
	enemies[enemy.id] = enemy

	# Create container node
	var container = Node2D.new()
	container.name = "EnemyContainer_%s" % enemy.id
	container.z_index = 101  # Above characters (100) but below UI
	add_child(container)
	enemy_containers[enemy.id] = container

	# Create sprite
	var sprite = Sprite2D.new()
	sprite.name = "EnemySprite_%s" % enemy.id
	sprite.texture = load(enemy.sprite_path)

	if sprite.texture:
		var texture_size = sprite.texture.get_size()

		# Detect grid sprite sheet (like Torch_Red.png: 7×5 grid = 448×400)
		# Check if texture is large and roughly square (grid layout)
		if texture_size.x > 256 and texture_size.y > 256:
			# Assume 7×5 grid for Torch_Red.png
			var grid_cols = 7
			var grid_rows = 5
			var frame_width = texture_size.x / grid_cols   # 448/7 = 64
			var frame_height = texture_size.y / grid_rows  # 400/5 = 80

			# Extract FIRST FRAME ONLY (top-left)
			sprite.region_enabled = true
			sprite.region_rect = Rect2(0, 0, frame_width, frame_height)

			# Scale the individual frame to target size
			var scale_factor = TARGET_SIZE / frame_width  # 70/64 = 1.094
			sprite.scale = Vector2(scale_factor, scale_factor)

			# Debug logging
			_debug_log("Sprite sheet detected: %dx%d" % [texture_size.x, texture_size.y])
			_debug_log("Grid: %dx%d, Frame: %dx%d" % [grid_cols, grid_rows, frame_width, frame_height])
			_debug_log("Region: %s, Scale: %.3f" % [sprite.region_rect, scale_factor])
		else:
			# Single sprite - use original logic
			var max_dimension = max(texture_size.x, texture_size.y)
			var scale_factor = TARGET_SIZE / max_dimension
			sprite.scale = Vector2(scale_factor, scale_factor)

			_debug_log("Single sprite: %dx%d, Scale: %.3f" % [texture_size.x, texture_size.y, scale_factor])

	container.add_child(sprite)
	enemy_sprites[enemy.id] = sprite

	# Create health bar
	var health_bar = create_health_bar(enemy)
	container.add_child(health_bar)
	enemy_health_bars[enemy.id] = health_bar

	# Position the container
	update_enemy_position(enemy)

	_debug_log("Added enemy sprite: %s at (%d, %d)" % [enemy.id, enemy.position.q, enemy.position.r])


## Create a health bar for an enemy
## @param enemy: The enemy to create health bar for
## @returns: ProgressBar node
func create_health_bar(enemy: Enemy) -> ProgressBar:
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar_%s" % enemy.id
	health_bar.custom_minimum_size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	health_bar.position = Vector2(-HEALTH_BAR_WIDTH / 2, HEALTH_BAR_OFFSET_Y)
	health_bar.max_value = enemy.maxHP
	health_bar.value = enemy.currentHP
	health_bar.show_percentage = false

	# Style the health bar
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Dark gray background
	health_bar.add_theme_stylebox_override("background", style_bg)

	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(1.0, 0.2, 0.2, 1.0)  # Red foreground
	health_bar.add_theme_stylebox_override("fill", style_fg)

	return health_bar


## Update health bar for an enemy
## @param enemy: The enemy whose health bar to update
func update_health_bar(enemy: Enemy) -> void:
	if not enemy_health_bars.has(enemy.id):
		return

	var health_bar = enemy_health_bars[enemy.id]
	health_bar.value = enemy.currentHP

	# Change color based on HP percentage
	var hp_percent = enemy.get_hp_percentage()
	var style_fg = StyleBoxFlat.new()

	if hp_percent > 0.6:
		style_fg.bg_color = Color(1.0, 0.2, 0.2, 1.0)  # Red (healthy)
	elif hp_percent > 0.3:
		style_fg.bg_color = Color(1.0, 0.6, 0.0, 1.0)  # Orange (damaged)
	else:
		style_fg.bg_color = Color(0.8, 0.0, 0.0, 1.0)  # Dark red (critical)

	health_bar.add_theme_stylebox_override("fill", style_fg)


## Remove an enemy's visual representation
## @param enemy_id: ID of the enemy to remove
func remove_enemy(enemy_id: String) -> void:
	if not enemies.has(enemy_id):
		return

	# Remove container (which contains sprite and health bar)
	if enemy_containers.has(enemy_id):
		var container = enemy_containers[enemy_id]
		container.queue_free()
		enemy_containers.erase(enemy_id)

	# Clean up references
	enemy_sprites.erase(enemy_id)
	enemy_health_bars.erase(enemy_id)
	enemies.erase(enemy_id)

	_debug_log("Removed enemy sprite: %s" % enemy_id)


## Play death animation for an enemy
## @param enemy: The enemy that died
func play_death_animation(enemy: Enemy) -> void:
	if not enemy_sprites.has(enemy.id):
		return

	var sprite = enemy_sprites[enemy.id]

	# Fade out animation
	var tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): remove_enemy(enemy.id))

	_debug_log("Playing death animation for: %s" % enemy.id)


## Update the position of an enemy sprite
## @param enemy: The enemy to update
func update_enemy_position(enemy: Enemy) -> void:
	if not enemy_containers.has(enemy.id):
		return

	var world_position = tile_map_layer.map_to_local(Vector2i(enemy.position.q, enemy.position.r))
	var container = enemy_containers[enemy.id]
	container.global_position = world_position

	_debug_log("Updated enemy position: %s to (%d, %d)" % [enemy.id, enemy.position.q, enemy.position.r])


## Get enemy at a specific position (for click detection)
## @param position: World position to check
## @returns: Enemy at that position or null
func get_enemy_at_position(world_position: Vector2) -> Enemy:
	# Convert world position to hex coordinate
	var tile_pos = tile_map_layer.local_to_map(world_position)
	var coord = HexCoordinate.new(tile_pos.x, tile_pos.y)

	# Check if any enemy is at this coordinate
	for enemy in enemies.values():
		if enemy.current_coordinate.equals(coord):
			return enemy

	return null


## Clear all enemy sprites (for level transitions)
func clear_all() -> void:
	for enemy_id in enemies.keys():
		remove_enemy(enemy_id)
	_debug_log("Cleared all enemy sprites")


## Debug logging
func _debug_log(message: String) -> void:
	if DEBUG_MODE:
		print("%s %s" % [DEBUG_PREFIX, message])
