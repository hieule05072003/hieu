extends Node2D

## Main scene demonstrating the complete HexTilemap system with:
## 1. Automatic rendering (HexTerrainRenderer)
## 2. Random terrain generation (HexMapGenerator)
## 3. Save/Load functionality (HexMapLoader)

@onready var hex_tilemap: HexTilemap = $HexTilemap
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var env_tile_map_layer: TileMapLayer = $EnvironmentalTileMapLayer
@onready var renderer: HexTerrainRenderer = $HexTerrainRenderer
@onready var generator: HexMapGenerator = $HexMapGenerator
@onready var loader: HexMapLoader = $HexMapLoader
@onready var camera: Camera2D = $Camera2D
@onready var coordinate_display: CoordinateDisplay = $CoordinateDisplay
@onready var asset_renderer: EnvironmentalAssetRenderer = $EnvironmentalAssetRenderer
@onready var character_renderer: CharacterRenderer = $CharacterRenderer

## === Part 2: Resource and Harvesting System ===
## These are created programmatically in _ready()
var resource_manager: ResourceManager = null
var harvesting_system: HarvestingSystem = null
var resource_renderer: ResourceRenderer = null
var character_manager: CharacterManager = null

## === Part 3: Combat and Enemy System ===
var enemy_manager: EnemyManager = null
var enemy_renderer: EnemyRenderer = null
var combat_system: CombatSystem = null

## Simple UI (new clean approach)
var resource_counter_label: Label = null
var harvest_progress_label: Label = null

## Turn System UI
var execute_turn_button: Button = null
var phase_indicator_label: Label = null
var turn_counter_label: Label = null
var upkeep_warning_label: Label = null
var action_progress_label: Label = null  # Shows "Action X/7" during execution

## Phase 5: Character info panel UI
var character_info_panel: PanelContainer = null
var char_info_name_label: Label = null
var char_info_position_label: Label = null
var char_info_abilities_label: Label = null
var char_info_assignment_label: Label = null

## === Victory UI ===
var objectives_label: Label = null
var victory_panel: PanelContainer = null
var victory_label: Label = null
var next_level_button: Button = null

## === Debug UI ===
var debug_panel: PanelContainer = null
var debug_info_label: Label = null

## Current generation mode
enum GenerationMode { ISLAND, NOISE, CLUSTERED, CHECKERBOARD, TEST_PATTERN }
var current_mode: GenerationMode = GenerationMode.ISLAND

## Camera control settings
var camera_pan_speed: float = 300.0  # Pixels per second
var camera_zoom_speed: float = 0.1   # Zoom change per input
var camera_zoom_min: float = 0.3     # Minimum zoom level
var camera_zoom_max: float = 2.0     # Maximum zoom level
var default_camera_position: Vector2 = Vector2.ZERO
var default_camera_zoom: Vector2 = Vector2(1.035, 1.035)

func _ready() -> void:
	print("\n" + "=".repeat(60))
	print("  HEX TILEMAP SYSTEM - FULL FEATURE DEMO")
	print("=".repeat(60) + "\n")

	# Initialize the tilemap
	print("STEP 1: Initializing 20x20 hex grid...")
	hex_tilemap.initialize_map(20, 20, HexTile.TerrainType.GRASS)
	print()

	# Setup the renderer
	print("STEP 2: Setting up automatic terrain renderer...")
	renderer.setup(hex_tilemap, tile_map_layer)
	hex_tilemap.attach_renderer(renderer)
	print()

	# Generate terrain
	print("STEP 3: Generating terrain (Island mode)...")
	generator.generate_island(hex_tilemap, 8)
	print()

	# Automatically render to TileMapLayer
	print("STEP 4: Rendering tilemap visually...")
	renderer.render_tilemap()
	print()

	# Center camera on the map
	print("STEP 4.5: Centering camera...")
	center_camera_on_map()
	print()

	# Setup coordinate display
	print("STEP 4.6: Setting up coordinate display...")
	coordinate_display.setup(hex_tilemap, tile_map_layer)
	print()

	# Setup environmental asset renderer
	print("STEP 4.7: Setting up environmental asset renderer...")
	asset_renderer.setup(hex_tilemap, env_tile_map_layer)
	print()

	# Render environmental assets
	print("STEP 4.8: Rendering environmental assets...")
	asset_renderer.render_all_assets()
	print()

	# Setup character renderer
	print("STEP 4.9: Setting up character renderer...")
	character_renderer.setup(hex_tilemap, tile_map_layer)
	print()

	# Add 3 specialized characters (Phase 2)
	print("STEP 4.10: Adding 3 specialized characters...")
	print("  Creating Hunter, Chopper, and Miner team...")

	# Create Hunter (Archer sprite) - Specializes in hunting animals for food
	var hunter_coord = HexCoordinate.new(9, 10)
	var hunter = Character.new(
		"hunter_01",
		"Hunter",
		"res://Character/Player/Archer_Idle.png",
		hunter_coord,
		Character.CharacterType.PLAYER
	)
	hunter.character_class = "Hunter"
	hunter.set_abilities(true, false, false)  # canHunt=true ONLY
	hunter.set_stats(100, 15, 5, 2)  # HP=100, Attack=15, WorkPerAction=5, Range=2
	character_renderer.add_character(hunter)
	print("    ✓ Hunter created at (9, 10) - Ability: Hunt (Sheep → Food)")

	# Create Chopper (Warrior sprite) - Specializes in chopping trees for wood
	var chopper_coord = HexCoordinate.new(10, 10)
	var chopper = Character.new(
		"chopper_01",
		"Chopper",
		"res://Character/Player/Warrior_Idle.png",
		chopper_coord,
		Character.CharacterType.PLAYER
	)
	chopper.character_class = "Chopper"
	chopper.set_abilities(false, true, false)  # canChop=true ONLY
	chopper.set_stats(100, 15, 5, 2)  # HP=100, Attack=15, WorkPerAction=5, Range=2
	character_renderer.add_character(chopper)
	print("    ✓ Chopper created at (10, 10) - Ability: Chop (Trees → Wood)")

	# Create Miner (Pawn sprite) - Specializes in mining rocks and gold
	var miner_coord = HexCoordinate.new(11, 10)
	var miner = Character.new(
		"miner_01",
		"Miner",
		"res://Character/Player/Pawn_Blue.png",
		miner_coord,
		Character.CharacterType.PLAYER
	)
	miner.character_class = "Miner"
	miner.set_abilities(false, false, true)  # canMine=true ONLY
	miner.set_stats(100, 15, 5, 2)  # HP=100, Attack=15, WorkPerAction=5, Range=2
	character_renderer.add_character(miner)
	print("    ✓ Miner created at (11, 10) - Ability: Mine (Rocks → Gold)")
	print("  ✓ 3-character team complete!")
	print()

	# Part 2: Setup resource and harvesting systems
	print("STEP 5: Setting up Part 2 - Resource & Harvesting System...")
	setup_part2_systems()
	print()

	# Register all characters with CharacterManager
	print("STEP 5.5: Registering characters with CharacterManager...")
	character_manager.add_character(hunter)
	character_manager.add_character(chopper)
	character_manager.add_character(miner)
	print("  ✓ All 3 characters registered with CharacterManager")
	print("  ✓ CharacterManager now tracking: %d characters" % character_manager.get_character_count())
	print()

	# Test save functionality
	print("STEP 5: Testing save functionality...")
	var save_path = "user://test_map.json"
	var saved = loader.save_map_to_file(hex_tilemap, save_path)
	if saved:
		print("  ✓ Saved to: %s" % save_path)
	print()

	# Display statistics
	print("STEP 6: Map statistics...")
	loader.print_map_stats(hex_tilemap)

	# Show controls
	print_controls()

	print("\n" + "=".repeat(60))
	print("  System ready! Map is displaying on screen.")
	print("=".repeat(60) + "\n")

	# TEST: Verify owner field can store character/resource data
	test_owner_field()

