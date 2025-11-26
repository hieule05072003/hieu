class_name HexMapLoader
extends Node

## Save and load HexTilemap data to/from JSON files
## Supports terrain data, owner data, and map metadata

## Save a HexTilemap to a JSON file
## @param tilemap: The HexTilemap to save
## @param file_path: Path to save the file (e.g., "res://maps/my_map.json")
## @return: true if successful, false otherwise
func save_map_to_file(tilemap: HexTilemap, file_path: String) -> bool:
	print("Saving map to: %s" % file_path)

	var map_data = {
		"version": "1.0",
		"metadata": {
			"width": tilemap.width,
			"height": tilemap.height,
			"tile_count": tilemap.tiles.size(),
			"created_at": Time.get_datetime_string_from_system()
		},
		"tiles": []
	}

	# Serialize all tiles
	for tile in tilemap.get_all_tiles():
		var tile_data = {
			"q": tile.coordinate.q,
			"r": tile.coordinate.r,
			"terrain": tile.terrain,
			"terrain_name": tile.get_terrain_name(),
		}

		# Include owner if present
		if tile.owner != null:
			tile_data["owner"] = var_to_str(tile.owner)

		map_data["tiles"].append(tile_data)

	# Convert to JSON string
	var json_string = JSON.stringify(map_data, "\t")

	# Save to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if file == null:
		push_error("Failed to open file for writing: %s" % file_path)
		return false

	file.store_string(json_string)
	file.close()

	print("✓ Map saved successfully (%d tiles)" % map_data["tiles"].size())
	return true

## Load a HexTilemap from a JSON file
## @param tilemap: The HexTilemap to load data into
## @param file_path: Path to the file to load
## @return: true if successful, false otherwise
func load_map_from_file(tilemap: HexTilemap, file_path: String) -> bool:
	print("Loading map from: %s" % file_path)

	# Check if file exists
	if not FileAccess.file_exists(file_path):
		push_error("File does not exist: %s" % file_path)
		return false

	# Read file
	var file = FileAccess.open(file_path, FileAccess.READ)

	if file == null:
		push_error("Failed to open file for reading: %s" % file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	# Parse JSON
	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse JSON: %s" % json.get_error_message())
		return false

	var map_data = json.data

	# Validate data structure
	if not map_data.has("metadata") or not map_data.has("tiles"):
		push_error("Invalid map file format")
		return false

	var metadata = map_data["metadata"]

	# Initialize the tilemap with the correct dimensions
	print("  Map dimensions: %dx%d" % [metadata["width"], metadata["height"]])
	tilemap.initialize_map(metadata["width"], metadata["height"])

	# Load tiles
	var tiles_loaded = 0

	for tile_data in map_data["tiles"]:
		var coord = HexCoordinate.new(tile_data["q"], tile_data["r"])
		var terrain = tile_data["terrain"]

		# Parse owner if present
		var owner = null
		if tile_data.has("owner"):
			owner = str_to_var(tile_data["owner"])

		# Set tile data
		tilemap.set_tile_info(coord, terrain, owner)
		tiles_loaded += 1

	print("✓ Map loaded successfully (%d tiles)" % tiles_loaded)
	return true

## Export map to a simple CSV format (for spreadsheet editing)
## @param tilemap: The HexTilemap to export
## @param file_path: Path to save the CSV file
## @return: true if successful, false otherwise
func export_map_to_csv(tilemap: HexTilemap, file_path: String) -> bool:
	print("Exporting map to CSV: %s" % file_path)

	var csv_lines: Array[String] = []

	# Header
	csv_lines.append("q,r,terrain,terrain_name")

	# Export all tiles
	for tile in tilemap.get_all_tiles():
		var line = "%d,%d,%d,%s" % [
			tile.coordinate.q,
			tile.coordinate.r,
			tile.terrain,
			tile.get_terrain_name()
		]
		csv_lines.append(line)

	# Write to file
	var file = FileAccess.open(file_path, FileAccess.WRITE)

	if file == null:
		push_error("Failed to open file for writing: %s" % file_path)
		return false

	for line in csv_lines:
		file.store_line(line)

	file.close()

	print("✓ CSV export complete (%d tiles)" % (csv_lines.size() - 1))
	return true

## Import map from a simple CSV format
## @param tilemap: The HexTilemap to import into
## @param file_path: Path to the CSV file
## @return: true if successful, false otherwise
func import_map_from_csv(tilemap: HexTilemap, file_path: String) -> bool:
	print("Importing map from CSV: %s" % file_path)

	if not FileAccess.file_exists(file_path):
		push_error("File does not exist: %s" % file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)

	if file == null:
		push_error("Failed to open file for reading: %s" % file_path)
		return false

	var tiles_imported = 0
	var line_num = 0

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		line_num += 1

		# Skip header and empty lines
		if line_num == 1 or line.is_empty():
			continue

		var parts = line.split(",")

		if parts.size() < 3:
			continue

		var q = int(parts[0])
		var r = int(parts[1])
		var terrain = int(parts[2])

		var coord = HexCoordinate.new(q, r)
		tilemap.set_tile_info(coord, terrain)
		tiles_imported += 1

	file.close()

	print("✓ CSV import complete (%d tiles)" % tiles_imported)
	return true

## Get map statistics as a dictionary
func get_map_stats(tilemap: HexTilemap) -> Dictionary:
	var terrain_counts = {}

	for tile in tilemap.get_all_tiles():
		var terrain_name = tile.get_terrain_name()
		if not terrain_counts.has(terrain_name):
			terrain_counts[terrain_name] = 0
		terrain_counts[terrain_name] += 1

	return {
		"dimensions": "%dx%d" % [tilemap.width, tilemap.height],
		"total_tiles": tilemap.tiles.size(),
		"occupied_tiles": tilemap.get_occupied_tiles().size(),
		"terrain_distribution": terrain_counts
	}

## Print map statistics to console
func print_map_stats(tilemap: HexTilemap) -> void:
	var stats = get_map_stats(tilemap)

	print("\n=== Map Statistics ===")
	print("Dimensions: %s" % stats["dimensions"])
	print("Total tiles: %d" % stats["total_tiles"])
	print("Occupied tiles: %d" % stats["occupied_tiles"])
	print("\nTerrain Distribution:")

	for terrain_name in stats["terrain_distribution"]:
		var count = stats["terrain_distribution"][terrain_name]
		var percentage = (float(count) / stats["total_tiles"]) * 100.0
		print("  %s: %d (%.1f%%)" % [terrain_name, count, percentage])

	print("======================\n")
