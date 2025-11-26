class_name EnvironmentalAssetRenderer
extends Node

## Renders environmental assets (trees, rocks, water, etc.) on hex tiles
## based on terrain type. Uses EnvironmentalTileMapLayer with Elements.png.

## References to other systems
var hex_tilemap: HexTilemap
var env_tile_map_layer: TileMapLayer

## Mapping of terrain types to tile atlas coordinates
## Format: Vector2i(column, row) in the Elements.png atlas
## Elements.png is arranged as an 8x10 grid of 16x16 sprites
var TERRAIN_TO_ATLAS = {
	HexTile.TerrainType.FOREST: [
		Vector2i(0, 2),  # Tree 1
		Vector2i(1, 2),  # Tree 2
	],
	HexTile.TerrainType.MOUNTAIN: [
		Vector2i(2, 2),  # Rock 1
		Vector2i(3, 2),  # Rock 2
	],
	HexTile.TerrainType.HILL: [
		Vector2i(2, 2),  # Rock 1
	],
	HexTile.TerrainType.WATER: [
		Vector2i(0, 4),  # Water puddle 1
		Vector2i(3, 3),  # Water puddle 2
	],
	HexTile.TerrainType.STONE: [
		Vector2i(4, 2),  # Stone formation
	],
}

## Whether environmental assets are visible
var visible_assets: bool = true

func _ready() -> void:
	pass

## Initialize the renderer with references to other systems
func setup(p_hex_tilemap: HexTilemap, p_env_tile_map_layer: TileMapLayer) -> void:
	hex_tilemap = p_hex_tilemap
	env_tile_map_layer = p_env_tile_map_layer

	# Connect to tilemap signals for automatic updates
	if hex_tilemap:
		hex_tilemap.tile_changed.connect(_on_tile_changed)
		hex_tilemap.map_initialized.connect(_on_map_initialized)

	print("✓ EnvironmentalAssetRenderer setup complete (TileMapLayer mode)")

## Render environmental assets for all tiles
func render_all_assets() -> void:
	if not hex_tilemap or not env_tile_map_layer:
		return

	# Clear existing tiles
	clear_all_assets()

	# Iterate through all tiles and place appropriate assets
	var tiles = hex_tilemap.get_all_tiles()
	var count = 0

	for tile in tiles:
		if _should_have_asset(tile.terrain):
			_place_asset_for_tile(tile)
			count += 1

	print("✓ Rendered %d environmental assets" % count)

## Check if a terrain type should have an environmental asset
func _should_have_asset(terrain: HexTile.TerrainType) -> bool:
	return TERRAIN_TO_ATLAS.has(terrain)

## Place an environmental tile for a specific tile
func _place_asset_for_tile(tile: HexTile) -> void:
	if not tile or not tile.coordinate:
		return

	# Get appropriate atlas coordinates for this terrain
	var atlas_coords = _get_atlas_coords_for_terrain(tile.terrain)
	if atlas_coords == Vector2i(-1, -1):
		return

	# Place tile on environmental layer using TileMapLayer
	var tile_pos = Vector2i(tile.coordinate.q, tile.coordinate.r)
	env_tile_map_layer.set_cell(tile_pos, 0, atlas_coords)

## Get atlas coordinates for a given terrain type (with optional variety)
func _get_atlas_coords_for_terrain(terrain: HexTile.TerrainType) -> Vector2i:
	if not TERRAIN_TO_ATLAS.has(terrain):
		return Vector2i(-1, -1)

	var atlas_options = TERRAIN_TO_ATLAS[terrain]
	if atlas_options.is_empty():
		return Vector2i(-1, -1)

	# For variety, randomly pick one if multiple options exist
	if atlas_options.size() > 1:
		return atlas_options[randi() % atlas_options.size()]
	else:
		return atlas_options[0]

## Clear all spawned environmental assets
func clear_all_assets() -> void:
	if not env_tile_map_layer:
		return

	env_tile_map_layer.clear()
	print("✓ Cleared all environmental assets")

## Toggle visibility of environmental assets
func toggle_visibility() -> void:
	visible_assets = !visible_assets
	if env_tile_map_layer:
		env_tile_map_layer.visible = visible_assets
	print("✓ Environmental assets: %s" % ("ON" if visible_assets else "OFF"))

## Show environmental assets
func show_assets() -> void:
	visible_assets = true
	if env_tile_map_layer:
		env_tile_map_layer.visible = true

## Hide environmental assets
func hide_assets() -> void:
	visible_assets = false
	if env_tile_map_layer:
		env_tile_map_layer.visible = false

## Signal handler: When a tile changes, update its asset
func _on_tile_changed(coordinate: HexCoordinate, tile: HexTile) -> void:
	if not tile or not env_tile_map_layer:
		return

	var tile_pos = Vector2i(coordinate.q, coordinate.r)

	# Remove existing asset
	env_tile_map_layer.erase_cell(tile_pos)

	# Add new asset if terrain type requires one
	if _should_have_asset(tile.terrain):
		var atlas_coords = _get_atlas_coords_for_terrain(tile.terrain)
		if atlas_coords != Vector2i(-1, -1):
			env_tile_map_layer.set_cell(tile_pos, 0, atlas_coords)

## Signal handler: When map is initialized, render all assets
func _on_map_initialized(width: int, height: int) -> void:
	# Wait one frame for terrain to be rendered first
	await get_tree().process_frame
	render_all_assets()

## Update asset for a specific tile coordinate
func update_tile_asset(coordinate: HexCoordinate) -> void:
	var tile = hex_tilemap.get_tile_info(coordinate)
	if tile:
		_on_tile_changed(coordinate, tile)

## Remove asset at specific coordinate
func remove_tile_asset(coordinate: HexCoordinate) -> void:
	if not env_tile_map_layer:
		return

	var tile_pos = Vector2i(coordinate.q, coordinate.r)
	env_tile_map_layer.erase_cell(tile_pos)

## Get count of currently placed assets
func get_asset_count() -> int:
	if not env_tile_map_layer:
		return 0

	var count = 0
	var tiles = hex_tilemap.get_all_tiles()
	for tile in tiles:
		var tile_pos = Vector2i(tile.coordinate.q, tile.coordinate.r)
		if env_tile_map_layer.get_cell_source_id(tile_pos) != -1:
			count += 1

	return count

## Set custom atlas mapping for a terrain type
func set_terrain_atlas(terrain: HexTile.TerrainType, atlas_coords_array: Array) -> void:
	TERRAIN_TO_ATLAS[terrain] = atlas_coords_array
	print("✓ Updated terrain %d atlas mapping" % terrain)