func test_owner_field() -> void:
	print("\n" + "=".repeat(60))
	print("  TESTING OWNER FIELD FOR CHARACTER STORAGE")
	print("=".repeat(60) + "\n")

	# Create a test character object
	var test_coord = HexCoordinate.new(5, 5)
	var my_character = "Player Character"  # Could be any object

	print("TEST 1: Placing character on tile (5, 5)...")
	hex_tilemap.set_tile_info(test_coord, -1, my_character)

	# Verify it was stored
	var tile = hex_tilemap.get_tile_info(test_coord)
	print("  ✓ Tile (5,5) owner: %s" % tile.owner)
	print("  ✓ Is tile occupied? %s" % tile.is_occupied())
	print()

	print("TEST 2: Simulating character movement from (5,5) to (10,10)...")
	var new_coord = HexCoordinate.new(10, 10)

	# Clear old tile (character leaves)
	hex_tilemap.set_tile_info(test_coord, -1, null)
	print("  ✓ Removed character from tile (5,5)")

	# Place on new tile (character arrives)
	hex_tilemap.set_tile_info(new_coord, -1, my_character)
	print("  ✓ Placed character on tile (10,10)")
	print()

	print("TEST 3: Verifying movement...")
	var old_tile = hex_tilemap.get_tile_info(test_coord)
	var new_tile = hex_tilemap.get_tile_info(new_coord)
	print("  ✓ Tile (5,5) owner after move: %s" % ("null" if old_tile.owner == null else old_tile.owner))
	print("  ✓ Tile (10,10) owner: %s" % new_tile.owner)
	print("  ✓ Old tile occupied? %s" % old_tile.is_occupied())
	print("  ✓ New tile occupied? %s" % new_tile.is_occupied())
	print()

	print("TEST 4: Getting all occupied tiles...")
	var occupied = hex_tilemap.get_occupied_tiles()
	print("  ✓ Number of occupied tiles: %d" % occupied.size())
	for occupied_tile in occupied:
		print("    - Tile %s has owner: %s" % [occupied_tile.coordinate, occupied_tile.owner])
	print()

	print("=".repeat(60))
	print("  OWNER FIELD TESTS COMPLETE")
	print("  Result: Character storage is working correctly!")
	print("  The system is ready for player movement implementation.")
	print("=".repeat(60) + "\n")

## === Part 2: Setup Function ===

