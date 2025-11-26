## HarvestingSystem.gd
## Implements the 7-action harvesting system.
## When a character reaches a resource tile, this system executes 7 harvesting actions.
## Each action harvests the resource and adds yields to GameStatus.
## After all 7 actions complete, the resource is removed from the map.
##
## NOTE: HP is NOT used for harvesting - it's reserved for combat mechanics (future feature)
##       All harvesting operations ignore HP and always complete 7 full actions.
##
## Usage:
##   harvesting_system.execute_harvest_actions(character, resource)
##   # Connect to signals for visual feedback
##   harvesting_system.action_executed.connect(_on_harvest_action)
##
## Signals:
##   harvesting_started(character, resource) - Emitted when harvesting begins
##   action_executed(action_number, character, resource, yields, total_yields) - Emitted for each action (includes running totals)
##   harvesting_completed(character, resource, total_yields) - Emitted when all actions done
##   resource_depleted(resource) - Emitted when resource is removed after harvesting
##
## Note: Harvesting actions now have 0.3s delays between them for UI visibility

extends Node
class_name HarvestingSystem

## Emitted when harvesting sequence starts
signal harvesting_started(character: Character, resource: ResourceStatus)

## Emitted for each harvesting action
signal action_executed(action_number: int, character: Character, resource: ResourceStatus, yields: Dictionary, total_yields: Dictionary)

## Emitted when all 7 actions are complete
signal harvesting_completed(character: Character, resource: ResourceStatus, total_yields: Dictionary)

## Emitted when resource is depleted during harvesting
signal resource_depleted(resource: ResourceStatus)

## Number of actions to execute per harvest
const ACTIONS_PER_HARVEST: int = 7

## Reference to ResourceManager (set externally)
var resource_manager: ResourceManager = null

## Execute 7 harvesting actions for a character on a resource
## @param character: The character doing the harvesting
## @param resource: The resource being harvested
## @returns: Dictionary with total yields {food, wood, gold}
func execute_harvest_actions(character: Character, resource: ResourceStatus) -> Dictionary:
	# Validate inputs
	if character == null or resource == null:
		push_error("Cannot execute harvest: character or resource is null")
		return {"food": 0, "wood": 0, "gold": 0}

	# Check if character can harvest this resource
	if not character.can_harvest_resource(resource):
		push_warning("%s cannot harvest %s (missing required ability)" % [character.name, resource.get_resource_name()])
		return {"food": 0, "wood": 0, "gold": 0}

	# Track total yields across all actions
	var total_yields = {"food": 0, "wood": 0, "gold": 0}

	# Emit start signal
	harvesting_started.emit(character, resource)
	print("\n====================================")
	print("=== HARVESTING STARTED ===")
	print("Character: %s (Work/Action: %d)" % [character.name, character.workPerAction])
	print("Resource: %s at position (%d, %d)" % [resource.get_resource_name(), resource.coordinate.q, resource.coordinate.r])
	print("Actions to execute: %d" % ACTIONS_PER_HARVEST)
	print("====================================\n")

	# Execute ALL 7 actions (HP is ignored for harvesting)
	for action_num in range(1, ACTIONS_PER_HARVEST + 1):
		# Perform harvest
		var yields = _perform_single_harvest_action(action_num, character, resource)

		# Add to totals
		total_yields["food"] += yields["food"]
		total_yields["wood"] += yields["wood"]
		total_yields["gold"] += yields["gold"]

		# Emit action signal with running totals
		action_executed.emit(action_num, character, resource, yields, total_yields)

		# Add 0.3 second delay between actions for UI visibility
		await get_tree().create_timer(0.3).timeout

	# Add total yields to GameStatus
	var game_status = get_node_or_null("/root/GameStatus")
	if game_status != null:
		game_status.add_resources(total_yields)
		print("\n--- Resources added to GameStatus ---")
		print("Food: +%d" % total_yields["food"])
		print("Wood: +%d" % total_yields["wood"])
		print("Gold: +%d" % total_yields["gold"])

	# ALWAYS remove resource after 7 actions complete
	if resource_manager != null:
		resource_manager.remove_resource(resource.coordinate)
		print("\n[RESOURCE REMOVED] %s at (%d, %d) has been depleted and removed from map" %
			  [resource.get_resource_name(), resource.coordinate.q, resource.coordinate.r])
		resource_depleted.emit(resource)

	# Emit completion signal
	harvesting_completed.emit(character, resource, total_yields)
	print("\n====================================")
	print("=== HARVESTING COMPLETED ===")
	print("Total yields: Food +%d, Wood +%d, Gold +%d" % [total_yields["food"], total_yields["wood"], total_yields["gold"]])
	print("====================================\n")

	return total_yields

