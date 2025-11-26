class_name CharacterRenderer
extends Node2D

## Renders character sprites on the hex grid
## Uses individual Sprite2D nodes positioned at hex coordinates
## Designed for Part 2 turn-based movement system

## References to other systems
var hex_tilemap: HexTilemap
var tile_map_layer: TileMapLayer  # Reference to get correct tile positions

## Dictionary of character ID -> Sprite2D
var character_sprites: Dictionary = {}

## Dictionary of character ID -> Character data
var characters: Dictionary = {}

## Whether characters are visible
var characters_visible: bool = true

## === Part 2: Character Selection System ===

## ID of currently selected character (null if none selected)
var selected_character_id: String = ""

## Dictionary of character ID -> selection highlight sprite
var selection_highlights: Dictionary = {}

## Selection highlight color
var selection_color: Color = Color(1.0, 1.0, 0.0, 0.8)  # Yellow with some transparency

## === Part 3: Character Health Bar System ===

## Health bar settings
const HEALTH_BAR_WIDTH = 50.0
const HEALTH_BAR_HEIGHT = 6.0
const HEALTH_BAR_OFFSET_Y = -40.0  # Above the sprite

## Dictionary of character_id -> ProgressBar (health bars)
var character_health_bars: Dictionary = {}

func _ready() -> void:
	pass

## Initialize the renderer with hex tilemap reference
func setup(p_hex_tilemap: HexTilemap, p_tile_map_layer: TileMapLayer) -> void:
	hex_tilemap = p_hex_tilemap
	tile_map_layer = p_tile_map_layer

	# Connect to tilemap signals for automatic updates
	if hex_tilemap:
		hex_tilemap.tile_changed.connect(_on_tile_changed)

	print("✓ CharacterRenderer setup complete")

## Add a character to the map
func add_character(character: Character) -> void:
	if characters.has(character.id):
		push_warning("Character with ID '%s' already exists" % character.id)
		return

	# Store character data
	characters[character.id] = character

	# Create sprite for the character
	var sprite = Sprite2D.new()
	sprite.name = "Character_" + character.id
	sprite.texture = load(character.sprite_path)
	sprite.z_index = 100  # Above terrain and environmental assets
	sprite.centered = true  # Center sprite on tile

	# Check if texture loaded
	if not sprite.texture:
		push_error("  ✗ Failed to load texture: %s" % character.sprite_path)
		return

	# Get texture dimensions
	var texture_size = sprite.texture.get_size()
	print("  ✓ Texture loaded: %s (size: %s)" % [character.sprite_path, texture_size])

	# Smart sprite sheet handling
	# Check if this is a sprite sheet (horizontal strip or grid)
	if texture_size.x > texture_size.y * 1.5:
		# Horizontal sprite sheet (like Archer_Idle)
		var frame_count = 6  # Archer_Idle has 6 frames
		var frame_width = texture_size.x / frame_count
		var frame_height = texture_size.y

		# Configure region to show only first frame
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, frame_width, frame_height)
		print("  ✓ Horizontal sprite sheet detected - showing first frame: %dx%d" % [frame_width, frame_height])
	elif texture_size.x == texture_size.y and texture_size.x > 256:
		# Square texture that's large = likely a grid sprite sheet (like Pawn_Blue)
		# Assume 6x6 grid for 1152x1152 images
		var grid_size = 6  # 6x6 grid
		var frame_size = texture_size.x / grid_size

		# Configure region to show only first frame (top-left corner)
		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, frame_size, frame_size)
		print("  ✓ Grid sprite sheet detected (%dx%d grid) - showing first frame: %dx%d" % [grid_size, grid_size, frame_size, frame_size])
	else:
		print("  ✓ Single sprite detected (no region needed)")

	# Scale down to fit hex tile better (adjust as needed)
	# Hex tiles are typically 32x32, so scale sprite to fit nicely
	var target_size = 70  # Target size for character sprite
	var current_display_size = sprite.region_rect.size.x if sprite.region_enabled else texture_size.x
	if current_display_size > target_size:
		var scale_factor = target_size / current_display_size
		sprite.scale = Vector2(scale_factor, scale_factor)
		print("  ✓ Scaled to fit tile: %0.2fx" % scale_factor)

	# Position sprite at character's coordinate using TileMapLayer conversion
	var world_pos = _hex_to_pixel(character.current_coordinate)
	sprite.position = world_pos

	# DEBUG: Print position info
	print("  ✓ Character positioned at: %s (world), tile: %s" % [world_pos, character.current_coordinate])

	# Add sprite to scene tree
	add_child(sprite)
	character_sprites[character.id] = sprite

	# Part 2: Create selection highlight (initially hidden)
	var highlight = Sprite2D.new()
	highlight.name = "Highlight_" + character.id
	highlight.z_index = 99  # Just below character sprite
	highlight.centered = true
	highlight.position = world_pos
	highlight.visible = false
	highlight.modulate = selection_color

	# Create a simple circle texture for highlight (using a placeholder approach)
	# Note: In a real game, you'd load a highlight sprite texture
	# For now, we'll use the character's texture scaled up slightly
	highlight.texture = sprite.texture
	if sprite.region_enabled:
		highlight.region_enabled = true
		highlight.region_rect = sprite.region_rect
	highlight.scale = sprite.scale * 1.3  # 30% larger for highlight effect
	highlight.modulate = Color(selection_color.r, selection_color.g, selection_color.b, 0.5)

	add_child(highlight)
	selection_highlights[character.id] = highlight

	# Part 3: Create health bar (initially hidden)
	var health_bar = create_health_bar(character)
	health_bar.position = world_pos + Vector2(-HEALTH_BAR_WIDTH / 2, HEALTH_BAR_OFFSET_Y)
	add_child(health_bar)
	character_health_bars[character.id] = health_bar

	# Update tile owner field
	if hex_tilemap:
		hex_tilemap.set_tile_info(character.current_coordinate, -1, character)

	print("✓ Added character '%s' at %s" % [character.name, character.current_coordinate])