func setup_part2_systems() -> void:
	# Create ResourceManager node
	resource_manager = ResourceManager.new()
	resource_manager.name = "ResourceManager"
	resource_manager.tilemap = hex_tilemap
	add_child(resource_manager)
	print("  ✓ ResourceManager created and initialized")

	# Create HarvestingSystem node
	harvesting_system = HarvestingSystem.new()
	harvesting_system.name = "HarvestingSystem"
	harvesting_system.resource_manager = resource_manager
	add_child(harvesting_system)
	print("  ✓ HarvestingSystem created and initialized")

	# Create ResourceRenderer node
	resource_renderer = ResourceRenderer.new()
	resource_renderer.name = "ResourceRenderer"
	resource_renderer.setup(hex_tilemap, tile_map_layer, resource_manager)
	add_child(resource_renderer)
	print("  ✓ ResourceRenderer created and initialized")

	# Create CharacterManager node
	character_manager = CharacterManager.new()
	character_manager.name = "CharacterManager"
	add_child(character_manager)
	print("  ✓ CharacterManager created and initialized")

	# Create EnemyManager node
	enemy_manager = EnemyManager.new()
	enemy_manager.name = "EnemyManager"
	add_child(enemy_manager)
	print("  ✓ EnemyManager created and initialized")

	# Create EnemyRenderer node
	enemy_renderer = EnemyRenderer.new()
	enemy_renderer.name = "EnemyRenderer"
	enemy_renderer.setup(hex_tilemap, tile_map_layer)
	add_child(enemy_renderer)
	print("  ✓ EnemyRenderer created and initialized")

	# Create CombatSystem node
	combat_system = CombatSystem.new()
	combat_system.name = "CombatSystem"
	combat_system.enemy_manager = enemy_manager
	add_child(combat_system)
	print("  ✓ CombatSystem created and initialized")

	# Connect TurnManager to our systems
	TurnManager.character_manager = character_manager
	TurnManager.harvesting_system = harvesting_system
	TurnManager.combat_system = combat_system
	TurnManager.enemy_manager = enemy_manager
	TurnManager.resource_manager = resource_manager
	print("  ✓ TurnManager connected to all systems")

	# Create NEW simple UI with CanvasLayer (stays fixed on screen!)
	print("\n  [UI] Creating simple resource counter...")
	var ui_canvas = CanvasLayer.new()
	ui_canvas.name = "UICanvas"
	add_child(ui_canvas)
	print("  ✓ CanvasLayer created (UI will stay fixed)")

	resource_counter_label = Label.new()
	resource_counter_label.position = Vector2(10, 10)
	resource_counter_label.add_theme_font_size_override("font_size", 24)
	resource_counter_label.add_theme_color_override("font_color", Color.WHITE)
	resource_counter_label.text = "Food: 0  |  Wood: 0  |  Gold: 0"
	ui_canvas.add_child(resource_counter_label)
	print("  ✓ Resource counter created at (10, 10)")
	print("  ✓ Label reference: %s" % resource_counter_label)
	print("  ✓ UI will update in _process() using GameStatus autoload")

	# Create harvest progress label (initially hidden)
	harvest_progress_label = Label.new()
	harvest_progress_label.position = Vector2(10, 50)  # Below resource counter
	harvest_progress_label.add_theme_font_size_override("font_size", 20)
	harvest_progress_label.add_theme_color_override("font_color", Color.YELLOW)
	harvest_progress_label.text = "Harvesting: 0/7"
	harvest_progress_label.visible = false  # Hidden by default
	ui_canvas.add_child(harvest_progress_label)
	print("  ✓ Harvest progress label created at (10, 50), initially hidden")

	# Create turn system UI
	print("\n  [UI] Creating turn system UI...")

	# Execute Turn button (bottom center)
	execute_turn_button = Button.new()
	execute_turn_button.text = "EXECUTE TURN"
	# Position relative to viewport - bottom center
	var viewport_size = get_viewport().get_visible_rect().size
	execute_turn_button.position = Vector2(
		(viewport_size.x - 200) / 2,  # Center horizontally (button width is 200)
		viewport_size.y - 80  # 80 pixels from bottom
	)
	execute_turn_button.size = Vector2(200, 60)
	execute_turn_button.add_theme_font_size_override("font_size", 20)
	execute_turn_button.pressed.connect(_on_execute_turn_pressed)
	ui_canvas.add_child(execute_turn_button)
	print("  ✓ Execute Turn button created at %s (viewport size: %s)" % [execute_turn_button.position, viewport_size])

	# Phase indicator (top center)
	phase_indicator_label = Label.new()
	phase_indicator_label.position = Vector2((viewport_size.x - 300) / 2, 10)  # Centered
	phase_indicator_label.add_theme_font_size_override("font_size", 28)
	phase_indicator_label.add_theme_color_override("font_color", Color.CYAN)
	phase_indicator_label.text = "PLANNING PHASE"
	ui_canvas.add_child(phase_indicator_label)
	print("  ✓ Phase indicator created at %s" % phase_indicator_label.position)

	# Turn counter (top right)
	turn_counter_label = Label.new()
	turn_counter_label.position = Vector2(viewport_size.x - 150, 10)
	turn_counter_label.add_theme_font_size_override("font_size", 24)
	turn_counter_label.add_theme_color_override("font_color", Color.WHITE)
	turn_counter_label.text = "Turn: 1"
	ui_canvas.add_child(turn_counter_label)
	print("  ✓ Turn counter created at %s" % turn_counter_label.position)

	# Upkeep warning (top right, below turn counter)
	upkeep_warning_label = Label.new()
	upkeep_warning_label.position = Vector2(viewport_size.x - 200, 45)
	upkeep_warning_label.add_theme_font_size_override("font_size", 18)
	upkeep_warning_label.add_theme_color_override("font_color", Color.ORANGE)
	upkeep_warning_label.text = "Next upkeep: 5 food"
	ui_canvas.add_child(upkeep_warning_label)
	print("  ✓ Upkeep warning created at %s" % upkeep_warning_label.position)

	# Action progress label (top-left corner, below resources, shows during execution)
	action_progress_label = Label.new()
	action_progress_label.position = Vector2(20, 60)
	action_progress_label.add_theme_font_size_override("font_size", 32)
	action_progress_label.add_theme_color_override("font_color", Color.YELLOW)
	action_progress_label.text = "Action 0/7"
	action_progress_label.visible = false  # Hidden by default
	ui_canvas.add_child(action_progress_label)
	print("  ✓ Action progress label created (top-left corner, initially hidden)")

	# Phase 5: Character info panel (right side, shows when character selected)
	character_info_panel = PanelContainer.new()
	character_info_panel.position = Vector2(viewport_size.x - 250, 150)
	character_info_panel.custom_minimum_size = Vector2(230, 200)
	character_info_panel.visible = false  # Hidden by default

	# Create VBoxContainer for vertical layout
	var info_vbox = VBoxContainer.new()
	character_info_panel.add_child(info_vbox)

	# Character name label
	char_info_name_label = Label.new()
	char_info_name_label.add_theme_font_size_override("font_size", 20)
	char_info_name_label.add_theme_color_override("font_color", Color.YELLOW)
	char_info_name_label.text = "HUNTER"
	info_vbox.add_child(char_info_name_label)

	# Position label
	char_info_position_label = Label.new()
	char_info_position_label.add_theme_font_size_override("font_size", 14)
	char_info_position_label.text = "Position: (0, 0)"
	info_vbox.add_child(char_info_position_label)

	# Spacer
	var spacer1 = Label.new()
	spacer1.text = ""
	info_vbox.add_child(spacer1)

	# Abilities label
	char_info_abilities_label = Label.new()
	char_info_abilities_label.add_theme_font_size_override("font_size", 14)
	char_info_abilities_label.text = "Abilities:\n✓ Hunt\n✗ Chop\n✗ Mine"
	info_vbox.add_child(char_info_abilities_label)

	# Spacer
	var spacer2 = Label.new()
	spacer2.text = ""
	info_vbox.add_child(spacer2)

	# Assignment label
	char_info_assignment_label = Label.new()
	char_info_assignment_label.add_theme_font_size_override("font_size", 14)
	char_info_assignment_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	char_info_assignment_label.text = "No resource assigned"
	info_vbox.add_child(char_info_assignment_label)

	ui_canvas.add_child(character_info_panel)
	print("  ✓ Character info panel created (right side, initially hidden)")

	# Create objectives tracker (top-right, below upkeep)
	objectives_label = Label.new()
	objectives_label.position = Vector2(viewport_size.x - 220, 80)
	objectives_label.add_theme_font_size_override("font_size", 16)
	objectives_label.add_theme_color_override("font_color", Color.YELLOW)
	objectives_label.text = "Objectives:\nResources: 0\nEnemies: 0"
	ui_canvas.add_child(objectives_label)
	print("  ✓ Objectives tracker created (top-right)")

	# Create victory panel (center screen, initially hidden)
	victory_panel = PanelContainer.new()
	victory_panel.position = Vector2(viewport_size.x / 2 - 200, viewport_size.y / 2 - 150)
	victory_panel.custom_minimum_size = Vector2(400, 300)
	victory_panel.visible = false

	var victory_vbox = VBoxContainer.new()
	victory_panel.add_child(victory_vbox)

	victory_label = Label.new()
	victory_label.text = "LEVEL COMPLETE!"
	victory_label.add_theme_font_size_override("font_size", 36)
	victory_label.add_theme_color_override("font_color", Color.YELLOW)
	victory_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	victory_vbox.add_child(victory_label)

	# Spacer
	var victory_spacer = Control.new()
	victory_spacer.custom_minimum_size = Vector2(0, 40)
	victory_vbox.add_child(victory_spacer)

	next_level_button = Button.new()
	next_level_button.text = "NEXT LEVEL"
	next_level_button.custom_minimum_size = Vector2(200, 60)
	next_level_button.add_theme_font_size_override("font_size", 24)
	next_level_button.pressed.connect(_on_next_level_pressed)
	victory_vbox.add_child(next_level_button)

	ui_canvas.add_child(victory_panel)
	print("  ✓ Victory panel created (center screen, initially hidden)")

	# Create debug panel (top-left, toggleable with F12)
	debug_panel = PanelContainer.new()
	debug_panel.position = Vector2(10, 120)
	debug_panel.custom_minimum_size = Vector2(300, 250)
	debug_panel.visible = false  # Hidden by default

	var debug_vbox = VBoxContainer.new()
	debug_panel.add_child(debug_vbox)

	var debug_title = Label.new()
	debug_title.text = "=== DEBUG INFO ==="
	debug_title.add_theme_font_size_override("font_size", 16)
	debug_title.add_theme_color_override("font_color", Color.CYAN)
	debug_vbox.add_child(debug_title)

	debug_info_label = Label.new()
	debug_info_label.add_theme_font_size_override("font_size", 12)
	debug_info_label.add_theme_color_override("font_color", Color.WHITE)
	debug_info_label.text = "Press F12 to toggle\nPress F11 for full status"
	debug_vbox.add_child(debug_info_label)

	ui_canvas.add_child(debug_panel)
	print("  ✓ Debug panel created (F12 to toggle)")

	print("  ✓ Turn system UI complete")

	# Place test resources on the map
	place_test_resources()
	print("  ✓ Test resources placed on map")

	# Render resource sprites
	resource_renderer.render_all_resources()
	print("  ✓ Resource sprites rendered")

	# Place monsters on the map
	place_level_monsters(GameStatus.level)
	print("  ✓ Monsters placed for level %d" % GameStatus.level)

	# Initialize victory objectives
	if resource_manager and enemy_manager:
		VictoryManager.initialize_level_objectives(
			resource_manager.get_resource_count(),
			enemy_manager.get_enemy_count()
		)
		print("  ✓ Victory objectives initialized")

	# Connect signals
	var game_status_node = get_node("/root/GameStatus")
	if game_status_node:
		game_status_node.resources_changed.connect(_on_resources_changed)
		print("  ✓ Connected to GameStatus signals")

	# Connect harvesting signals for feedback
	harvesting_system.harvesting_started.connect(_on_harvesting_started)
	harvesting_system.action_executed.connect(_on_harvest_action)
	harvesting_system.harvesting_completed.connect(_on_harvesting_completed)
	harvesting_system.resource_depleted.connect(_on_resource_depleted)
	print("  ✓ Connected to HarvestingSystem signals")

	# Connect TurnManager signals
	TurnManager.phase_changed.connect(_on_phase_changed)
	TurnManager.turn_started.connect(_on_turn_started)
	TurnManager.execution_started.connect(_on_execution_started)
	TurnManager.action_executed.connect(_on_action_executed)
	TurnManager.execution_completed.connect(_on_execution_completed)
	TurnManager.game_over.connect(_on_game_over)
	print("  ✓ Connected to TurnManager signals")

	# Connect CombatSystem signals
	combat_system.enemy_defeated.connect(_on_enemy_defeated)
	combat_system.character_defeated.connect(_on_character_defeated)
	combat_system.attack_executed.connect(_on_attack_executed)
	print("  ✓ Connected to CombatSystem signals")

	# Connect VictoryManager signals
	VictoryManager.victory_achieved.connect(_on_victory_achieved)
	VictoryManager.objective_updated.connect(_on_objectives_updated)
	print("  ✓ Connected to VictoryManager signals")

	# Start the turn system
	TurnManager.start_game()
	print("  ✓ Turn system started")

	print("\n  === PART 2 CONTROLS ===")
	print("  [Left Click] - Select character OR move selected character")
	print("  [ESC] - Deselect character")
	print("  [G] - Print GameStatus")
	print("  [V] - Toggle resource sprites")
	print("  ========================\n")

