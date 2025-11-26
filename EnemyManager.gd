## EnemyManager.gd
## Manages all enemies in the game
## Tracks enemy creation, removal, and state
## Similar to CharacterManager but for enemies
##
## Usage:
##   enemy_manager.add_enemy(enemy)
##   var all_enemies = enemy_manager.get_all_enemies()
##   var alive = enemy_manager.get_alive_enemies()

class_name EnemyManager
extends Node

## Emitted when an enemy is added to the manager
signal enemy_added(enemy: Enemy)

## Emitted when an enemy is removed from the manager
signal enemy_removed(enemy: Enemy)

## Emitted when an enemy dies
signal enemy_died(enemy: Enemy)

## Array of all enemies in the game
var enemies: Array[Enemy] = []

## Currently selected enemy (for debugging/UI)
var selected_enemy: Enemy = null

const DEBUG_MODE = true
const DEBUG_PREFIX = "[EnemyManager]"


## Add an enemy to the manager
## @param enemy: The Enemy instance to add
func add_enemy(enemy: Enemy) -> void:
	if enemy == null:
		push_error("%s Cannot add null enemy" % DEBUG_PREFIX)
		return

	if enemies.has(enemy):
		push_warning("%s Enemy %s already exists in manager" % [DEBUG_PREFIX, enemy.id])
		return

	enemies.append(enemy)
	enemy_added.emit(enemy)
	_debug_log("Added enemy: %s" % enemy.to_string())


## Remove an enemy from the manager
## @param enemy: The Enemy instance to remove
func remove_enemy(enemy: Enemy) -> void:
	if enemy == null:
		push_error("%s Cannot remove null enemy" % DEBUG_PREFIX)
		return

	var index = enemies.find(enemy)
	if index != -1:
		enemies.remove_at(index)
		enemy_removed.emit(enemy)
		_debug_log("Removed enemy: %s" % enemy.id)
	else:
		push_warning("%s Enemy %s not found in manager" % [DEBUG_PREFIX, enemy.id])


## Handle enemy death (marks as dead and emits signal)
## @param enemy: The enemy that died
func handle_enemy_death(enemy: Enemy) -> void:
	if enemy == null:
		return

	if not enemy.is_dead:
		enemy.is_dead = true
		enemy_died.emit(enemy)
		_debug_log("Enemy died: %s" % enemy.id)


## Get all enemies (alive and dead)
## @returns: Array of all enemies
func get_all_enemies() -> Array[Enemy]:
	return enemies.duplicate()


## Get only alive enemies
## @returns: Array of alive enemies
func get_alive_enemies() -> Array[Enemy]:
	var alive: Array[Enemy] = []
	for enemy in enemies:
		if enemy.is_alive():
			alive.append(enemy)
	return alive


## Get total enemy count (including dead)
## @returns: Number of all enemies
func get_enemy_count() -> int:
	return enemies.size()


## Get alive enemy count
## @returns: Number of alive enemies
func get_alive_enemy_count() -> int:
	var count = 0
	for enemy in enemies:
		if enemy.is_alive():
			count += 1
	return count


## Find enemy by ID
## @param enemy_id: The ID to search for
## @returns: Enemy instance or null if not found
func find_enemy_by_id(enemy_id: String) -> Enemy:
	for enemy in enemies:
		if enemy.id == enemy_id:
			return enemy
	return null


## Find enemy at specific coordinate
## @param coordinate: The HexCoordinate to check
## @returns: Enemy at that position or null
func find_enemy_at_coordinate(coordinate: HexCoordinate) -> Enemy:
	for enemy in enemies:
		if enemy.current_coordinate.equals(coordinate):
			return enemy
	return null


## Clear all enemies (for level transitions)
func clear_all() -> void:
	var count = enemies.size()
	enemies.clear()
	_debug_log("Cleared all enemies (%d removed)" % count)


## Select an enemy (for UI/debugging)
## @param enemy: The enemy to select
func select_enemy(enemy: Enemy) -> void:
	selected_enemy = enemy
	_debug_log("Selected enemy: %s" % (enemy.id if enemy else "none"))


## Deselect current enemy
func deselect_enemy() -> void:
	selected_enemy = null
	_debug_log("Deselected enemy")


## Get currently selected enemy
## @returns: Selected enemy or null
func get_selected_enemy() -> Enemy:
	return selected_enemy


## Check if an enemy is selected
## @returns: true if an enemy is selected
func has_selected_enemy() -> bool:
	return selected_enemy != null


## Debug logging
func _debug_log(message: String) -> void:
	if DEBUG_MODE:
		print("%s %s" % [DEBUG_PREFIX, message])


## Print all enemies (for debugging)
func print_enemies() -> void:
	print("=== Enemy List ===")
	print("Total enemies: %d" % enemies.size())
	print("Alive enemies: %d" % get_alive_enemy_count())
	for enemy in enemies:
		var status = "ALIVE" if enemy.is_alive() else "DEAD"
		print("  [%s] %s" % [status, enemy.to_string()])
