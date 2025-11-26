class_name HexTilemap
extends Node

## Main grid manager for the hex-based tilemap system
## Implements the 3 core functions from design document:
## 1. Initialize Map: Create and set up the grid
## 2. Get Tile Information: Retrieve data from a specific tile
## 3. Set Tile Information: Update tile data
##
## Map supports up to 20x20 hexagonal tiles

## Dictionary storing all tiles, keyed by coordinate hash
var tiles: Dictionary = {}

## Grid dimensions
var width: int = 0
var height: int = 0

## Maximum grid size (from design document)
const MAX_WIDTH: int = 20
const MAX_HEIGHT: int = 20

## Signals for tile changes
signal tile_changed(coordinate: HexCoordinate, tile: HexTile)
signal map_initialized(width: int, height: int)

## Optional renderer for automatic visual updates
var renderer: HexTerrainRenderer = null

## Attach a renderer for automatic visual updates
func attach_renderer(p_renderer: HexTerrainRenderer) -> void:
	renderer = p_renderer
	print("✓ HexTilemap: Renderer attached")

## CORE FUNCTION 1: Initialize Map
## Creates and sets up the grid with specified dimensions
## @param p_width: Width of the map (max 20)
## @param p_height: Height of the map (max 20)
## @param default_terrain: Default terrain type for all tiles
func initialize_map(p_width: int, p_height: int, default_terrain: HexTile.TerrainType = HexTile.TerrainType.EMPTY) -> void:
	# Clamp dimensions to maximum size
	width = clampi(p_width, 1, MAX_WIDTH)
	height = clampi(p_height, 1, MAX_HEIGHT)

	# Clear existing tiles
	tiles.clear()

	# Create tiles for the grid
	# Using axial coordinates with offset layout
	for q in range(width):
		for r in range(height):
			var coord = HexCoordinate.new(q, r)
			var tile = HexTile.new(coord, default_terrain, null)
			var key = _coordinate_to_key(coord)
			tiles[key] = tile

	print("HexTilemap initialized: %d x %d grid with %d tiles" % [width, height, tiles.size()])
	map_initialized.emit(width, height)

## CORE FUNCTION 2: Get Tile Information
## Retrieves data from a specific tile
## @param coordinate: The hex coordinate to query
## @return: HexTile object or null if coordinate is invalid
func get_tile_info(coordinate: HexCoordinate) -> HexTile:
	var key = _coordinate_to_key(coordinate)
	return tiles.get(key, null)

## Alternative getter using q, r coordinates
func get_tile_at(q: int, r: int) -> HexTile:
	var coord = HexCoordinate.new(q, r)
	return get_tile_info(coord)

## CORE FUNCTION 3: Set Tile Information
## Updates tile data at a specific coordinate
## @param coordinate: The hex coordinate to update
## @param terrain: New terrain type (optional, use -1 to keep current)
## @param owner: New owner (optional, use null to clear owner)
## @return: true if tile was updated successfully, false otherwise
func set_tile_info(coordinate: HexCoordinate, terrain: HexTile.TerrainType = -1, owner: Variant = null) -> bool:
	var tile = get_tile_info(coordinate)

	if tile == null:
		push_warning("Attempted to set tile info for invalid coordinate: %s" % coordinate)
		return false

	# Update terrain if specified
	if terrain != -1:
		tile.terrain = terrain

	# Update owner (null clears the owner)
	tile.owner = owner

	tile_changed.emit(coordinate, tile)
	return true

## Alternative setter using q, r coordinates
func set_tile_at(q: int, r: int, terrain: HexTile.TerrainType = -1, owner: Variant = null) -> bool:
	var coord = HexCoordinate.new(q, r)
	return set_tile_info(coord, terrain, owner)

## Check if coordinate is within grid bounds
func is_valid_coordinate(coordinate: HexCoordinate) -> bool:
	return coordinate.q >= 0 and coordinate.q < width and coordinate.r >= 0 and coordinate.r < height

## Get all tiles in the grid
func get_all_tiles() -> Array[HexTile]:
	var result: Array[HexTile] = []
	for tile in tiles.values():
		result.append(tile)
	return result

## Get all occupied tiles
func get_occupied_tiles() -> Array[HexTile]:
	var result: Array[HexTile] = []
	for tile in tiles.values():
		if tile.is_occupied():
			result.append(tile)
	return result

## Get tiles by terrain type
func get_tiles_by_terrain(terrain_type: HexTile.TerrainType) -> Array[HexTile]:
	var result: Array[HexTile] = []
	for tile in tiles.values():
		if tile.terrain == terrain_type:
			result.append(tile)
	return result

## Clear all owners from the grid
func clear_all_owners() -> void:
	for tile in tiles.values():
		tile.clear_owner()

## Convert coordinate to dictionary key
func _coordinate_to_key(coordinate: HexCoordinate) -> String:
	return "%d,%d" % [coordinate.q, coordinate.r]

## Get grid statistics for debugging
func get_grid_stats() -> Dictionary:
	return {
		"width": width,
		"height": height,
		"total_tiles": tiles.size(),
		"occupied_tiles": get_occupied_tiles().size()
	}

## Print grid information
func print_grid_info() -> void:
	var stats = get_grid_stats()
	print("=== HexTilemap Info ===")
	print("Dimensions: %dx%d" % [stats.width, stats.height])
	print("Total tiles: %d" % stats.total_tiles)
	print("Occupied tiles: %d" % stats.occupied_tiles)
	print("======================")