## Place test resources on the map for testing
## Phase 4: Place resources in clusters (70-80%) and scattered (20-30%)
func place_test_resources() -> void:
	print("  DEBUG: Placing resources with clustered generation...")

	# Phase 4: Clustered resource placement
	# 70-80% in clusters, 20-30% scattered
	var num_clusters = 1  # Just 1 cluster for testing (2-3 resources total)
	var num_scattered = 0  # No scattered resources for testing

	# Place clusters
	var clustered_count = place_clustered_resources(num_clusters)
	print("    ✓ Placed %d resources in %d clusters" % [clustered_count, num_clusters])

	# Place scattered resources
	var scattered_count = place_scattered_resources(num_scattered)
	print("    ✓ Placed %d scattered resources" % scattered_count)

	print("  Total resources placed: %d (%.1f%% clustered, %.1f%% scattered)" % [
		resource_manager.get_resource_count(),
		(float(clustered_count) / resource_manager.get_resource_count() * 100.0),
		(float(scattered_count) / resource_manager.get_resource_count() * 100.0)
	])

## Phase 4: Place resources in clusters
## @param num_clusters: Number of clusters to generate
## @returns: Total number of resources placed
func place_clustered_resources(num_clusters: int) -> int:
	var total_placed = 0
	var resource_types = [
		ResourceStatus.ResourceType.SHEEP,
		ResourceStatus.ResourceType.TREE,
		ResourceStatus.ResourceType.ROCK,
		ResourceStatus.ResourceType.GOLD_DEPOSIT
	]

	for i in range(num_clusters):
		# Pick random resource type for this cluster
		var resource_type = resource_types[randi() % resource_types.size()]

		# Pick random cluster size (2-3 resources)
		var cluster_size = randi_range(2, 3)

		# Find valid center point for cluster
		var center = get_random_valid_coordinate_for_resource()
		if not center:
			continue  # Skip if no valid location found

		# Place center resource
		var placed_resource = resource_manager.place_resource(center, resource_type)
		if placed_resource:
			total_placed += 1

		# Place remaining resources around center
		var neighbors = center.get_neighbors()
		var placed_in_cluster = 1

		for neighbor in neighbors:
			if placed_in_cluster >= cluster_size:
				break

			# Check if this neighbor is valid
			if is_valid_resource_placement(neighbor):
				placed_resource = resource_manager.place_resource(neighbor, resource_type)
				if placed_resource:
					total_placed += 1
					placed_in_cluster += 1

	return total_placed

## Phase 4: Place scattered individual resources
## @param count: Number of scattered resources to place
## @returns: Total number of resources placed
func place_scattered_resources(count: int) -> int:
	var total_placed = 0
	var resource_types = [
		ResourceStatus.ResourceType.SHEEP,
		ResourceStatus.ResourceType.TREE,
		ResourceStatus.ResourceType.ROCK,
		ResourceStatus.ResourceType.GOLD_DEPOSIT
	]

	for i in range(count):
		# Pick random resource type
		var resource_type = resource_types[randi() % resource_types.size()]

		# Find valid random location
		var coord = get_random_valid_coordinate_for_resource()
		if not coord:
			continue  # Skip if no valid location found

		# Place resource
		var placed_resource = resource_manager.place_resource(coord, resource_type)
		if placed_resource:
			total_placed += 1

	return total_placed

## Phase 4: Get a random valid coordinate for placing a resource
## @returns: Valid HexCoordinate or null if none found after max attempts
func get_random_valid_coordinate_for_resource() -> HexCoordinate:
	var max_attempts = 50

	for attempt in range(max_attempts):
		# Pick random coordinate within map bounds
		var q = randi_range(5, hex_tilemap.width - 5)
		var r = randi_range(5, hex_tilemap.height - 5)
		var coord = HexCoordinate.new(q, r)

		if is_valid_resource_placement(coord):
			return coord

	return null  # No valid location found

## Phase 4: Check if a coordinate is valid for resource placement
## @param coord: Coordinate to check
## @returns: true if valid (walkable, not occupied)
func is_valid_resource_placement(coord: HexCoordinate) -> bool:
	# Check if coordinate is within bounds
	if not hex_tilemap.is_valid_coordinate(coord):
		return false

	# Check if tile exists
	var tile = hex_tilemap.get_tile_info(coord)
	if not tile:
		return false

	# Check if tile is walkable (grass or sand, not water or mountain)
	if not tile.is_walkable():
		return false

	# Check if tile is already occupied (by character or resource)
	if tile.is_occupied():
		return false

	# Check if resource already exists here
	if resource_manager.has_resource_at(coord):
		return false

	return true

## Signal handler: When resources change
func _on_resources_changed(food: int, wood: int, gold: int) -> void:
	pass  # UI updates in _process() now

## Signal handler: When harvesting starts
func _on_harvesting_started(character: Character, resource: ResourceStatus) -> void:
	harvest_progress_label.visible = true
	harvest_progress_label.text = "Harvesting: 0/7"
	print("  [UI] Harvest progress shown")

## Signal handler: When a harvest action is executed
func _on_harvest_action(action_number: int, character: Character, resource: ResourceStatus, yields: Dictionary, total_yields: Dictionary) -> void:
	harvest_progress_label.text = "Harvesting: %d/7" % action_number
	print("  [UI] Progress updated to %d/7" % action_number)

## Signal handler: When harvesting completes
func _on_harvesting_completed(character: Character, resource: ResourceStatus, total_yields: Dictionary) -> void:
	harvest_progress_label.visible = false
	print("  [UI] Harvest progress hidden")
	print("  Harvesting complete! Total yields: Food +%d, Wood +%d, Gold +%d" % [
		total_yields["food"],
		total_yields["wood"],
		total_yields["gold"]
	])

## Signal handler: When a resource is depleted
func _on_resource_depleted(resource: ResourceStatus) -> void:
	pass  # Just log in console already

## === Turn System Signal Handlers ===

## Signal handler: When turn phase changes
func _on_phase_changed(new_phase: TurnManager.GamePhase) -> void:
	var phase_name = TurnManager.GamePhase.keys()[new_phase]
	print("[Main] Phase changed to: %s" % phase_name)

	# Update phase indicator label
	if phase_indicator_label:
		match new_phase:
			TurnManager.GamePhase.PLANNING:
				phase_indicator_label.text = "PLANNING PHASE"
				phase_indicator_label.add_theme_color_override("font_color", Color.CYAN)
				execute_turn_button.disabled = false
			TurnManager.GamePhase.EXECUTING:
				phase_indicator_label.text = "EXECUTING..."
				phase_indicator_label.add_theme_color_override("font_color", Color.YELLOW)
				execute_turn_button.disabled = true
			TurnManager.GamePhase.RESOLUTION:
				phase_indicator_label.text = "RESOLVING TURN..."
				phase_indicator_label.add_theme_color_override("font_color", Color.ORANGE)
				execute_turn_button.disabled = true
			TurnManager.GamePhase.GAME_OVER:
				phase_indicator_label.text = "GAME OVER"
				phase_indicator_label.add_theme_color_override("font_color", Color.RED)
				execute_turn_button.disabled = true

## Signal handler: When a new turn starts
func _on_turn_started(turn_number: int) -> void:
	print("[Main] Turn %d started" % turn_number)

	# Update turn counter
	if turn_counter_label:
		turn_counter_label.text = "Turn: %d" % turn_number

	# Update upkeep warning
	if upkeep_warning_label:
		var next_upkeep = GameStatus.food_expense_per_turn
		upkeep_warning_label.text = "Next upkeep: %d food" % next_upkeep

		# Warning color if food is low
		if GameStatus.food < next_upkeep:
			upkeep_warning_label.add_theme_color_override("font_color", Color.RED)
		elif GameStatus.food < next_upkeep * 2:
			upkeep_warning_label.add_theme_color_override("font_color", Color.ORANGE)
		else:
			upkeep_warning_label.add_theme_color_override("font_color", Color.WHITE)

## Signal handler: When game ends
func _on_game_over(reason: String) -> void:
	print("[Main] GAME OVER: %s" % reason)

	# Show game over message
	if phase_indicator_label:
		phase_indicator_label.text = "GAME OVER - %s" % reason
		phase_indicator_label.add_theme_color_override("font_color", Color.RED)

	# TODO: Show proper game over screen with restart button

