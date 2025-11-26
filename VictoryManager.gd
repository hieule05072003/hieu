extends Node

## VictoryManager - Singleton for tracking level objectives and win conditions
## Checks if player has completed all objectives (resources + enemies)

signal victory_achieved(level: int)
signal objective_updated(resources_remaining: int, enemies_remaining: int)

# Objective tracking for current level
var total_resources_this_level: int = 0
var total_enemies_this_level: int = 0

# Win condition: ALL resources harvested AND ALL enemies defeated
var victory_condition_met: bool = false

const DEBUG_MODE = true
const DEBUG_PREFIX = "[VictoryManager]"


func _ready() -> void:
	_debug_log("VictoryManager initialized")


## Initialize objectives for a new level
## @param resource_count: Total resources on this level
## @param enemy_count: Total enemies on this level
func initialize_level_objectives(resource_count: int, enemy_count: int) -> void:
	total_resources_this_level = resource_count
	total_enemies_this_level = enemy_count
	victory_condition_met = false

	_debug_log("Level objectives set: %d resources, %d enemies" % [resource_count, enemy_count])
	objective_updated.emit(resource_count, enemy_count)


## Check if victory condition is met
## @param resource_manager: Reference to ResourceManager
## @param enemy_manager: Reference to EnemyManager
## @returns: true if ALL resources gone AND ALL enemies dead
func check_victory_condition(resource_manager: ResourceManager, enemy_manager: EnemyManager) -> bool:
	if not resource_manager or not enemy_manager:
		push_error("%s Cannot check victory: missing manager references" % DEBUG_PREFIX)
		return false

	var resources_remaining = resource_manager.get_resource_count()
	var enemies_remaining = enemy_manager.get_alive_enemy_count()

	_debug_log("Checking victory: Resources=%d, Enemies=%d" % [resources_remaining, enemies_remaining])

	# Emit objective update
	objective_updated.emit(resources_remaining, enemies_remaining)

	# Victory condition: both must be zero
	if resources_remaining == 0 and enemies_remaining == 0:
		victory_condition_met = true
		_debug_log("VICTORY CONDITION MET!")
		return true

	return false


## Display victory screen (called by TurnManager)
## @param level: The level that was completed
func display_victory_screen(level: int) -> void:
	_debug_log("=== LEVEL %d COMPLETE ===" % level)
	victory_achieved.emit(level)


## Reset victory state (for new level)
func reset_victory_state() -> void:
	victory_condition_met = false
	_debug_log("Victory state reset")


## Get current objectives remaining
## @param resource_manager: Reference to ResourceManager
## @param enemy_manager: Reference to EnemyManager
## @returns: Dictionary with resources_remaining and enemies_remaining
func get_objectives_remaining(resource_manager: ResourceManager, enemy_manager: EnemyManager) -> Dictionary:
	if not resource_manager or not enemy_manager:
		return {"resources_remaining": 0, "enemies_remaining": 0}

	return {
		"resources_remaining": resource_manager.get_resource_count(),
		"enemies_remaining": enemy_manager.get_alive_enemy_count()
	}


## Check if victory has been achieved
func is_victory_achieved() -> bool:
	return victory_condition_met


## Debug logging
func _debug_log(message: String) -> void:
	if DEBUG_MODE:
		print("%s %s" % [DEBUG_PREFIX, message])
