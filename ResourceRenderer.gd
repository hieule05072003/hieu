## ResourceRenderer.gd
## Renders resource sprites on the hex grid
## Displays trees, sheep, rocks, and gold deposits with appropriate sprites
## Automatically updates when resources are placed, harvested, or depleted
##
## Usage:
##   resource_renderer.setup(hex_tilemap, tile_map_layer, resource_manager)
##   # Resources will automatically appear when placed via ResourceManager

extends Node2D
class_name ResourceRenderer

## References to other systems
var hex_tilemap: HexTilemap
var tile_map_layer: TileMapLayer
var resource_manager: ResourceManager

## Dictionary of coordinate -> Sprite2D
var resource_sprites: Dictionary = {}

## Resource type to sprite path mapping
const RESOURCE_SPRITES = {
	ResourceStatus.ResourceType.TREE: "res://Resource/Tree.png",
	ResourceStatus.ResourceType.SHEEP: "res://Resource/HappySheep_Bouncing.png",
	ResourceStatus.ResourceType.ROCK: "res://Resource/GoldMine_Inactive.png",
	ResourceStatus.ResourceType.GOLD_DEPOSIT: "res://Resource/GoldMine_Active.png"
}

## Whether resources are visible
var resources_visible: bool = true

## === Phase 3: Resource Highlighting System ===

## Dictionary of coordinate -> highlight Sprite2D
var resource_highlights: Dictionary = {}

## Highlight colors
var adjacent_highlight_color: Color = Color(0.0, 1.0, 0.5, 0.6)  # Green-cyan for harvestable
var assigned_highlight_color: Color = Color(1.0, 1.0, 0.0, 0.7)  # Yellow for assigned

func _ready() -> void:
	pass

## Initialize the renderer with references to other systems
## @param p_hex_tilemap: HexTilemap reference
## @param p_tile_map_layer: TileMapLayer for positioning
## @param p_resource_manager: ResourceManager to connect signals
func setup(p_hex_tilemap: HexTilemap, p_tile_map_layer: TileMapLayer, p_resource_manager: ResourceManager) -> void:
	hex_tilemap = p_hex_tilemap
	tile_map_layer = p_tile_map_layer
	resource_manager = p_resource_manager

	# Connect to ResourceManager signals
	if resource_manager:
		resource_manager.resource_placed.connect(_on_resource_placed)
		resource_manager.resource_depleted.connect(_on_resource_depleted)

	print("✓ ResourceRenderer setup complete")

## Render all existing resources on the map
func render_all_resources() -> void:
	if not resource_manager:
		push_warning("ResourceManager not set, cannot render resources")
		return

	var resources = resource_manager.get_all_resources()
	for resource in resources:
		render_resource(resource)

	print("✓ Rendered %d resources" % resources.size())