## Remove a character from the map
func remove_character(character_id: String) -> void:
	if not characters.has(character_id):
		push_warning("Character with ID '%s' not found" % character_id)
		return

	var character = characters[character_id]

	# Clear tile owner
	if hex_tilemap:
		hex_tilemap.set_tile_info(character.current_coordinate, -1, null)

	# Remove and free sprite
	if character_sprites.has(character_id):
		var sprite = character_sprites[character_id]
		sprite.queue_free()
		character_sprites.erase(character_id)

	# Part 2: Remove selection highlight
	if selection_highlights.has(character_id):
		var highlight = selection_highlights[character_id]
		highlight.queue_free()
		selection_highlights.erase(character_id)

	# Part 3: Remove health bar
	if character_health_bars.has(character_id):
		var health_bar = character_health_bars[character_id]
		health_bar.queue_free()
		character_health_bars.erase(character_id)

	# Deselect if this was the selected character
	if selected_character_id == character_id:
		selected_character_id = ""

	# Remove character data
	characters.erase(character_id)

	print("✓ Removed character '%s'" % character.name)

## Create a health bar for a character
## @param character: The character to create health bar for
## @returns: ProgressBar node
func create_health_bar(character: Character) -> ProgressBar:
	var health_bar = ProgressBar.new()
	health_bar.name = "HealthBar_%s" % character.id
	health_bar.custom_minimum_size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	# Position is set manually in add_character() and move_character()
	health_bar.max_value = character.maxHP
	health_bar.value = character.currentHP
	health_bar.show_percentage = false
	health_bar.visible = false  # Hidden by default - only show when selected

	# Style the health bar - dark background
	var style_bg = StyleBoxFlat.new()
	style_bg.bg_color = Color(0.2, 0.2, 0.2, 0.8)  # Dark gray background
	health_bar.add_theme_stylebox_override("background", style_bg)

	# Green foreground (friendly characters use green instead of red)
	var style_fg = StyleBoxFlat.new()
	style_fg.bg_color = Color(0.2, 1.0, 0.2, 1.0)  # Green for healthy characters
	health_bar.add_theme_stylebox_override("fill", style_fg)

	return health_bar

## Update health bar for a character
## @param character: The character whose health bar to update
func update_health_bar(character: Character) -> void:
	if not character_health_bars.has(character.id):
		return

	var health_bar = character_health_bars[character.id]
	health_bar.value = character.currentHP

	# Change color based on HP percentage (Green → Yellow → Red)
	var hp_percent = character.get_hp_percentage()
	var style_fg = StyleBoxFlat.new()

	if hp_percent > 0.6:
		style_fg.bg_color = Color(0.2, 1.0, 0.2, 1.0)  # Green (healthy)
	elif hp_percent > 0.3:
		style_fg.bg_color = Color(1.0, 1.0, 0.0, 1.0)  # Yellow (damaged)
	else:
		style_fg.bg_color = Color(1.0, 0.2, 0.2, 1.0)  # Red (critical)

	health_bar.add_theme_stylebox_override("fill", style_fg)

## Move a character to a new coordinate
func move_character(character_id: String, new_coordinate: HexCoordinate) -> bool:
	if not characters.has(character_id):
		push_warning("Character with ID '%s' not found" % character_id)
		return false

	var character = characters[character_id]
	var old_coordinate = character.current_coordinate

	# Check if target tile is valid and walkable
	var target_tile = hex_tilemap.get_tile_info(new_coordinate)
	if not target_tile:
		push_warning("Invalid coordinate: %s" % new_coordinate)
		return false

	if target_tile.is_occupied():
		push_warning("Tile %s is already occupied" % new_coordinate)
		return false

	if not target_tile.is_walkable():
		push_warning("Tile %s is not walkable (terrain: %s)" % [new_coordinate, target_tile.get_terrain_name()])
		return false

	# Clear old tile owner
	hex_tilemap.set_tile_info(old_coordinate, -1, null)

	# Update character position
	character.move_to(new_coordinate)

	# Set new tile owner
	hex_tilemap.set_tile_info(new_coordinate, -1, character)

	# Update sprite position
	if character_sprites.has(character_id):
		var sprite = character_sprites[character_id]
		var world_pos = _hex_to_pixel(new_coordinate)
		sprite.position = world_pos

		# Part 2: Also move highlight
		if selection_highlights.has(character_id):
			var highlight = selection_highlights[character_id]
			highlight.position = world_pos

		# Part 3: Also move health bar
		if character_health_bars.has(character_id):
			var health_bar = character_health_bars[character_id]
			health_bar.position = world_pos + Vector2(-HEALTH_BAR_WIDTH / 2, HEALTH_BAR_OFFSET_Y)

	print("✓ Moved character '%s' from %s to %s" % [character.name, old_coordinate, new_coordinate])
	return true

