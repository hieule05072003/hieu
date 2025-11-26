class_name CoordinateDisplay
extends Node2D

## Displays coordinate numbers (q, r) on each hex tile
## Useful for debugging and tile reference
## Uses Node2D for world-space positioning (follows camera)

var hex_tilemap: HexTilemap
var tile_map_layer: TileMapLayer
var labels: Dictionary = {}  # Key: "q,r", Value: Label

## Single coordinate display (click mode)
var single_label: PanelContainer
var single_label_text: Label
var single_coord_visible: bool = false
var current_shown_coord: HexCoordinate = null

## Display settings
var font_size: int = 16  # Increased from 10 for better visibility
var label_color: Color = Color.WHITE
var label_outline_color: Color = Color.BLACK
var label_outline_size: int = 2  # Increased outline
var is_visible: bool = false

## Single label settings
var single_bg_color: Color = Color(0, 0, 0, 0.7)  # Semi-transparent black
var single_font_size: int = 18

func _init() -> void:
	# Node2D doesn't need layer setting
	# Z-index can be set if needed: z_index = 10
	z_index = 100  # Render above tiles

## Setup the coordinate display
func setup(p_hex_tilemap: HexTilemap, p_tile_map_layer: TileMapLayer) -> void:
	hex_tilemap = p_hex_tilemap
	tile_map_layer = p_tile_map_layer
	create_single_label()
	create_coordinate_labels()

## Create single label for click-to-show mode
func create_single_label() -> void:
	# Create panel container for background
	single_label = PanelContainer.new()

	# Style the panel with semi-transparent background
	var stylebox = StyleBoxFlat.new()
	stylebox.bg_color = single_bg_color
	stylebox.border_width_left = 2
	stylebox.border_width_right = 2
	stylebox.border_width_top = 2
	stylebox.border_width_bottom = 2
	stylebox.border_color = Color.WHITE
	stylebox.corner_radius_top_left = 4
	stylebox.corner_radius_top_right = 4
	stylebox.corner_radius_bottom_left = 4
	stylebox.corner_radius_bottom_right = 4

	single_label.add_theme_stylebox_override("panel", stylebox)

	# Create label inside panel
	single_label_text = Label.new()
	single_label_text.add_theme_font_size_override("font_size", single_font_size)
	single_label_text.add_theme_color_override("font_color", label_color)
	single_label_text.add_theme_color_override("font_outline_color", label_outline_color)
	single_label_text.add_theme_constant_override("outline_size", label_outline_size)
	single_label_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	single_label_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Add padding
	single_label_text.add_theme_constant_override("margin_left", 8)
	single_label_text.add_theme_constant_override("margin_right", 8)
	single_label_text.add_theme_constant_override("margin_top", 4)
	single_label_text.add_theme_constant_override("margin_bottom", 4)

	single_label.add_child(single_label_text)
	single_label.visible = false

	add_child(single_label)

	print("✓ Single coordinate label created")

## Create label for each tile coordinate
func create_coordinate_labels() -> void:
	if not hex_tilemap:
		return

	# Clear existing labels
	clear_labels()

	for tile in hex_tilemap.get_all_tiles():
		var coord = tile.coordinate
		var label = Label.new()

		# Set label text
		label.text = "%d,%d" % [coord.q, coord.r]

		# Configure label appearance
		label.add_theme_font_size_override("font_size", font_size)
		label.add_theme_color_override("font_color", label_color)
		label.add_theme_color_override("font_outline_color", label_outline_color)
		label.add_theme_constant_override("outline_size", label_outline_size)

		# Position label at tile center using Godot's map_to_local
		var tile_pixel_pos = get_tile_pixel_position(coord)

		# Center the label on the tile
		# Estimate label size based on text length and font size
		var approx_label_width = len(label.text) * font_size * 0.6  # 0.6 is average char width ratio
		var approx_label_height = font_size
		label.position = tile_pixel_pos - Vector2(approx_label_width / 2, approx_label_height / 2)

		# Set visibility
		label.visible = is_visible

		# Add to scene
		add_child(label)

		# Store reference
		var key = "%d,%d" % [coord.q, coord.r]
		labels[key] = label

	print("✓ Created %d coordinate labels" % labels.size())

## Toggle coordinate visibility
func toggle_visibility() -> void:
	is_visible = !is_visible

	for label in labels.values():
		label.visible = is_visible

	if is_visible:
		print("✓ Coordinate display: ON")
	else:
		print("✓ Coordinate display: OFF")

## Show coordinates
func show_coordinates() -> void:
	is_visible = true
	for label in labels.values():
		label.visible = true
	print("✓ Coordinate display: ON")

