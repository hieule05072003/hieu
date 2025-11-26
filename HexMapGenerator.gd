class_name HexMapGenerator
extends Node

## Procedural terrain generation for HexTilemap
## Provides various generation algorithms for creating interesting maps

## Random number generator
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Noise generator for procedural generation
var noise: FastNoiseLite = FastNoiseLite.new()

func _init() -> void:
	# Setup noise with good defaults
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	noise.fractal_octaves = 3

## Generate a completely random map
## @param tilemap: The HexTilemap to generate into
## @param seed_value: Seed for reproducible generation (-1 for random)
func generate_random_map(tilemap: HexTilemap, seed_value: int = -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

	print("Generating random map with seed: %d" % rng.seed)

	# Generate random terrain for each tile
	for tile in tilemap.get_all_tiles():
		var terrain = _get_random_terrain()
		tilemap.set_tile_info(tile.coordinate, terrain)

	print("✓ Random map generation complete")

## Generate a map using Perlin noise for natural-looking terrain
## @param tilemap: The HexTilemap to generate into
## @param seed_value: Seed for reproducible generation (-1 for random)
func generate_noise_map(tilemap: HexTilemap, seed_value: int = -1) -> void:
	if seed_value >= 0:
		noise.seed = seed_value
	else:
		noise.seed = randi()

	print("Generating noise-based map with seed: %d" % noise.seed)

	# Use noise to determine terrain types
	for tile in tilemap.get_all_tiles():
		var coord = tile.coordinate
		var noise_value = noise.get_noise_2d(float(coord.q), float(coord.r))

		# Map noise value (-1 to 1) to terrain types
		var terrain = _noise_to_terrain(noise_value)
		tilemap.set_tile_info(coord, terrain)

	print("✓ Noise map generation complete")

## Generate an island-style map with water borders
## @param tilemap: The HexTilemap to generate into
## @param island_radius: Size of the island (default: 7)
func generate_island(tilemap: HexTilemap, island_radius: int = 7) -> void:
	print("Generating island map with radius: %d" % island_radius)

	var center_q = tilemap.width / 2
	var center_r = tilemap.height / 2
	var center = HexCoordinate.new(center_q, center_r)

	for tile in tilemap.get_all_tiles():
		var coord = tile.coordinate
		var distance = coord.distance_to(center)

		var terrain: HexTile.TerrainType

		if distance > island_radius:
			# Water around the edges
			terrain = HexTile.TerrainType.WATER
		elif distance > island_radius - 2:
			# Sand beach
			terrain = HexTile.TerrainType.SAND
		else:
			# Mix of grass, forest, hills in the interior
			var rand_val = rng.randf()
			if rand_val < 0.4:
				terrain = HexTile.TerrainType.GRASS
			elif rand_val < 0.7:
				terrain = HexTile.TerrainType.FOREST
			elif rand_val < 0.85:
				terrain = HexTile.TerrainType.HILL
			else:
				terrain = HexTile.TerrainType.MOUNTAIN

		tilemap.set_tile_info(coord, terrain)

	print("✓ Island generation complete")

## Generate terrain clusters (grouped terrain types)
## @param tilemap: The HexTilemap to generate into
## @param cluster_count: Number of terrain clusters to create
func generate_clustered_terrain(tilemap: HexTilemap, cluster_count: int = 5) -> void:
	print("Generating clustered terrain with %d clusters" % cluster_count)

	# Start with all empty
	for tile in tilemap.get_all_tiles():
		tilemap.set_tile_info(tile.coordinate, HexTile.TerrainType.GRASS)

	# Create clusters
	for i in range(cluster_count):
		var cluster_center_q = rng.randi_range(0, tilemap.width - 1)
		var cluster_center_r = rng.randi_range(0, tilemap.height - 1)
		var cluster_center = HexCoordinate.new(cluster_center_q, cluster_center_r)

		var cluster_terrain = _get_random_terrain()
		var cluster_size = rng.randi_range(2, 5)

		# Fill cluster area
		var tiles_in_range = HexGridCalculations.get_coordinates_in_range(cluster_center, cluster_size)

		for coord in tiles_in_range:
			if tilemap.is_valid_coordinate(coord):
				# Random chance to place terrain (creates irregular shapes)
				if rng.randf() < 0.7:
					tilemap.set_tile_info(coord, cluster_terrain)

	print("✓ Clustered terrain generation complete")

## Generate from a seed (wraps generate_noise_map for convenience)
## @param tilemap: The HexTilemap to generate into
## @param seed_value: Seed for reproducible generation
func generate_from_seed(tilemap: HexTilemap, seed_value: int) -> void:
	generate_noise_map(tilemap, seed_value)

## Generate a simple checkerboard pattern (useful for testing)
## @param tilemap: The HexTilemap to generate into
func generate_checkerboard(tilemap: HexTilemap) -> void:
	print("Generating checkerboard pattern")

	for tile in tilemap.get_all_tiles():
		var coord = tile.coordinate
		var terrain: HexTile.TerrainType

		if (coord.q + coord.r) % 2 == 0:
			terrain = HexTile.TerrainType.GRASS
		else:
			terrain = HexTile.TerrainType.STONE

		tilemap.set_tile_info(coord, terrain)

	print("✓ Checkerboard generation complete")

## Generate a test pattern with all terrain types visible
## @param tilemap: The HexTilemap to generate into
func generate_test_pattern(tilemap: HexTilemap) -> void:
	print("Generating test pattern with all terrain types")

	var terrain_types = [
		HexTile.TerrainType.EMPTY,
		HexTile.TerrainType.GRASS,
		HexTile.TerrainType.FLOWER,
		HexTile.TerrainType.HILL,
		HexTile.TerrainType.MOUNTAIN,
		HexTile.TerrainType.WATER,
		HexTile.TerrainType.FOREST,
		HexTile.TerrainType.SAND,
		HexTile.TerrainType.ICE,
		HexTile.TerrainType.STONE
	]

	var terrain_index = 0

	for tile in tilemap.get_all_tiles():
		var terrain = terrain_types[terrain_index % terrain_types.size()]
		tilemap.set_tile_info(tile.coordinate, terrain)
		terrain_index += 1

	print("✓ Test pattern generation complete")

## Internal: Get a random terrain type
func _get_random_terrain() -> HexTile.TerrainType:
	var terrains = [
		HexTile.TerrainType.GRASS,
		HexTile.TerrainType.FOREST,
		HexTile.TerrainType.WATER,
		HexTile.TerrainType.SAND,
		HexTile.TerrainType.HILL,
		HexTile.TerrainType.MOUNTAIN,
		HexTile.TerrainType.ICE,
		HexTile.TerrainType.STONE,
		HexTile.TerrainType.FLOWER,
	]
	return terrains[rng.randi() % terrains.size()]

## Internal: Convert noise value to terrain type
func _noise_to_terrain(noise_value: float) -> HexTile.TerrainType:
	# Map noise range (-1 to 1) to terrain types
	if noise_value < -0.4:
		return HexTile.TerrainType.WATER
	elif noise_value < -0.2:
		return HexTile.TerrainType.SAND
	elif noise_value < 0.1:
		return HexTile.TerrainType.GRASS
	elif noise_value < 0.3:
		return HexTile.TerrainType.FOREST
	elif noise_value < 0.5:
		return HexTile.TerrainType.HILL
	elif noise_value < 0.7:
		return HexTile.TerrainType.MOUNTAIN
	else:
		return HexTile.TerrainType.ICE

## Set custom noise parameters
func set_noise_params(frequency: float, octaves: int) -> void:
	noise.frequency = frequency
	noise.fractal_octaves = octaves