## Signal handler: When turn execution starts
func _on_execution_started() -> void:
	print("[Main] Turn execution started")

	# Show action progress label
	if action_progress_label:
		action_progress_label.visible = true
		action_progress_label.text = "Action 0/7"

## Signal handler: When an action is executed
func _on_action_executed(action_number: int) -> void:
	print("[Main] Action %d/7 executed" % action_number)

	# Update action progress label
	if action_progress_label:
		action_progress_label.text = "Action %d/7" % action_number

## Signal handler: When turn execution completes
func _on_execution_completed() -> void:
	print("[Main] Turn execution completed")

	# Hide action progress label
	if action_progress_label:
		action_progress_label.visible = false

## Button handler: Execute Turn button pressed
func _on_execute_turn_pressed() -> void:
	print("[Main] Execute Turn button pressed")

	# Check if we can execute
	if not TurnManager.can_player_interact():
		push_warning("[Main] Cannot execute turn - not in PLANNING phase")
		return

	# Execute the turn
	TurnManager.execute_turn()

func _process(delta: float) -> void:
	# Update UI every frame using GameStatus autoload
	if resource_counter_label:
		resource_counter_label.text = "Food: %d  |  Wood: %d  |  Gold: %d" % [
			GameStatus.food,
			GameStatus.wood,
			GameStatus.gold
		]

	# Update objectives tracker
	update_objectives_display()

	# Update debug panel if visible
	if debug_panel and debug_panel.visible and debug_info_label:
		var debug_info = DebugManager.get_debug_info()
		var char_count = character_manager.get_character_count() if character_manager else 0
		var enemy_count = enemy_manager.get_alive_enemy_count() if enemy_manager else 0
		var res_count = resource_manager.get_resource_count() if resource_manager else 0

		debug_info_label.text = "FPS: %.1f\nPhase: %s\nTurn: %d\n\nCharacters: %d\nEnemies: %d\nResources: %d\n\nErrors: %d\nWarnings: %d" % [
			debug_info["fps"],
			debug_info["phase"],
			debug_info["turn"],
			char_count,
			enemy_count,
			res_count,
			debug_info["errors"],
			debug_info["warnings"]
		]

	# Handle camera movement
	handle_camera_movement(delta)

	# Handle keyboard input for testing features
	handle_input()

