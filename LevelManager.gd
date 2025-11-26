extends Node

## LevelManager - Singleton for managing level progression and map generation
## Tracks current level, generates unique seeds, and ensures no duplicate maps

signal level_changed(new_level: int)
signal level_started(level: int)

# Current level number (1-based)
var current_level: int = 1

# Track all seeds used to ensure uniqueness
var used_seeds: Array[int] = []

# Track which algorithm was used for each level
var level_algorithms: Array[String] = []

# Random number generator for seed creation
var rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Available map generation algorithms
const ALGORITHMS = ["island", "noise", "clustered", "random"]

# Debug mode
const DEBUG_MODE = true
const DEBUG_PREFIX = "[LevelManager]"


func _ready() -> void:
	rng.randomize()
	_debug_log("LevelManager initialized")
	_debug_log("Starting at level %d" % current_level)


## Generate a unique seed for the given level
## Formula: (level * 1000000) + (timestamp % 1000000) + random(0-99999)
## This ensures different seeds even for the same level number across playthroughs
func generate_seed_for_level(level: int) -> int:
	var base_seed = level * 1000000
	var time_component = Time.get_ticks_msec() % 1000000
	var random_component = rng.randi_range(0, 99999)

	var seed_value = base_seed + time_component + random_component

	# Ensure uniqueness (extremely unlikely to collide, but check anyway)
	var attempts = 0
	while used_seeds.has(seed_value) and attempts < 100:
		random_component = rng.randi_range(0, 99999)
		seed_value = base_seed + time_component + random_component
		attempts += 1

	# Store the seed
	used_seeds.append(seed_value)

	_debug_log("Generated seed %d for level %d (attempt %d)" % [seed_value, level, attempts + 1])
	return seed_value


## Get the algorithm to use for the given level
## Rotates through algorithms to ensure variety
func get_algorithm_for_level(level: int) -> String:
	var index = (level - 1) % ALGORITHMS.size()
	var algorithm = ALGORITHMS[index]

	_debug_log("Level %d will use '%s' algorithm" % [level, algorithm])
	return algorithm


## Check if a seed has been used before
func is_seed_used(seed: int) -> bool:
	return used_seeds.has(seed)


## Advance to the next level
func advance_to_next_level() -> void:
	current_level += 1
	_debug_log("Advanced to level %d" % current_level)
	level_changed.emit(current_level)


## Start a new level (called when level begins)
func start_level(level: int) -> void:
	current_level = level
	_debug_log("=== LEVEL %d STARTED ===" % level)
	level_started.emit(level)


## Reset to level 1 (for new game)
func reset_to_level_one() -> void:
	current_level = 1
	used_seeds.clear()
	level_algorithms.clear()
	_debug_log("Reset to level 1")


## Save level progress to file
func save_level_progress() -> void:
	var save_data = {
		"current_level": current_level,
		"used_seeds": used_seeds,
		"level_algorithms": level_algorithms,
		"timestamp": Time.get_datetime_string_from_system()
	}

	var save_file = FileAccess.open("user://level_progress.json", FileAccess.WRITE)
	if save_file:
		save_file.store_string(JSON.stringify(save_data, "\t"))
		save_file.close()
		_debug_log("Level progress saved (level %d)" % current_level)
	else:
		push_error("%s Failed to save level progress" % DEBUG_PREFIX)


## Load level progress from file
func load_level_progress() -> bool:
	if not FileAccess.file_exists("user://level_progress.json"):
		_debug_log("No saved progress found")
		return false

	var save_file = FileAccess.open("user://level_progress.json", FileAccess.READ)
	if not save_file:
		push_error("%s Failed to open save file" % DEBUG_PREFIX)
		return false

	var json_string = save_file.get_as_text()
	save_file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("%s Failed to parse save file" % DEBUG_PREFIX)
		return false

	var save_data = json.data

	current_level = save_data.get("current_level", 1)
	used_seeds = save_data.get("used_seeds", [])
	level_algorithms = save_data.get("level_algorithms", [])

	_debug_log("Level progress loaded: level %d" % current_level)
	return true


## Get current level number
func get_current_level() -> int:
	return current_level


## Get total number of seeds generated (levels played)
func get_total_levels_played() -> int:
	return used_seeds.size()


## Debug logging
func _debug_log(message: String) -> void:
	if DEBUG_MODE:
		print("%s %s" % [DEBUG_PREFIX, message])
