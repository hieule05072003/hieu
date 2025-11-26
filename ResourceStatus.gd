## ResourceStatus.gd
## Defines harvestable resources that can be placed on the hex tilemap.
## Each resource has HP, yields (Food/Wood/Gold), and requires specific character abilities to harvest.
##
## IMPORTANT: HP is ONLY used for combat mechanics (future feature).
##            For harvesting (hunt, chop, mine), HP is IGNORED - resources are always harvested
##            for a full 7 actions and then removed from the map.
##            The harvest() method still reduces HP internally, but harvesting logic doesn't check it.
##
## Usage:
##   var tree = ResourceStatus.new(ResourceStatus.ResourceType.TREE, tree_coord, 20)
##   var yields = tree.harvest(5)  # Harvest with 5 work (HP reduced but not checked)
##   # After 7 harvest actions, HarvestingSystem removes the resource regardless of HP

extends Resource
class_name ResourceStatus

## Enum defining all harvestable resource types in the game
enum ResourceType {
	TREE,          ## Requires canChop, yields Wood
	ROCK,          ## Requires canMine, yields Gold
	SHEEP,         ## Requires canHunt, yields Food
	GOLD_DEPOSIT   ## Requires canMine, yields Gold (more than rocks)
}

## The type of this resource
var resource_type: ResourceType

## Current hit points of the resource
## NOTE: Only used for combat (future). Ignored by harvesting system.
var currentHP: int

## Maximum hit points of the resource
## NOTE: Only used for combat (future). Ignored by harvesting system.
var maxHP: int

## Position of the resource on the hex grid
var coordinate: HexCoordinate

## Alias for coordinate (for consistency)
var position: HexCoordinate:
	get:
		return coordinate
	set(value):
		coordinate = value

## Number of actions remaining until resource is depleted (for turn-based system)
var actions_remaining: int = 7

## Whether this resource still exists (not depleted)
var exists: bool = true

## Food yield per work unit
var yield_food: int = 0

## Wood yield per work unit
var yield_wood: int = 0

## Gold yield per work unit
var yield_gold: int = 0

## Constructor - Creates a new resource with default yields based on type
## @param type: The ResourceType to create
## @param coord: Position on the hex grid
## @param hp: Maximum HP for this resource (default varies by type)
func _init(type: ResourceType, coord: HexCoordinate, hp: int = -1) -> void:
	resource_type = type
	coordinate = coord

	# Set default HP and yields based on resource type
	match resource_type:
		ResourceType.TREE:
			maxHP = 20 if hp == -1 else hp
			yield_wood = 5

		ResourceType.ROCK:
			maxHP = 30 if hp == -1 else hp
			yield_gold = 3

		ResourceType.SHEEP:
			maxHP = 10 if hp == -1 else hp
			yield_food = 8

		ResourceType.GOLD_DEPOSIT:
			maxHP = 40 if hp == -1 else hp
			yield_gold = 7

	currentHP = maxHP

## Harvest this resource with the given work amount
## Reduces HP and returns the yields gained
##
## NOTE: HP reduction here is for internal tracking only (future combat use).
##       HarvestingSystem IGNORES HP and always executes 7 full actions.
##       This method is called 7 times per harvest, then the resource is removed.
##
## @param work_amount: How much work to apply (typically character's workPerAction)
## @returns: Dictionary with keys {food, wood, gold}
func harvest(work_amount: int) -> Dictionary:
	if is_depleted():
		return {"food": 0, "wood": 0, "gold": 0}

	# Calculate actual work done (can't exceed remaining HP)
	var actual_work = min(work_amount, currentHP)

	# Reduce HP (for future combat mechanics, not used by harvesting system)
	currentHP -= actual_work

	# Calculate yields (work_amount determines how many yields)
	var yields = {
		"food": yield_food * actual_work,
		"wood": yield_wood * actual_work,
		"gold": yield_gold * actual_work
	}

	return yields

## Check if this resource is depleted (HP <= 0)
## NOTE: Only relevant for combat (future). Harvesting system ignores this.
## @returns: true if HP is depleted (for combat mechanics)
func is_depleted() -> bool:
	return currentHP <= 0

## Get the ability required to harvest this resource
## @returns: String representing the required ability ("canChop", "canHunt", or "canMine")
func get_required_ability() -> String:
	match resource_type:
		ResourceType.TREE:
			return "canChop"
		ResourceType.ROCK:
			return "canMine"
		ResourceType.SHEEP:
			return "canHunt"
		ResourceType.GOLD_DEPOSIT:
			return "canMine"
	return ""

## Get a human-readable name for this resource type
## @returns: Display name for UI/debug purposes
func get_resource_name() -> String:
	match resource_type:
		ResourceType.TREE:
			return "Tree"
		ResourceType.ROCK:
			return "Rock"
		ResourceType.SHEEP:
			return "Sheep"
		ResourceType.GOLD_DEPOSIT:
			return "Gold Deposit"
	return "Unknown"

## Get HP percentage (for UI display)
## @returns: Float between 0.0 and 1.0
func get_hp_percentage() -> float:
	if maxHP <= 0:
		return 0.0
	return float(currentHP) / float(maxHP)

## String representation for debugging
func _to_string() -> String:
	return "%s at %s (HP: %d/%d)" % [get_resource_name(), coordinate, currentHP, maxHP]
