## GameStatus.gd
## Global singleton that tracks player resources and game state.
## This should be configured as an AutoLoad in Project Settings.
##
## Usage (from any script):
##   GameStatus.add_food(50)
##   GameStatus.add_wood(20)
##   if GameStatus.can_afford_food(10):
##       GameStatus.subtract_food(10)
##   print("Gold: ", GameStatus.gold)
##
## Signals:
##   resources_changed(food, wood, gold) - Emitted when any resource value changes
##   level_changed(new_level) - Emitted when level changes

extends Node

## Emitted when any resource value changes
signal resources_changed(food: int, wood: int, gold: int)

## Emitted when level changes
signal level_changed(new_level: int)

## === Game Resources ===

## Amount of Food the player has
var food: int = 0:
	set(value):
		food = max(0, value)
		resources_changed.emit(food, wood, gold)

## Amount of Wood the player has
var wood: int = 0:
	set(value):
		wood = max(0, value)
		resources_changed.emit(food, wood, gold)

## Amount of Gold the player has
var gold: int = 0:
	set(value):
		gold = max(0, value)
		resources_changed.emit(food, wood, gold)

## === Game State ===

## Current level/map number
var level: int = 1:
	set(value):
		level = max(1, value)
		level_changed.emit(level)

## Food expense per turn (upkeep cost)
var food_expense_per_turn: int = 5

## Turn counter (increases every 5 turns for upkeep scaling)
var turn_count: int = 0

## === Resource Management Methods ===

## Add food to player's total
## @param amount: Amount to add
func add_food(amount: int) -> void:
	food += amount

## Add wood to player's total
## @param amount: Amount to add
func add_wood(amount: int) -> void:
	wood += amount

## Add gold to player's total
## @param amount: Amount to add
func add_gold(amount: int) -> void:
	gold += amount

## Add multiple resources at once
## @param yields: Dictionary with keys {food, wood, gold}
func add_resources(yields: Dictionary) -> void:
	print("[GameStatus] add_resources() called with: Food +%d, Wood +%d, Gold +%d" % [
		yields.get("food", 0),
		yields.get("wood", 0),
		yields.get("gold", 0)
	])
	print("[GameStatus] BEFORE: Food=%d, Wood=%d, Gold=%d" % [food, wood, gold])

	if yields.has("food"):
		food += yields["food"]
	if yields.has("wood"):
		wood += yields["wood"]
	if yields.has("gold"):
		gold += yields["gold"]

	print("[GameStatus] AFTER: Food=%d, Wood=%d, Gold=%d" % [food, wood, gold])

## Subtract food from player's total
## @param amount: Amount to subtract
## @returns: true if successful, false if insufficient
func subtract_food(amount: int) -> bool:
	if food >= amount:
		food -= amount
		return true
	return false

## Subtract wood from player's total
## @param amount: Amount to subtract
## @returns: true if successful, false if insufficient
func subtract_wood(amount: int) -> bool:
	if wood >= amount:
		wood -= amount
		return true
	return false

## Subtract gold from player's total
## @param amount: Amount to subtract
## @returns: true if successful, false if insufficient
func subtract_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false

## Check if player can afford food cost
## @param amount: Required amount
## @returns: true if player has enough food
func can_afford_food(amount: int) -> bool:
	return food >= amount

## Check if player can afford wood cost
## @param amount: Required amount
## @returns: true if player has enough wood
func can_afford_wood(amount: int) -> bool:
	return wood >= amount

## Check if player can afford gold cost
## @param amount: Required amount
## @returns: true if player has enough gold
func can_afford_gold(amount: int) -> bool:
	return gold >= amount

## === Turn Management ===

## Increment turn counter and handle upkeep scaling
## Every 5 turns, increase food expense by 1
func advance_turn() -> void:
	turn_count += 1

	# Every 5 turns, increase upkeep
	if turn_count % 5 == 0:
		food_expense_per_turn += 1
		print("Turn %d: Food upkeep increased to %d per turn" % [turn_count, food_expense_per_turn])

## Pay turn upkeep (food expense)
## @returns: true if payment successful, false if insufficient food
func pay_upkeep() -> bool:
	if can_afford_food(food_expense_per_turn):
		subtract_food(food_expense_per_turn)
		print("Paid upkeep: %d food" % food_expense_per_turn)
		return true
	else:
		print("Cannot afford upkeep! Need %d food, have %d" % [food_expense_per_turn, food])
		return false

## === Game State Management ===

## Reset all resources and game state to initial values
func reset_game() -> void:
	food = 0
	wood = 0
	gold = 0
	level = 1
	food_expense_per_turn = 5
	turn_count = 0
	print("Game state reset")

## Advance to next level
func next_level() -> void:
	level += 1

## Apply resource retention on loss (e.g., 25% of resources kept)
## @param retention_percentage: Percentage to keep (0.0 to 1.0)
func apply_loss_penalty(retention_percentage: float = 0.25) -> void:
	food = int(food * retention_percentage)
	wood = int(wood * retention_percentage)
	gold = int(gold * retention_percentage)
	print("Loss penalty applied. Retained %d%% of resources" % int(retention_percentage * 100))

## === Debug & Utility ===

## Print current game status
func print_status() -> void:
	print("=== Game Status ===")
	print("  Level: %d" % level)
	print("  Food: %d" % food)
	print("  Wood: %d" % wood)
	print("  Gold: %d" % gold)
	print("  Turn: %d" % turn_count)
	print("  Upkeep: %d food/turn" % food_expense_per_turn)

## Get total resource count
## @returns: Sum of all resources
func get_total_resources() -> int:
	return food + wood + gold