## Get character at a specific coordinate
func get_character_at(coordinate: HexCoordinate) -> Character:
	var tile = hex_tilemap.get_tile_info(coordinate)
	if tile and tile.owner is Character:
		return tile.owner
	return null

## Toggle character visibility
func toggle_visibility() -> void:
	characters_visible = !characters_visible
	visible = characters_visible
	print("✓ Characters visibility: %s" % ("ON" if characters_visible else "OFF"))

## Clear all characters
func clear_all_characters() -> void:
	for character_id in characters.keys():
		remove_character(character_id)
	print("✓ Cleared all characters")

## Convert hex coordinate to pixel position (world space)
func _hex_to_pixel(coordinate: HexCoordinate) -> Vector2:
	# Use TileMapLayer's map_to_local to get the correct world position
	# This automatically handles the hex layout and tile size
	if tile_map_layer:
		var tile_pos = Vector2i(coordinate.q, coordinate.r)
		return tile_map_layer.map_to_local(tile_pos)
	else:
		# Fallback if tile_map_layer is not set
		push_warning("TileMapLayer not set in CharacterRenderer")
		return Vector2(coordinate.q * 32, coordinate.r * 32)

## Signal handler: When a tile changes
func _on_tile_changed(coordinate: HexCoordinate, tile: HexTile) -> void:
	# Update character sprite if the owner changed
	# This ensures characters stay in sync with tile data
	pass

## Get all characters
func get_all_characters() -> Array:
	return characters.values()

## Get character count
func get_character_count() -> int:
	return characters.size()

## === Part 2: Character Selection Methods ===

## Select a character by ID
## @param character_id: ID of character to select
## @returns: true if selection successful
func select_character(character_id: String) -> bool:
	if not characters.has(character_id):
		push_warning("Cannot select character '%s' - not found" % character_id)
		return false

	# Deselect previous character
	if selected_character_id != "":
		deselect_character()

	# Select new character
	selected_character_id = character_id

	# Show highlight
	if selection_highlights.has(character_id):
		selection_highlights[character_id].visible = true

	# Part 3: Show health bar when selected
	if character_health_bars.has(character_id):
		character_health_bars[character_id].visible = true

	var character = characters[character_id]
	print("✓ Selected character: %s" % character.name)
	return true

## Deselect the currently selected character
func deselect_character() -> void:
	if selected_character_id == "":
		return

	# Hide highlight
	if selection_highlights.has(selected_character_id):
		selection_highlights[selected_character_id].visible = false

	# Part 3: Hide health bar when deselected
	if character_health_bars.has(selected_character_id):
		character_health_bars[selected_character_id].visible = false

	print("✓ Deselected character")
	selected_character_id = ""

## Get the currently selected character
## @returns: Character object or null if none selected
func get_selected_character() -> Character:
	if selected_character_id == "" or not characters.has(selected_character_id):
		return null
	return characters[selected_character_id]

## Check if a character is currently selected
## @returns: true if a character is selected
func has_selected_character() -> bool:
	return selected_character_id != "" and characters.has(selected_character_id)

## Move the selected character to a new coordinate
## @param target_coordinate: Destination coordinate
## @returns: true if move successful
func move_selected_character_to(target_coordinate: HexCoordinate) -> bool:
	if not has_selected_character():
		push_warning("No character selected to move")
		return false

	return move_character(selected_character_id, target_coordinate)

## Check if a world position (mouse click) is on a character sprite
## @param world_pos: Position in world space (e.g., mouse position)
## @returns: Character ID if clicked, empty string otherwise
func get_character_at_position(world_pos: Vector2) -> String:
	# Check each character sprite
	for character_id in character_sprites.keys():
		var sprite = character_sprites[character_id]

		# Get sprite's bounds
		var sprite_pos = sprite.global_position
		var texture_size = Vector2.ZERO

		if sprite.region_enabled:
			texture_size = sprite.region_rect.size * sprite.scale
		elif sprite.texture:
			texture_size = sprite.texture.get_size() * sprite.scale

		# Create bounding rect (centered sprite)
		var half_size = texture_size / 2.0
		var rect = Rect2(sprite_pos - half_size, texture_size)

		# Check if world_pos is inside rect
		if rect.has_point(world_pos):
			return character_id

	return ""

## Select character at a world position (for mouse click handling)
## @param world_pos: Position in world space
## @returns: true if a character was selected
func select_character_at_position(world_pos: Vector2) -> bool:
	var character_id = get_character_at_position(world_pos)
	if character_id != "":
		return select_character(character_id)
	return false