## Perform a single harvesting action
## @param action_num: Current action number (1-7)
## @param character: Character performing the harvest
## @param resource: Resource being harvested
## @returns: Dictionary with yields from this action {food, wood, gold}
func _perform_single_harvest_action(action_num: int, character: Character, resource: ResourceStatus) -> Dictionary:
	# Harvest using character's work amount
	# NOTE: resource.harvest() still reduces HP internally, but we ignore HP for harvesting logic
	var yields = resource.harvest(character.workPerAction)

	# Build yield string for logging
	var yield_parts = []
	if yields["food"] > 0:
		yield_parts.append("Food +%d" % yields["food"])
	if yields["wood"] > 0:
		yield_parts.append("Wood +%d" % yields["wood"])
	if yields["gold"] > 0:
		yield_parts.append("Gold +%d" % yields["gold"])

	var yield_str = ", ".join(yield_parts) if yield_parts.size() > 0 else "No yield"

	# Log action with detailed info
	print("  [Action %d/%d] Yields: %s | Work applied: %d" %
		  [action_num, ACTIONS_PER_HARVEST, yield_str, character.workPerAction])

	return yields

## Quick harvest (non-animated) - immediately executes all 7 actions
## This is the default behavior for Part 2
## @param character: Character harvesting
## @param resource: Resource being harvested
## @returns: Total yields
func quick_harvest(character: Character, resource: ResourceStatus) -> Dictionary:
	return await execute_harvest_actions(character, resource)

## Animated harvest (for future use) - executes actions with delays
## This can be implemented later for visual feedback
## @param character: Character harvesting
## @param resource: Resource being harvested
## @param delay_between_actions: Seconds between each action
func animated_harvest(character: Character, resource: ResourceStatus, delay_between_actions: float = 0.3) -> void:
	# TODO: Implement tween-based animation for future visual polish
	# For now, just call quick_harvest
	quick_harvest(character, resource)

## Check if a character can harvest at their current position
## @param character: Character to check
## @returns: ResourceStatus if harvestable resource present, null otherwise
func get_harvestable_resource_at_position(character: Character) -> ResourceStatus:
	if resource_manager == null:
		return null

	var resource = resource_manager.get_resource_at(character.current_coordinate)
	if resource != null and character.can_harvest_resource(resource):
		return resource

	return null

## Check if harvesting should auto-trigger for a character
## @param character: Character that just moved
## @returns: true if harvesting should begin
func should_auto_harvest(character: Character) -> bool:
	return get_harvestable_resource_at_position(character) != null

## Execute a SINGLE harvest action (for turn-based system)
## Called by TurnManager for each of the 7 actions
## @param character: Character performing the harvest
## @param resource: Resource being harvested
## @returns: Total yield from this single action
func execute_single_harvest_action(character: Character, resource: ResourceStatus) -> int:
	const DEBUG_PREFIX = "[HarvestingSystem]"

	# Validate inputs
	if character == null or resource == null:
		push_error("%s Cannot execute harvest: character or resource is null" % DEBUG_PREFIX)
		return 0

	# Phase 3: Validate adjacency - resource must be adjacent to character
	var distance = character.current_coordinate.distance_to(resource.coordinate)
	if distance > 1:
		var char_name = character.character_class if "character_class" in character else character.name
		push_warning("%s %s cannot harvest %s at (%d, %d) - not adjacent (distance: %d)" % [
			DEBUG_PREFIX,
			char_name,
			resource.get_resource_name(),
			resource.coordinate.q,
			resource.coordinate.r,
			distance
		])
		return 0

	# Check if character can harvest this resource
	if not character.can_harvest_resource(resource):
		var char_name = character.character_class if "character_class" in character else character.name
		push_warning("%s %s cannot harvest %s (missing required ability)" % [
			DEBUG_PREFIX,
			char_name,
			resource.get_resource_name()
		])
		return 0

	# Perform harvest
	var yields = resource.harvest(character.workPerAction)

	# Calculate total yield (sum of all resources)
	var total_yield = yields["food"] + yields["wood"] + yields["gold"]

	# Add to GameStatus
	var game_status = get_node_or_null("/root/GameStatus")
	if game_status != null:
		game_status.add_resources(yields)

	# Decrease actions remaining
	if "actions_remaining" in resource:
		resource.actions_remaining -= 1
	else:
		# Add actions_remaining if it doesn't exist (for new system)
		resource.actions_remaining = 6  # 7 total, minus this action = 6 remaining

	# Check if resource should be depleted
	if resource.actions_remaining <= 0:
		print("%s Resource %s depleted!" % [DEBUG_PREFIX, resource.get_resource_name()])
		resource.exists = false  # Mark as no longer existing

		# Remove from map
		if resource_manager != null:
			resource_manager.remove_resource(resource.coordinate)
			resource_depleted.emit(resource)

	return total_yield