## Render a single resource sprite
## @param resource: ResourceStatus to render
func render_resource(resource: ResourceStatus) -> void:
	if resource == null:
		push_error("Cannot render null resource")
		return

	# Check if already rendered
	if resource_sprites.has(resource.coordinate):
		push_warning("Resource at %s already rendered" % resource.coordinate)
		return

	# Get sprite path for this resource type
	var sprite_path = RESOURCE_SPRITES.get(resource.resource_type, "")
	if sprite_path == "":
		push_warning("No sprite defined for resource type: %d" % resource.resource_type)
		return

	# Create sprite
	var sprite = Sprite2D.new()
	sprite.name = "Resource_%s_%s" % [resource.get_resource_name(), resource.coordinate]
	sprite.texture = load(sprite_path)
	sprite.z_index = 50  # Above terrain, below characters (characters are 100)
	sprite.centered = true

	# Check if texture loaded
	if not sprite.texture:
		push_error("Failed to load texture: %s" % sprite_path)
		return

	# Get texture size
	var texture_size = sprite.texture.get_size()

	# Debug: Print texture dimensions for each resource type
	print("  [ResourceRenderer] %s texture: %.0fx%.0f (ratio: %.2f)" % [
		resource.get_resource_name(),
		texture_size.x,
		texture_size.y,
		texture_size.x / texture_size.y
	])

	# Resource-specific sprite sheet handling
	if resource.resource_type == ResourceStatus.ResourceType.TREE:
		# Tree sprite is 768x576 - assume 4x3 grid (12 frames)
		# Show only first frame (top-left: 192x192)
		var grid_cols = 4
		var grid_rows = 3
		var frame_width = texture_size.x / grid_cols
		var frame_height = texture_size.y / grid_rows

		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, frame_width, frame_height)
		texture_size = Vector2(frame_width, frame_height)
		print("  ✓ Tree sprite sheet detected (4x3 grid) - showing first frame: %dx%d" % [frame_width, frame_height])
	# Handle other horizontal sprite sheets (like HappySheep_Bouncing)
	elif texture_size.x > texture_size.y * 1.5:
		# Likely a sprite sheet - show first frame
		var frame_count = 6
		var frame_width = texture_size.x / frame_count
		var frame_height = texture_size.y

		sprite.region_enabled = true
		sprite.region_rect = Rect2(0, 0, frame_width, frame_height)
		texture_size = Vector2(frame_width, frame_height)
		print("  ✓ Horizontal sprite sheet detected (%d frames) - showing first frame: %dx%d" % [frame_count, frame_width, frame_height])

	# Scale to fit hex tile (target ~40-50 pixels)
	var target_size = 45
	if texture_size.x > target_size or texture_size.y > target_size:
		var scale_factor = target_size / max(texture_size.x, texture_size.y)
		sprite.scale = Vector2(scale_factor, scale_factor)

	# Position sprite at resource coordinate
	var world_pos = _hex_to_pixel(resource.coordinate)
	sprite.position = world_pos

	# Add to scene tree
	add_child(sprite)
	resource_sprites[resource.coordinate] = sprite

	print("  ✓ Rendered %s at %s" % [resource.get_resource_name(), resource.coordinate])

## Remove resource sprite from display
## @param coordinate: Position of resource to remove
func remove_resource_sprite(coordinate: HexCoordinate) -> void:
	if not resource_sprites.has(coordinate):
		return

	var sprite = resource_sprites[coordinate]
	sprite.queue_free()
	resource_sprites.erase(coordinate)

	print("  ✓ Removed resource sprite at %s" % coordinate)

## Toggle resource visibility
func toggle_visibility() -> void:
	resources_visible = !resources_visible
	visible = resources_visible
	print("✓ Resource visibility: %s" % ("ON" if resources_visible else "OFF"))

## Clear all resource sprites
func clear_all_sprites() -> void:
	for sprite in resource_sprites.values():
		sprite.queue_free()
	resource_sprites.clear()
	print("✓ Cleared all resource sprites")

## Convert hex coordinate to pixel position (world space)
func _hex_to_pixel(coordinate: HexCoordinate) -> Vector2:
	if tile_map_layer:
		var tile_pos = Vector2i(coordinate.q, coordinate.r)
		return tile_map_layer.map_to_local(tile_pos)
	else:
		push_warning("TileMapLayer not set in ResourceRenderer")
		return Vector2(coordinate.q * 32, coordinate.r * 32)

## Signal handler: When a resource is placed
func _on_resource_placed(coordinate: HexCoordinate, resource: ResourceStatus) -> void:
	render_resource(resource)

## Signal handler: When a resource is depleted
func _on_resource_depleted(coordinate: HexCoordinate, resource: ResourceStatus) -> void:
	remove_resource_sprite(coordinate)

## Get resource count
func get_resource_sprite_count() -> int:
	return resource_sprites.size()

## === Phase 3: Resource Highlighting Methods ===

