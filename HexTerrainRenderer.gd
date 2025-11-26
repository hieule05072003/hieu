class_name HexTerrainRenderer
extends Node

## Automatically renders HexTilemap terrain data to a TileMapLayer
## Maps terrain types to visual tile atlas coordinates

## Reference to the HexTilemap data structure
var hex_tilemap: HexTilemap

## Reference to the TileMapLayer for visual rendering
var tile_map_layer: TileMapLayer

## TileSet source ID (usually 0)
const TILESET_SOURCE_ID: int = 0

## Mapping of terrain types to tile atlas coordinates (x, y) in Tileset1.png
## Tiles are arranged VERTICALLY in the 384x384 texture
## With 32x32 regions, tiles are at: (0,0), (0,2), (0,4), (0,6), (0,8), (0,10), (0,12), (0,14)
## 0: Gray Stone, 1: Blue Water, 2: Green Forest, 3: Orange Sand
## 4: Blue Ice, 5: Light Cyan, 6: Pink, 7: Brown Wood
var terrain_to_tile_map: Dictionary = {
	HexTile.TerrainType.EMPTY: Vector2i(0, 10),     # Light Cyan - empty/walkable
	HexTile.TerrainType.GRASS: Vector2i(0, 4),      # Green - grass
	HexTile.TerrainType.FLOWER: Vector2i(0, 12),    # Pink - flowers
	HexTile.TerrainType.HILL: Vector2i(0, 6),       # Orange - hills
	HexTile.TerrainType.MOUNTAIN: Vector2i(0, 0),   # Gray Stone - mountains
	HexTile.TerrainType.WATER: Vector2i(0, 2),      # Blue - water
	HexTile.TerrainType.FOREST: Vector2i(0, 4),     # Green - forest
	HexTile.TerrainType.SAND: Vector2i(0, 6),       # Orange - sand
	HexTile.TerrainType.ICE: Vector2i(0, 8),        # Blue Ice - ice
	HexTile.TerrainType.STONE: Vector2i(0, 0),      # Gray Stone - stone
}

func _init(p_hex_tilemap: HexTilemap = null, p_tile_map_layer: TileMapLayer = null) -> void:
	hex_tilemap = p_hex_tilemap
	tile_map_layer = p_tile_map_layer

## Initialize the renderer with references
func setup(p_hex_tilemap: HexTilemap, p_tile_map_layer: TileMapLayer) -> void:
	hex_tilemap = p_hex_tilemap
	tile_map_layer = p_tile_map_layer

	# Connect to tile changed signal for automatic updates
	if hex_tilemap and not hex_tilemap.tile_changed.is_connected(_on_tile_changed):
		hex_tilemap.tile_changed.connect(_on_tile_changed)

	print("✓ HexTerrainRenderer initialized and connected")

## Render the entire HexTilemap to the TileMapLayer
func render_tilemap() -> void:
	if not hex_tilemap or not tile_map_layer:
		push_error("HexTerrainRenderer: hex_tilemap or tile_map_layer not set!")
		return

	# Clear existing tiles
	tile_map_layer.clear()

	var tiles_rendered = 0

	# Render all tiles from the HexTilemap
	var terrain_counts = {}
	for tile in hex_tilemap.get_all_tiles():
		var coord = tile.coordinate
		var terrain = tile.terrain

		# Get the atlas coordinates for this terrain type
		var atlas_coords = terrain_to_tile_map.get(terrain, Vector2i(0, 10))

		# Set the cell on the TileMapLayer
		# Note: Using the coordinate directly as position
		tile_map_layer.set_cell(Vector2i(coord.q, coord.r), TILESET_SOURCE_ID, atlas_coords)
		tiles_rendered += 1

		# Count terrain types for debug
		var terrain_name = tile.get_terrain_name()
		if not terrain_counts.has(terrain_name):
			terrain_counts[terrain_name] = 0
		terrain_counts[terrain_name] += 1

	print("✓ Rendered %d tiles to TileMapLayer" % tiles_rendered)
	print("  Terrain distribution: %s" % terrain_counts)

## Update a single tile's visual representation
func update_tile_visual(coordinate: HexCoordinate, terrain: HexTile.TerrainType) -> void:
	if not tile_map_layer:
		return

	var atlas_coords = terrain_to_tile_map.get(terrain, Vector2i(5, 0))
	tile_map_layer.set_cell(Vector2i(coordinate.q, coordinate.r), TILESET_SOURCE_ID, atlas_coords)

## Clear a tile's visual representation
func clear_tile_visual(coordinate: HexCoordinate) -> void:
	if not tile_map_layer:
		return

	tile_map_layer.erase_cell(Vector2i(coordinate.q, coordinate.r))

## Signal handler for when a tile changes in the HexTilemap
func _on_tile_changed(coordinate: HexCoordinate, tile: HexTile) -> void:
	update_tile_visual(coordinate, tile.terrain)

## Customize terrain to tile mapping
func set_terrain_tile(terrain: HexTile.TerrainType, atlas_coords: Vector2i) -> void:
	terrain_to_tile_map[terrain] = atlas_coords

## Get the atlas coordinates for a terrain type
func get_terrain_tile(terrain: HexTile.TerrainType) -> Vector2i:
	return terrain_to_tile_map.get(terrain, Vector2i(5, 0))

## Render a specific area of the map
func render_area(top_left: HexCoordinate, bottom_right: HexCoordinate) -> void:
	if not hex_tilemap or not tile_map_layer:
		return

	for q in range(top_left.q, bottom_right.q + 1):
		for r in range(top_left.r, bottom_right.r + 1):
			var coord = HexCoordinate.new(q, r)
			var tile = hex_tilemap.get_tile_info(coord)

			if tile != null:
				update_tile_visual(coord, tile.terrain)

## Get rendering statistics
func get_render_stats() -> Dictionary:
	var visible_tiles = 0

	if tile_map_layer:
		for cell in tile_map_layer.get_used_cells():
			visible_tiles += 1

	return {
		"visible_tiles": visible_tiles,
		"terrain_mappings": terrain_to_tile_map.size()
	}