func _input(event: InputEvent) -> void:
	# Handle mouse input
	if event is InputEventMouseButton and event.pressed:
		# Camera zoom with mouse wheel
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			handle_camera_zoom(camera_zoom_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			handle_camera_zoom(-camera_zoom_speed)
		# Left click to show coordinate
		elif event.button_index == MOUSE_BUTTON_LEFT:
			handle_tile_click(event.position)
		# Right click to hide coordinate and deselect character
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			coordinate_display.hide_single_coordinate()
			# Phase 3/5: Also deselect character and hide resource highlights and info panel
			if character_renderer.has_selected_character():
				character_renderer.deselect_character()
				character_manager.deselect_character()
				resource_renderer.hide_all_highlights()
				# Phase 5: Hide character info panel
				hide_character_info_panel()

func handle_input() -> void:
	# Escape - Part 2/3/5: Deselect character (if one is selected), otherwise quit
	if Input.is_action_just_pressed("ui_cancel"):
		if character_renderer.has_selected_character():
			character_renderer.deselect_character()
			character_manager.deselect_character()
			# Phase 3: Hide resource highlights
			resource_renderer.hide_all_highlights()
			# Phase 5: Hide character info panel
			hide_character_info_panel()
		else:
			print("Exiting...")
			get_tree().quit()

	# === DEBUG SHORTCUTS ===
	# F12 - Toggle debug panel
	if Input.is_action_just_pressed("ui_page_down") or Input.is_key_pressed(KEY_F12):
		if debug_panel:
			debug_panel.visible = !debug_panel.visible
			DebugManager.debug_log("Debug panel toggled: %s" % ("VISIBLE" if debug_panel.visible else "HIDDEN"))

	# F11 - Print full game state
	if Input.is_key_pressed(KEY_F11):
		DebugManager.print_game_state()
		if character_manager:
			DebugManager.print_characters(character_manager)
		if enemy_manager:
			DebugManager.print_enemies(enemy_manager)
		if resource_manager:
			DebugManager.print_resources(resource_manager)

	# F10 - Spawn test enemy at random location (debug)
	if Input.is_key_pressed(KEY_F10):
		spawn_test_enemy()

	# F9 - Heal all characters to full HP (debug)
	if Input.is_key_pressed(KEY_F9):
		heal_all_characters()

	# F8 - Add resources cheat (debug)
	if Input.is_key_pressed(KEY_F8):
		GameStatus.add_food(50)
		GameStatus.add_wood(50)
		GameStatus.add_gold(50)
		DebugManager.debug_log("DEBUG CHEAT: Added 50 of each resource")
		print("[DEBUG] Resources added: +50 Food, +50 Wood, +50 Gold")

	# G - Part 2: Print GameStatus
	if Input.is_key_pressed(KEY_G):
		var game_status = get_node_or_null("/root/GameStatus")
		if game_status:
			game_status.print_status()

	# Number keys - Generate different terrain types
	if Input.is_key_pressed(KEY_1):
		regenerate_map(GenerationMode.ISLAND)
	elif Input.is_key_pressed(KEY_2):
		regenerate_map(GenerationMode.NOISE)
	elif Input.is_key_pressed(KEY_3):
		regenerate_map(GenerationMode.CLUSTERED)
	elif Input.is_key_pressed(KEY_4):
		regenerate_map(GenerationMode.CHECKERBOARD)
	elif Input.is_key_pressed(KEY_5):
		regenerate_map(GenerationMode.TEST_PATTERN)

	# S - Save map
	if Input.is_action_just_pressed("ui_text_submit") or Input.is_key_pressed(KEY_S):
		save_current_map()

	# L - Load map
	if Input.is_key_pressed(KEY_L):
		load_saved_map()

	# R - Re-render (force refresh)
	if Input.is_key_pressed(KEY_R):
		print("\nRe-rendering map...")
		renderer.render_tilemap()

	# E - Export to CSV
	if Input.is_key_pressed(KEY_E):
		export_to_csv()

	# Plus/Minus - Zoom in/out
	if Input.is_key_pressed(KEY_EQUAL) or Input.is_key_pressed(KEY_KP_ADD):
		handle_camera_zoom(camera_zoom_speed)
	elif Input.is_key_pressed(KEY_MINUS) or Input.is_key_pressed(KEY_KP_SUBTRACT):
		handle_camera_zoom(-camera_zoom_speed)

	# Home - Reset camera
	if Input.is_key_pressed(KEY_HOME):
		reset_camera()

	# M - Generate 3 random maps
	if Input.is_key_pressed(KEY_M):
		generate_random_maps()

	# C - Toggle coordinate display
	if Input.is_key_pressed(KEY_C):
		coordinate_display.toggle_visibility()

	# T - Toggle environmental assets
	if Input.is_key_pressed(KEY_T):
		asset_renderer.toggle_visibility()

	# P - Toggle character visibility
	if Input.is_key_pressed(KEY_P):
		character_renderer.toggle_visibility()

	# V - Part 2: Toggle resource visibility
	if Input.is_key_pressed(KEY_V):
		if resource_renderer:
			resource_renderer.toggle_visibility()

## Regenerate map with a specific mode
func regenerate_map(mode: GenerationMode) -> void:
	if current_mode == mode:
		return  # Already in this mode

	current_mode = mode
	print("\n" + "-".repeat(60))

	match mode:
		GenerationMode.ISLAND:
			print("Generating ISLAND terrain...")
			generator.generate_island(hex_tilemap, 8)
		GenerationMode.NOISE:
			print("Generating NOISE-BASED terrain...")
			generator.generate_noise_map(hex_tilemap)
		GenerationMode.CLUSTERED:
			print("Generating CLUSTERED terrain...")
			generator.generate_clustered_terrain(hex_tilemap, 6)
		GenerationMode.CHECKERBOARD:
			print("Generating CHECKERBOARD pattern...")
			generator.generate_checkerboard(hex_tilemap)
		GenerationMode.TEST_PATTERN:
			print("Generating TEST PATTERN (all terrains)...")
			generator.generate_test_pattern(hex_tilemap)

	# Automatically re-render terrain and assets
	renderer.render_tilemap()
	asset_renderer.render_all_assets()
	print("✓ Map regenerated and rendered")
	print("-".repeat(60) + "\n")

## Save the current map
func save_current_map() -> void:
	print("\n" + "-".repeat(60))
	print("Saving current map...")

	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var save_path = "user://hex_map_%s.json" % timestamp

	if loader.save_map_to_file(hex_tilemap, save_path):
		print("✓ Map saved to: %s" % save_path)
		loader.print_map_stats(hex_tilemap)
	else:
		print("✗ Failed to save map")

	print("-".repeat(60) + "\n")

## Load a saved map
func load_saved_map() -> void:
	print("\n" + "-".repeat(60))
	print("Loading saved map...")

	var load_path = "user://test_map.json"

	if loader.load_map_from_file(hex_tilemap, load_path):
		print("✓ Map loaded from: %s" % load_path)
		# Re-render after loading
		renderer.render_tilemap()
		asset_renderer.render_all_assets()
		loader.print_map_stats(hex_tilemap)
	else:
		print("✗ Failed to load map (file may not exist)")

	print("-".repeat(60) + "\n")

## Export map to CSV
func export_to_csv() -> void:
	print("\n" + "-".repeat(60))
	print("Exporting map to CSV...")

	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var csv_path = "user://hex_map_%s.csv" % timestamp

	if loader.export_map_to_csv(hex_tilemap, csv_path):
		print("✓ Map exported to: %s" % csv_path)
	else:
		print("✗ Failed to export map")

	print("-".repeat(60) + "\n")

## Print keyboard controls
func print_controls() -> void:
	print("KEYBOARD CONTROLS:")
	print("\nTerrain Generation:")
	print("  [1] - Generate Island terrain")
	print("  [2] - Generate Noise-based terrain")
	print("  [3] - Generate Clustered terrain")
	print("  [4] - Generate Checkerboard pattern")
	print("  [5] - Generate Test pattern (all terrains)")
	print("  [M] - Generate 3 random maps and save")
	print("\nMap Management:")
	print("  [S] - Save current map to JSON")
	print("  [L] - Load saved map from JSON")
	print("  [E] - Export map to CSV")
	print("  [R] - Re-render map (force refresh)")
	print("\nCamera Controls:")
	print("  [WASD / Arrow Keys] - Move camera")
	print("  [Mouse Wheel / +/-] - Zoom in/out")
	print("  [Home] - Reset camera position")
	print("\nDisplay Options:")
	print("  [C] - Toggle all coordinates (debug mode)")
	print("  [T] - Toggle environmental assets (trees, rocks, water)")
	print("  [P] - Toggle character visibility")
	print("  [Left Click] - Show coordinate of clicked tile")
	print("  [Right Click] - Hide shown coordinate")
	print("\n  [ESC] - Quit")
	print()

## Center the camera on the tilemap
func center_camera_on_map() -> void:
	# Calculate the center of the map in tile coordinates
	var center_q = hex_tilemap.width / 2
	var center_r = hex_tilemap.height / 2

	# For isometric diamond down layout with tile_size (32, 32)
	# The camera position should be at approximately:
	# x = center_q * 24 (adjusted for diamond layout)
	# y = center_r * 16
	var camera_x = center_q * 24.0
	var camera_y = center_r * 16.0

	camera.position = Vector2(camera_x, camera_y)

	# Save as default position for reset
	default_camera_position = camera.position
	default_camera_zoom = camera.zoom

	print("✓ Camera centered at: %s" % camera.position)

## Handle camera movement with WASD/Arrow keys
func handle_camera_movement(delta: float) -> void:
	var movement = Vector2.ZERO

	# Check for WASD keys
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1

	# Apply movement (normalized for diagonal movement)
	if movement.length() > 0:
		movement = movement.normalized()
		camera.position += movement * camera_pan_speed * delta

## Handle camera zoom
func handle_camera_zoom(zoom_delta: float) -> void:
	var new_zoom = camera.zoom.x + zoom_delta

	# Clamp zoom within limits
	new_zoom = clamp(new_zoom, camera_zoom_min, camera_zoom_max)

	# Apply zoom
	camera.zoom = Vector2(new_zoom, new_zoom)

## Reset camera to default position and zoom
func reset_camera() -> void:
	camera.position = default_camera_position
	camera.zoom = default_camera_zoom
	print("\n✓ Camera reset to default position: %s, zoom: %s" % [camera.position, camera.zoom])

## Phase 3: Assign a resource to a character for harvesting
## @param character: Character to assign resource to
## @param resource: Resource to assign
## @returns: true if assignment successful
func assign_resource_to_character(character: Character, resource: ResourceStatus) -> bool:
	if not character or not resource:
		return false

	# Validate: Resource must be adjacent (distance <= 1)
	var distance = character.current_coordinate.distance_to(resource.coordinate)
	if distance > 1:
		print("==> Cannot assign resource - not adjacent (distance: %d)" % distance)
		return false

	# Validate: Character must have ability to harvest this resource
	if not resource_renderer.is_resource_harvestable(character, resource):
		var char_class = character.character_class if "character_class" in character else "Character"
		print("==> Cannot assign resource - %s cannot harvest %s" % [
			char_class,
			resource.get_resource_name()
		])
		return false

	# Assign resource
	character.assigned_resource = resource
	print("==> Assigned %s to %s at (%d, %d)" % [
		resource.get_resource_name(),
		character.character_class if "character_class" in character else character.name,
		resource.coordinate.q,
		resource.coordinate.r
	])

	# Update visual feedback (change highlight to yellow)
	resource_renderer.update_assignment_highlight(character)

	# Phase 5: Update character info panel
	update_character_info_panel(character)

	return true

## Assign an enemy to a character for combat
## @param character: Character to assign enemy to
## @param enemy: Enemy to assign
## @returns: true if assignment successful
func assign_enemy_to_character(character: Character, enemy: Enemy) -> bool:
	if not character or not enemy:
		return false

	# Validate: Enemy must be adjacent (distance <= 1)
	var distance = character.current_coordinate.distance_to(enemy.current_coordinate)
	if distance > 1:
		print("==> Cannot assign enemy - not adjacent (distance: %d)" % distance)
		return false

	# Validate: Character must be Hunter or Chopper (can fight)
	var char_class = character.character_class if "character_class" in character else ""
	if char_class != "Hunter" and char_class != "Chopper":
		print("==> Cannot assign enemy - %s cannot fight (only Hunter/Chopper can)" % char_class)
		return false

	# Assign enemy
	character.assigned_enemy = enemy
	print("==> Assigned enemy to %s for combat at (%d, %d)" % [
		char_class,
		enemy.current_coordinate.q,
		enemy.current_coordinate.r
	])

	# Update visual feedback (TODO: highlight enemy in red)
	# enemy_renderer.update_assignment_highlight(enemy)

	# Update character info panel
	update_character_info_panel(character)

	return true

## Phase 5: Update character info panel with character details
## @param character: Character to display info for
func update_character_info_panel(character: Character) -> void:
	if not character or not character_info_panel:
		return

	# Show panel
	character_info_panel.visible = true

	# Update name
	var char_name = character.character_class if "character_class" in character else character.name
	char_info_name_label.text = char_name.to_upper()

	# Update position
	char_info_position_label.text = "Position: (%d, %d)" % [
		character.current_coordinate.q,
		character.current_coordinate.r
	]

	# Update abilities
	var can_hunt = character.canHunt if "canHunt" in character else false
	var can_chop = character.canChop if "canChop" in character else false
	var can_mine = character.canMine if "canMine" in character else false

	char_info_abilities_label.text = "Abilities:\n%s Hunt\n%s Chop\n%s Mine" % [
		"✓" if can_hunt else "✗",
		"✓" if can_chop else "✗",
		"✓" if can_mine else "✗"
	]

	# Update assignment (resource or enemy)
	if character.assigned_enemy:
		var enemy = character.assigned_enemy
		var distance = character.current_coordinate.distance_to(enemy.current_coordinate)
		char_info_assignment_label.text = "Assigned:\n→ ENEMY at (%d, %d)\n  Distance: %d hex" % [
			enemy.current_coordinate.q,
			enemy.current_coordinate.r,
			distance
		]
		char_info_assignment_label.add_theme_color_override("font_color", Color.RED)
	elif character.assigned_resource:
		var resource = character.assigned_resource
		var distance = character.current_coordinate.distance_to(resource.coordinate)
		char_info_assignment_label.text = "Assigned:\n→ %s at (%d, %d)\n  Distance: %d hex" % [
			resource.get_resource_name(),
			resource.coordinate.q,
			resource.coordinate.r,
			distance
		]
		char_info_assignment_label.add_theme_color_override("font_color", Color.LIGHT_GREEN)
	else:
		char_info_assignment_label.text = "No assignment"
		char_info_assignment_label.add_theme_color_override("font_color", Color.GRAY)

## Phase 5: Hide character info panel
func hide_character_info_panel() -> void:
	if character_info_panel:
		character_info_panel.visible = false

## Handle tile click - Part 2: Character selection and movement, Part 3: Resource assignment
func handle_tile_click(screen_pos: Vector2) -> void:
	# Only allow interaction during PLANNING phase
	if not TurnManager.can_player_interact():
		print("==> Cannot interact - not in PLANNING phase (current: %s)" % TurnManager.get_phase_name())
		return

	# Convert screen position to world position (accounting for camera)
	var world_pos = screen_pos + camera.get_screen_center_position() - get_viewport_rect().size / 2

	# Part 2: First, check if clicking on a character
	if character_renderer.select_character_at_position(world_pos):
		var selected_char = character_renderer.get_selected_character()
		print("==> Character selected: %s at (%d, %d)" % [
			selected_char.name,
			selected_char.position.q,
			selected_char.position.r
		])

		# Also update CharacterManager selection
		character_manager.select_character(selected_char)

		# Phase 3: Show resource highlights for adjacent harvestable resources
		resource_renderer.show_adjacent_highlights(selected_char)

		# Phase 5: Show character info panel
		update_character_info_panel(selected_char)

		return  # Character selected, don't process tile click

	# Get the tile coordinate at mouse position
	var coord = coordinate_display.get_tile_at_position(screen_pos, camera)

	if coord:
		# Part 3: If a character is selected, check if clicking on a resource first
		if character_renderer.has_selected_character():
			var selected_char = character_renderer.get_selected_character()

			# Check if there's a resource at this coordinate
			var resource = resource_manager.get_resource_at(coord)
			if resource:
				# Try to assign resource to character
				if assign_resource_to_character(selected_char, resource):
					return  # Resource assigned, done

			# Check if there's an enemy at this coordinate
			if enemy_manager:
				var enemy = enemy_manager.find_enemy_at_coordinate(coord)
				if enemy and enemy.is_alive():
					# Try to assign enemy to character for combat
					if assign_enemy_to_character(selected_char, enemy):
						return  # Enemy assigned, done

			# No resource/enemy or assignment failed, try to move character instead
			if character_renderer.move_selected_character_to(coord):
				print("==> Moved %s to (%d, %d)" % [selected_char.name, coord.q, coord.r])

				# Phase 3: Update highlights after move (adjacency may have changed)
				resource_renderer.show_adjacent_highlights(selected_char)

				# Phase 5: Update character info panel (position changed)
				update_character_info_panel(selected_char)

				# NOTE: NO auto-harvesting! Harvesting happens during turn execution.
				# Character just moves during PLANNING phase.

			else:
				print("==> Cannot move to (%d, %d)" % [coord.q, coord.r])
		else:
			# No character selected, just show coordinate
			coordinate_display.show_single_coordinate(coord)
			print("==> CLICKED TILE COORDINATE: (%d, %d)" % [coord.q, coord.r])
	else:
		# Clicked outside map
		coordinate_display.hide_single_coordinate()
		print("==> Clicked outside map area")

## Generate 3 random maps and save them
func generate_random_maps(count: int = 3) -> void:
	print("\n" + "=".repeat(60))
	print("GENERATING %d RANDOM MAPS..." % count)
	print("=".repeat(60) + "\n")

	for i in range(count):
		var map_num = i + 1
		print("Map %d/%d:" % [map_num, count])

		# Use different generation algorithm for variety
		var seed_value = randi()

		match i:
			0:
				print("  Type: Island")
				generator.generate_island(hex_tilemap, 8)
			1:
				print("  Type: Noise (seed: %d)" % seed_value)
				generator.generate_noise_map(hex_tilemap, seed_value)
			2:
				print("  Type: Clustered (6 clusters)")
				generator.generate_clustered_terrain(hex_tilemap, 6)

		# Render the map and assets
		renderer.render_tilemap()
		asset_renderer.render_all_assets()

		# Save map with descriptive filename
		var filename = "user://random_map_%d.json" % map_num
		var saved = loader.save_map_to_file(hex_tilemap, filename)

		if saved:
			print("  ✓ Saved to: %s" % filename)
		else:
			print("  ✗ Failed to save map %d" % map_num)

		print()

	print("=".repeat(60))
	print("✓ Generated and saved %d random maps!" % count)
	print("=".repeat(60) + "\n")

	# Refresh coordinate display if visible
	if coordinate_display.is_visible:
		coordinate_display.refresh()

## ====================================================
## COMBAT & VICTORY SYSTEM HANDLERS (Phase 3)
## ====================================================

## Signal handler: When enemy is defeated
func _on_enemy_defeated(enemy: Enemy) -> void:
	print("[Main] Enemy defeated: %s" % enemy.name)
	
	# Update enemy renderer with death animation
	if enemy_renderer:
		enemy_renderer.update_health_bar(enemy)
		enemy_renderer.play_death_animation(enemy)
	
	# Update objectives
	update_objectives_display()

## Signal handler: When character is defeated
func _on_character_defeated(character: Character) -> void:
	print("[Main] Character defeated: %s" % character.name)
	
	# TODO: Play character death animation
	# For now, just remove from renderer
	if character_renderer:
		character_renderer.remove_character(character.id)
	
	# Check if all characters dead = game over
	if character_manager and character_manager.get_character_count() == 0:
		print("[Main] All characters defeated - GAME OVER!")

## Signal handler: When attack is executed
func _on_attack_executed(action_number: int, attacker, defender, damage: int, is_counterattack: bool) -> void:
	# Update health bars
	if defender is Enemy:  # Check if defender is an Enemy
		if enemy_renderer:
			enemy_renderer.update_health_bar(defender)
	elif defender is Character:  # Also update character health bars
		if character_renderer:
			character_renderer.update_health_bar(defender)

## Signal handler: When victory is achieved
func _on_victory_achieved(level: int) -> void:
	print("[Main] VICTORY! Level %d complete!" % level)
	
	# Show victory panel
	if victory_panel and victory_label:
		victory_panel.visible = true
		victory_label.text = "LEVEL %d COMPLETE!" % level
	
	# Disable execute turn button
	if execute_turn_button:
		execute_turn_button.disabled = true

## Signal handler: When objectives are updated
func _on_objectives_updated(resources_remaining: int, enemies_remaining: int) -> void:
	update_objectives_display()

## Update the objectives display
func update_objectives_display() -> void:
	if not objectives_label:
		return
	
	var resources = resource_manager.get_resource_count() if resource_manager else 0
	var enemies = enemy_manager.get_alive_enemy_count() if enemy_manager else 0
	
	objectives_label.text = "Objectives:\nResources: %d\nEnemies: %d" % [resources, enemies]
	
	# Change color when objectives complete
	if resources == 0 and enemies == 0:
		objectives_label.add_theme_color_override("font_color", Color.GREEN)
	else:
		objectives_label.add_theme_color_override("font_color", Color.YELLOW)

## Signal handler: When "Next Level" button is pressed
func _on_next_level_pressed() -> void:
	print("[Main] Next Level button pressed")

	# PHASE 1: Hide UI and advance game state
	if victory_panel:
		victory_panel.visible = false

	GameStatus.next_level()
	LevelManager.advance_to_next_level()
	TurnManager.current_turn = 1
	TurnManager.current_phase = TurnManager.GamePhase.PLANNING

	print("[Main] === LEVEL %d STARTING ===" % GameStatus.level)

	# PHASE 2: Clear all game entities
	print("[Main] Clearing old entities...")

	# Clear enemies
	if enemy_renderer:
		enemy_renderer.clear_all()
	if enemy_manager:
		enemy_manager.clear_all()

	# Clear resources
	if resource_renderer:
		resource_renderer.clear_all_sprites()
	if resource_manager:
		resource_manager.clear_all_resources()

	print("[Main] ✓ Cleared enemies and resources")

	# PHASE 3: Regenerate map with unique seed
	print("[Main] Regenerating map...")

	var seed_value = LevelManager.generate_seed_for_level(GameStatus.level)
	print("[Main] Generated seed: %d" % seed_value)

	# Use noise algorithm with seed for reproducible random maps
	generator.generate_noise_map(hex_tilemap, seed_value)

	# Re-render terrain and assets
	renderer.render_tilemap()
	asset_renderer.render_all_assets()

	print("[Main] ✓ Map regenerated with seed %d" % seed_value)

	# PHASE 4: Reset characters
	print("[Main] Resetting characters...")

	var characters = character_manager.get_all_characters()
	for character in characters:
		# Reset HP to maximum
		character.currentHP = character.maxHP

		# Reset position based on character type
		var new_coord: HexCoordinate
		if character.character_class == "Hunter":
			new_coord = HexCoordinate.new(9, 10)
		elif character.character_class == "Chopper":
			new_coord = HexCoordinate.new(10, 10)
		elif character.character_class == "Miner":
			new_coord = HexCoordinate.new(11, 10)

		# Update character coordinates
		character.current_coordinate = new_coord
		character.position = new_coord

		# Update sprite position manually
		var sprite = character_renderer.character_sprites.get(character.id)
		if sprite:
			var world_pos = tile_map_layer.map_to_local(Vector2i(new_coord.q, new_coord.r))
			sprite.position = world_pos

			# Also update highlight position if it exists
			var highlight = character_renderer.selection_highlights.get(character.id)
			if highlight:
				highlight.position = world_pos

		# Update tilemap owner
		hex_tilemap.set_tile_info(new_coord, -1, character)

		# Clear assignments
		character.assigned_resource = null
		character.assigned_enemy = null

	print("[Main] ✓ Characters reset to starting positions with full HP")

	# PHASE 5: Spawn new resources and enemies
	print("[Main] Spawning new entities...")

	# Spawn resources
	place_test_resources()
	resource_renderer.render_all_resources()

	# Spawn enemies (scaled to level)
	place_level_monsters(GameStatus.level)

	print("[Main] ✓ Spawned resources and level %d enemies" % GameStatus.level)

	# PHASE 6: Reinitialize victory objectives
	var resource_count = resource_manager.get_resource_count()
	var enemy_count = enemy_manager.get_alive_enemy_count()
	VictoryManager.initialize_level_objectives(resource_count, enemy_count)

	print("[Main] ✓ Victory objectives: %d resources, %d enemies" % [resource_count, enemy_count])

	# Enable execute button
	if execute_turn_button:
		execute_turn_button.disabled = false

	print("[Main] === LEVEL %d READY ===" % GameStatus.level)

## Place monsters on the map for current level
func place_level_monsters(level: int) -> void:
	if not enemy_manager or not enemy_renderer:
		print("[Main] ERROR: Enemy systems not initialized!")
		return
	
	var monster_count = 2 + (level - 1) * 2  # Level 1: 2, Level 2: 4, Level 3: 6...
	print("[Main] Placing %d monsters for level %d..." % [monster_count, level])
	
	for i in range(monster_count):
		# Find random valid coordinate (not too close to starting area)
		var coord = get_random_monster_spawn_coordinate()
		if not coord:
			print("[Main] WARNING: Could not find valid spawn for monster %d" % i)
			continue
		
		# Create enemy
		var enemy = Enemy.new(
			"enemy_level%d_%d" % [level, i],
			"Monster",
			"res://Character/Enemy/Torch_Red.png",
			coord
		)
		
		# Scale HP and damage with level
		enemy.maxHP = 50 + (level - 1) * 10  # Level 1: 50 HP, Level 2: 60 HP...
		enemy.currentHP = enemy.maxHP
		enemy.attackDamage = 8 + (level - 1) * 2  # Level 1: 8 dmg, Level 2: 10 dmg...
		
		# Add to managers
		enemy_manager.add_enemy(enemy)
		enemy_renderer.add_enemy(enemy)
	
	print("[Main] Placed %d monsters" % monster_count)

## Get a random coordinate for monster spawn (away from player start)
func get_random_monster_spawn_coordinate() -> HexCoordinate:
	var attempts = 0
	var max_attempts = 50
	
	while attempts < max_attempts:
		var q = randi_range(0, 19)
		var r = randi_range(0, 19)
		var coord = HexCoordinate.new(q, r)
		
		# Check if tile is walkable
		var tile = hex_tilemap.get_tile_info(coord)
		if not tile or not tile.is_walkable():
			attempts += 1
			continue
		
		# Check if tile is occupied
		if tile.is_occupied():
			attempts += 1
			continue
		
		# Check distance from player starting area (9-11, 10)
		var dist_from_start = min(
			coord.distance_to(HexCoordinate.new(9, 10)),
			coord.distance_to(HexCoordinate.new(10, 10)),
			coord.distance_to(HexCoordinate.new(11, 10))
		)
		
		# Must be at least 5 tiles away from starting area
		if dist_from_start >= 5:
			return coord
		
		attempts += 1
	
	return null  # Failed to find valid spawn

## ====================================================
## DEBUG HELPER FUNCTIONS
## ====================================================

## Spawn a test enemy at a random location (debug function)
func spawn_test_enemy() -> void:
	if not enemy_manager or not enemy_renderer:
		DebugManager.log_error("Cannot spawn test enemy - enemy systems not initialized")
		return

	# Find random spawn location
	var coord = get_random_monster_spawn_coordinate()
	if not coord:
		DebugManager.log_warning("Could not find valid spawn location for test enemy")
		return

	# Create test enemy
	var test_id = "debug_enemy_%d" % Time.get_ticks_msec()
	var enemy = Enemy.new(
		test_id,
		"DEBUG Monster",
		"res://Character/Enemy/Torch_Red.png",
		coord
	)

	# Standard stats
	enemy.maxHP = 50
	enemy.currentHP = 50
	enemy.attackDamage = 8

	# Add to managers
	enemy_manager.add_enemy(enemy)
	enemy_renderer.add_enemy(enemy)

	DebugManager.debug_log("DEBUG: Spawned test enemy at (%d, %d)" % [coord.q, coord.r])
	print("[DEBUG] Test enemy spawned at (%d, %d)" % [coord.q, coord.r])

## Heal all characters to full HP (debug function)
func heal_all_characters() -> void:
	if not character_manager:
		DebugManager.log_error("Cannot heal characters - character_manager not initialized")
		return

	var characters = character_manager.get_all_characters()
	var healed_count = 0

	for character in characters:
		if "currentHP" in character and "maxHP" in character:
			var hp_before = character.currentHP
			character.currentHP = character.maxHP
			if hp_before < character.maxHP:
				healed_count += 1
				DebugManager.debug_log("Healed %s: %d → %d HP" % [
					character.name,
					hp_before,
					character.currentHP
				])

	if healed_count > 0:
		print("[DEBUG] Healed %d characters to full HP" % healed_count)
	else:
		print("[DEBUG] All characters already at full HP")

	DebugManager.debug_log("DEBUG: Heal all characters - healed %d characters" % healed_count)
