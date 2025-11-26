## CombatSystem.gd
## Implements the 7-action combat system
## Similar to HarvestingSystem but for combat
## Character attacks enemy, enemy counterattacks each action
##
## Usage:
##   combat_system.execute_single_attack_action(character, enemy)
##   # Call 7 times per turn during EXECUTING phase

class_name CombatSystem
extends Node

## Emitted when combat starts
signal combat_started(character: Character, enemy: Enemy)

## Emitted for each attack action
signal attack_executed(action_number: int, attacker, defender, damage: int, is_counterattack: bool)

## Emitted when all 7 actions complete
signal combat_completed(character: Character, enemy: Enemy)

## Emitted when enemy is defeated
signal enemy_defeated(enemy: Enemy)

## Emitted when character is defeated
signal character_defeated(character: Character)

## Reference to EnemyManager
var enemy_manager: EnemyManager = null

const DEBUG_MODE = true
const DEBUG_PREFIX = "[CombatSystem]"


## Execute a single attack action (called by TurnManager for each of 7 actions)
## @param character: The attacking character
## @param enemy: The target enemy
## @returns: Damage dealt by character this action
func execute_single_attack_action(character: Character, enemy: Enemy) -> int:
	if character == null or enemy == null:
		return 0

	# Validate character can fight
	if not can_character_fight(character):
		_debug_log("%s cannot fight (wrong class)" % character.name)
		return 0

	# Validate adjacency
	var distance = character.current_coordinate.distance_to(enemy.current_coordinate)
	if distance > 1:
		_debug_log("%s too far from enemy (distance: %d)" % [character.name, distance])
		return 0

	# Validate enemy is alive
	if not enemy.is_alive():
		return 0

	# Character attacks enemy
	var damage = character.attackDamage
	var enemy_still_alive = enemy.take_damage(damage)

	_debug_log("%s attacks %s for %d damage (Enemy HP: %d/%d)" % [
		character.name, enemy.name, damage, enemy.currentHP, enemy.maxHP
	])

	# Emit attack signal
	attack_executed.emit(-1, character, enemy, damage, false)

	# Check if enemy died
	if not enemy_still_alive:
		enemy.is_dead = true
		enemy_defeated.emit(enemy)
		_debug_log("Enemy %s defeated!" % enemy.name)

		# Notify enemy manager
		if enemy_manager:
			enemy_manager.handle_enemy_death(enemy)

		return damage

	# Enemy counterattacks (if still alive and character adjacent)
	if enemy.can_attack_character(character):
		var counter_damage = enemy.attackDamage
		var character_still_alive = character.take_damage(counter_damage)

		_debug_log("%s counterattacks %s for %d damage (Character HP: %d/%d)" % [
			enemy.name, character.name, counter_damage, character.currentHP, character.maxHP
		])

		# Emit counterattack signal
		attack_executed.emit(-1, enemy, character, counter_damage, true)

		# Check if character died
		if not character_still_alive:
			character_defeated.emit(character)
			_debug_log("Character %s defeated!" % character.name)

	return damage


## Check if character can fight
## @param character: The character to check
## @returns: true if Hunter or Chopper
func can_character_fight(character: Character) -> bool:
	if not character:
		return false

	# Only Hunter and Chopper can fight (temporary solution)
	if "character_class" in character:
		return character.character_class == "Hunter" or character.character_class == "Chopper"

	return false


## Check if character can attack enemy
## @param character: The attacking character
## @param enemy: The target enemy
## @returns: true if valid attack
func can_character_attack_enemy(character: Character, enemy: Enemy) -> bool:
	if not character or not enemy:
		return false

	# Must be able to fight
	if not can_character_fight(character):
		return false

	# Must be adjacent
	var distance = character.current_coordinate.distance_to(enemy.current_coordinate)
	if distance > 1:
		return false

	# Enemy must be alive
	if not enemy.is_alive():
		return false

	return true


## Debug logging
func _debug_log(message: String) -> void:
	if DEBUG_MODE:
		print("%s %s" % [DEBUG_PREFIX, message])