## Create a highlight sprite for a resource
## @param coordinate: Resource coordinate to highlight
## @param color: Highlight color
func create_highlight_for_resource(coordinate: HexCoordinate, color: Color) -> void:
	# Don't create if already exists
	if resource_highlights.has(coordinate):
		# Update color instead
		var highlight = resource_highlights[coordinate]
		highlight.modulate = color
		return

	# Get the resource sprite to base highlight on
	if not resource_sprites.has(coordinate):
		return

	var resource_sprite = resource_sprites[coordinate]

	# Create highlight sprite
	var highlight = Sprite2D.new()
	highlight.name = "ResourceHighlight_%s" % coordinate
	highlight.z_index = 49  # Just below resource sprite (50)
	highlight.centered = true
	highlight.position = resource_sprite.position
	highlight.modulate = color

	# Use same texture as resource
	highlight.texture = resource_sprite.texture
	if resource_sprite.region_enabled:
		highlight.region_enabled = true
		highlight.region_rect = resource_sprite.region_rect

	# Make highlight slightly larger (30% bigger)
	highlight.scale = resource_sprite.scale * 1.3

	add_child(highlight)
	resource_highlights[coordinate] = highlight

## Show highlights for resources adjacent to character
## @param character: Character whose adjacent resources to highlight
func show_adjacent_highlights(character: Character) -> void:
	if not character:
		return

	# Hide any existing highlights first
	hide_all_highlights()

	# Get adjacent resources
	var adjacent_resources = get_adjacent_resources(character)

	# Highlight each harvestable resource
	for resource in adjacent_resources:
		if is_resource_harvestable(character, resource):
			# Check if already assigned
			var is_assigned = (character.assigned_resource == resource)
			var color = assigned_highlight_color if is_assigned else adjacent_highlight_color
			create_highlight_for_resource(resource.coordinate, color)

	var harvestable_count = resource_highlights.size()
	if harvestable_count > 0:
		print("  ✓ Highlighted %d harvestable adjacent resources" % harvestable_count)

## Hide all resource highlights
func hide_all_highlights() -> void:
	for highlight in resource_highlights.values():
		highlight.queue_free()
	resource_highlights.clear()

## Check if a character can harvest a resource
## @param character: Character to check
## @param resource: Resource to check
## @returns: true if character has the ability to harvest this resource
func is_resource_harvestable(character: Character, resource: ResourceStatus) -> bool:
	if not character or not resource:
		return false

	# Check if resource still exists
	if "exists" in resource and not resource.exists:
		return false

	# Check if resource has actions remaining
	if "actions_remaining" in resource and resource.actions_remaining <= 0:
		return false

	# Check ability match
	match resource.resource_type:
		ResourceStatus.ResourceType.SHEEP:
			return character.canHunt if "canHunt" in character else false
		ResourceStatus.ResourceType.TREE:
			return character.canChop if "canChop" in character else false
		ResourceStatus.ResourceType.ROCK, ResourceStatus.ResourceType.GOLD_DEPOSIT:
			return character.canMine if "canMine" in character else false

	return false

## Get all resources adjacent to a character
## @param character: Character to check around
## @returns: Array of ResourceStatus objects
func get_adjacent_resources(character: Character) -> Array:
	var adjacent = []

	if not character or not resource_manager:
		return adjacent

	# Get all 6 neighbor coordinates
	var neighbors = character.current_coordinate.get_neighbors()

	# Check each neighbor for a resource
	for neighbor in neighbors:
		var resource = resource_manager.get_resource_at(neighbor)
		if resource:
			adjacent.append(resource)

	return adjacent

## Update highlight for assigned resource
## @param character: Character with assignment
func update_assignment_highlight(character: Character) -> void:
	if not character or not character.assigned_resource:
		return

	var resource = character.assigned_resource
	if resource_highlights.has(resource.coordinate):
		var highlight = resource_highlights[resource.coordinate]
		highlight.modulate = assigned_highlight_color
		print("  ✓ Updated highlight for assigned resource at %s" % resource.coordinate)
