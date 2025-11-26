class_name Character
extends RefCounted

## Represents a character (player or NPC) in the game
## Stores character data including position, sprite, attributes, and abilities
## Part 2: Added HP system, harvesting abilities, and work stats

## Unique identifier for this character
var id: String

## Display name
var name: String

## Path to the character sprite (PNG file)
var sprite_path: String

## Current position on the hex grid
var current_coordinate: HexCoordinate

## Alias for current_coordinate (for consistency with other code)
var position: HexCoordinate:
	get:
		return current_coordinate
	set(value):
		current_coordinate = value

## Character type (for future use: player, enemy, neutral)
enum CharacterType {
	PLAYER,
	ENEMY,
	NEUTRAL
}
var character_type: CharacterType = CharacterType.PLAYER

## Specialized character class (Hunter, Chopper, Miner, Allrounder)
var character_class: String = "Allrounder"

## Assigned resource for this turn (set during planning phase)
var assigned_resource = null

## Assigned enemy for combat this turn (set during planning phase)
var assigned_enemy = null

## === Part 2: Character Attributes ===

## Current hit points
var currentHP: int = 100

## Maximum hit points
var maxHP: int = 100

## Ability: Can this character hunt animals (Sheep)?
var canHunt: bool = false

## Ability: Can this character chop trees for wood?
var canChop: bool = false

## Ability: Can this character mine rocks and gold deposits?
var canMine: bool = false

## How much work this character does per action (affects harvest amount)
var workPerAction: int = 1

## Attack damage (for future combat system)
var attackDamage: int = 10

## Interaction range (how far can character harvest/attack)
var range: int = 1

## Constructor
func _init(p_id: String, p_name: String, p_sprite_path: String, p_coordinate: HexCoordinate, p_type: CharacterType = CharacterType.PLAYER) -> void:
	id = p_id
	name = p_name
	sprite_path = p_sprite_path
	current_coordinate = p_coordinate
	character_type = p_type

## Move character to a new coordinate
func move_to(new_coordinate: HexCoordinate) -> void:
	current_coordinate = new_coordinate

## Get character type as string
func get_type_name() -> String:
	return CharacterType.keys()[character_type]

## Convert to string for debugging
func _to_string() -> String:
	return "Character[ID: %s, Name: %s, Type: %s, Position: %s, HP: %d/%d]" % [id, name, get_type_name(), current_coordinate, currentHP, maxHP]

## === Part 2: Character Methods ===

## Check if character can harvest a specific resource type
## @param resource: The ResourceStatus to check
## @returns: true if character has the required ability
func can_harvest_resource(resource: ResourceStatus) -> bool:
	var required_ability = resource.get_required_ability()

	match required_ability:
		"canHunt":
			return canHunt
		"canChop":
			return canChop
		"canMine":
			return canMine

	return false

## Take damage and reduce HP
## @param damage: Amount of HP to reduce
## @returns: true if character is still alive
func take_damage(damage: int) -> bool:
	currentHP = max(0, currentHP - damage)
	return is_alive()

## Heal the character
## @param amount: HP to restore
func heal(amount: int) -> void:
	currentHP = min(maxHP, currentHP + amount)

## Check if character is alive
## @returns: true if HP > 0
func is_alive() -> bool:
	return currentHP > 0

## Check if character is at full health
## @returns: true if HP equals maxHP
func is_full_health() -> bool:
	return currentHP >= maxHP

## Get HP as a percentage (0.0 to 1.0)
## @returns: Float representing HP percentage
func get_hp_percentage() -> float:
	if maxHP <= 0:
		return 0.0
	return float(currentHP) / float(maxHP)

## Set character abilities (helper for creating different character types)
## @param hunt: Can hunt animals
## @param chop: Can chop trees
## @param mine: Can mine rocks/gold
func set_abilities(hunt: bool, chop: bool, mine: bool) -> void:
	canHunt = hunt
	canChop = chop
	canMine = mine

## Set character stats (helper for configuring character)
## @param hp: Maximum HP
## @param attack: Attack damage
## @param work: Work per action
## @param interaction_range: Interaction range
func set_stats(hp: int, attack: int, work: int, interaction_range: int) -> void:
	maxHP = hp
	currentHP = hp
	attackDamage = attack
	workPerAction = work
	range = interaction_range