## Hide coordinates
func hide_coordinates() -> void:
	is_visible = false
	for label in labels.values():
		label.visible = false
	print("✓ Coordinate display: OFF")

## Update coordinate positions (call after camera zoom changes)
func update_positions() -> void:
	if not hex_tilemap:
		return

	for tile in hex_tilemap.get_all_tiles():
		var coord = tile.coordinate
		var key = "%d,%d" % [coord.q, coord.r]

		if labels.has(key):
			var label = labels[key]
			var tile_pixel_pos = get_tile_pixel_position(coord)

			# Center the label (same logic as create_coordinate_labels)
			var approx_label_width = len(label.text) * font_size * 0.6
			var approx_label_height = font_size
			label.position = tile_pixel_pos - Vector2(approx_label_width / 2, approx_label_height / 2)

## Clear all labels
func clear_labels() -> void:
	for label in labels.values():
		label.queue_free()
	labels.clear()

## Refresh labels (recreate all)
func refresh() -> void:
	create_coordinate_labels()

## Change font size
func set_font_size(size: int) -> void:
	font_size = size
	for label in labels.values():
		label.add_theme_font_size_override("font_size", font_size)

## Change label color
func set_label_color(color: Color) -> void:
	label_color = color
	for label in labels.values():
		label.add_theme_color_override("font_color", label_color)

## Get tile pixel position (helper function)
func get_tile_pixel_position(coord: HexCoordinate) -> Vector2:
	if not tile_map_layer:
		push_error("CoordinateDisplay: tile_map_layer not set!")
		return Vector2.ZERO

	# Use Godot's built-in coordinate transformation
	# This automatically handles isometric Diamond Down layout correctly
	return tile_map_layer.map_to_local(Vector2i(coord.q, coord.r))

## Show single coordinate at specific tile
func show_single_coordinate(coord: HexCoordinate) -> void:
	if not single_label or not hex_tilemap:
		return

	# Get tile at coordinate
	var tile = hex_tilemap.get_tile_info(coord)
	if not tile:
		return

	# Update label text
	single_label_text.text = "%d,%d" % [coord.q, coord.r]

	# Position above tile center
	var tile_pos = get_tile_pixel_position(coord)

	# Estimate popup width based on text and font size
	var approx_popup_width = len(single_label_text.text) * single_font_size * 0.6 + 16  # +16 for padding
	var popup_height = single_font_size + 8  # +8 for padding

	# Position above and centered on tile
	single_label.position = tile_pos - Vector2(approx_popup_width / 2, popup_height + 10)  # +10 offset above tile

	# Show label
	single_label.visible = true
	single_coord_visible = true
	current_shown_coord = coord

	print("✓ Showing coordinate at (%d, %d)" % [coord.q, coord.r])

## Hide single coordinate
func hide_single_coordinate() -> void:
	if single_label:
		single_label.visible = false
		single_coord_visible = false
		current_shown_coord = null
		print("✓ Coordinate hidden")

## Convert screen/mouse position to tile coordinate
func get_tile_at_position(screen_pos: Vector2, camera: Camera2D = null) -> HexCoordinate:
	if not tile_map_layer:
		return null

	# Convert screen position to world coordinates
	# If camera is provided, account for camera transform
	var world_pos = screen_pos
	if camera:
		# Get viewport
		var viewport = get_viewport()
		if viewport:
			# Convert screen to world coordinates considering camera
			world_pos = camera.get_global_mouse_position()

	# Convert world position to tile map local coordinates
	var tile_map_pos = tile_map_layer.to_local(world_pos)

	# Use TileMapLayer's built-in method to get tile coordinates
	var tile_coords = tile_map_layer.local_to_map(tile_map_pos)

	# Create HexCoordinate from tile coordinates
	var coord = HexCoordinate.new(tile_coords.x, tile_coords.y)

	# Validate coordinate is within bounds
	if hex_tilemap and hex_tilemap.is_valid_coordinate(coord):
		print("DEBUG: Screen pos: %s → World pos: %s → Tile pos: %s → Coord: (%d, %d)" % [screen_pos, world_pos, tile_map_pos, coord.q, coord.r])
		return coord

	print("DEBUG: Click outside valid tile area - Screen pos: %s → Tile coords: %s" % [screen_pos, tile_coords])
	return null

## Toggle between single coordinate and all coordinates
func toggle_mode() -> void:
	if is_visible:
		# Currently showing all, hide all
		hide_coordinates()
	elif single_coord_visible:
		# Currently showing single, hide it
		hide_single_coordinate()
	else:
		# Show all
		show_coordinates()
