extends Node

## TurnManager - Manages turn-based game flow
## Singleton (AutoLoad) that controls game phases and turn execution

# Signals for other systems to react to turn events
signal phase_changed(new_phase: GamePhase)
signal turn_started(turn_number: int)
signal turn_ended(turn_number: int)
signal execution_started()
signal action_executed(action_number: int)  # Emitted for each of the 7 actions
signal execution_completed()
signal game_over(reason: String)

# Game phases
enum GamePhase {
	PLANNING,    # Player positions characters and assigns targets
	EXECUTING,   # Characters perform their 7 actions
	RESOLUTION,  # Pay upkeep, check win/loss, prepare next turn
	VICTORY,     # Level complete - waiting for next level
	GAME_OVER    # Game ended (win or loss)
}

# Current state
var current_phase: GamePhase = GamePhase.PLANNING
var current_turn: int = 1
var is_executing: bool = false

# References (set by Main scene)
var character_manager = null
var harvesting_system = null
var combat_system = null
var enemy_manager = null
var resource_manager = null

# Debug settings
const DEBUG_MODE = true
const DEBUG_PREFIX = "[TurnManager]"


func _ready() -> void:
	_debug_log("TurnManager initialized")
	_debug_log("Starting in PLANNING phase, Turn 1")


## Start the game (called by Main scene after setup)
func start_game() -> void:
	_debug_log("=== GAME STARTED ===")
	current_turn = 1
	current_phase = GamePhase.PLANNING
	phase_changed.emit(current_phase)
	turn_started.emit(current_turn)
	_debug_log("Turn %d - PLANNING phase begun" % current_turn)


## Player presses "Execute Turn" button
func execute_turn() -> void:
	if current_phase != GamePhase.PLANNING:
		push_warning("%s Cannot execute turn - not in PLANNING phase (current: %s)" % [DEBUG_PREFIX, GamePhase.keys()[current_phase]])
		return

	if is_executing:
		push_warning("%s Already executing a turn!" % DEBUG_PREFIX)
		return

	_debug_log("=== EXECUTE TURN BUTTON PRESSED ===")
	_debug_log("Transitioning from PLANNING to EXECUTING phase")

	# Change to EXECUTING phase
	_change_phase(GamePhase.EXECUTING)

	# Execute the turn
	await _execute_all_actions()

	# Move to RESOLUTION phase
	_change_phase(GamePhase.RESOLUTION)

	# Resolve turn effects
	await _resolve_turn()

	# Check if game continues
	if current_phase != GamePhase.GAME_OVER:
		# Start next turn
		current_turn += 1
		_debug_log("=== TURN %d COMPLETE ===" % (current_turn - 1))
		_debug_log("=== STARTING TURN %d ===" % current_turn)
		_change_phase(GamePhase.PLANNING)
		turn_started.emit(current_turn)


## Execute all character actions simultaneously
func _execute_all_actions() -> void:
	_debug_log(">>> Execution Phase Started <<<")
	is_executing = true
	execution_started.emit()

	if not character_manager:
		push_error("%s No character_manager reference! Cannot execute actions." % DEBUG_PREFIX)
		is_executing = false
		return

	if not harvesting_system:
		push_error("%s No harvesting_system reference! Cannot execute actions." % DEBUG_PREFIX)
		is_executing = false
		return

	# Get all characters
	var characters = character_manager.get_all_characters()
	_debug_log("Found %d characters to execute actions" % characters.size())

	if characters.is_empty():
		_debug_log("No characters to execute - skipping execution phase")
		is_executing = false
		execution_completed.emit()
		return

	# For each character, determine what they will do (combat, harvest, or idle)
	var execution_plan = {}
	for character in characters:
		var target_enemy = character.assigned_enemy if "assigned_enemy" in character else null
		var target_resource = character.assigned_resource if "assigned_resource" in character else null

		if target_enemy:
			_debug_log("Character at %s assigned to attack enemy at %s" % [character.position, target_enemy.position])
			execution_plan[character] = {"type": "combat", "target": target_enemy}
		elif target_resource:
			_debug_log("Character at %s assigned to harvest resource at %s" % [character.position, target_resource.position])
			execution_plan[character] = {"type": "harvest", "target": target_resource}
		else:
			_debug_log("Character at %s has no assignment - will idle" % character.position)
			execution_plan[character] = {"type": "idle", "target": null}

	# Execute 7 actions for all characters simultaneously
	for action_num in range(1, 8):  # Actions 1-7
		_debug_log("--- Action %d/7 ---" % action_num)

		for character in characters:
			var plan = execution_plan[character]
			var char_type = character.character_class if "character_class" in character else "Character"

			match plan["type"]:
				"combat":
					var target_enemy = plan["target"]
					if target_enemy and target_enemy.is_alive():
						# Execute combat action
						var damage = combat_system.execute_single_attack_action(character, target_enemy)
						_debug_log("  %s: Attacked enemy for %d damage (Enemy HP: %d/%d)" % [
							char_type,
							damage,
							target_enemy.currentHP,
							target_enemy.maxHP
						])

						# Check if enemy died
						if target_enemy.is_dead:
							_debug_log("  !!! Enemy defeated !!!")
							# Switch to idle for remaining actions
							execution_plan[character] = {"type": "idle", "target": null}
					else:
						# Enemy already dead, idle
						_debug_log("  %s at %s: Idling (enemy already defeated)" % [char_type, character.position])

				"harvest":
					var target = plan["target"]
					if target and ("exists" in target) and target.exists == true:
						# Harvest the resource
						var yield_amount = harvesting_system.execute_single_harvest_action(character, target)
						var res_type = target.get_resource_name() if target.has_method("get_resource_name") else "resource"
						_debug_log("  %s: Harvested %d from %s at %s" % [
							char_type,
							yield_amount,
							res_type,
							target.position
						])

						# Check if resource depleted
						if ("actions_remaining" in target) and target.actions_remaining <= 0:
							_debug_log("  !!! Resource at %s depleted !!!" % target.position)
							# Switch to idle for remaining actions
							execution_plan[character] = {"type": "idle", "target": null}
					else:
						# Resource already gone, idle
						_debug_log("  %s at %s: Idling (resource already depleted)" % [char_type, character.position])

				"idle":
					# Character is idling
					_debug_log("  %s at %s: Idling (action %d/7)" % [
						char_type,
						character.position,
						action_num
					])

		# Emit signal for UI update
		action_executed.emit(action_num)

		# Wait between actions (for visual feedback)
		await get_tree().create_timer(0.3).timeout

	_debug_log(">>> Execution Phase Completed <<<")

	# Clear all character assignments for next turn
	_debug_log("Clearing character assignments for next turn...")
	for character in characters:
		character.assigned_resource = null
		character.assigned_enemy = null

	is_executing = false
	execution_completed.emit()


## Resolve turn effects (upkeep, win/loss checks)
func _resolve_turn() -> void:
	_debug_log(">>> Resolution Phase Started <<<")

	# Pay upkeep
	var food_before = GameStatus.food
	var upkeep_cost = GameStatus.food_expense_per_turn
	_debug_log("Paying upkeep: %d food (current: %d)" % [upkeep_cost, food_before])

	GameStatus.pay_upkeep()

	var food_after = GameStatus.food
	_debug_log("Food after upkeep: %d (spent %d)" % [food_after, food_before - food_after])

	# Check loss condition: food <= 0
	if GameStatus.food <= 0:
		_debug_log("!!! GAME OVER - OUT OF FOOD !!!")
		_end_game("Out of Food! You need to gather more food to feed your team.")
		return

	# Check victory condition (all resources + all enemies gone)
	if resource_manager and enemy_manager:
		if VictoryManager.check_victory_condition(resource_manager, enemy_manager):
			_debug_log("!!! VICTORY CONDITION MET !!!")
			await _achieve_victory()
			return

	# Log current state
	_debug_log("Current resources: Food=%d, Wood=%d, Gold=%d" % [
		GameStatus.food,
		GameStatus.wood,
		GameStatus.gold
	])

	# Warning if food is low
	if GameStatus.food < upkeep_cost * 2:
		push_warning("%s WARNING: Food is low (%d)! Next upkeep costs %d" % [
			DEBUG_PREFIX,
			GameStatus.food,
			upkeep_cost
		])

	_debug_log(">>> Resolution Phase Completed <<<")

	# Small delay before next turn
	await get_tree().create_timer(0.5).timeout


## End the game (win or loss)
func _end_game(reason: String) -> void:
	_debug_log("=== GAME ENDED ===")
	_debug_log("Reason: %s" % reason)
	_debug_log("Final Turn: %d" % current_turn)
	_debug_log("Final Resources: Food=%d, Wood=%d, Gold=%d" % [
		GameStatus.food,
		GameStatus.wood,
		GameStatus.gold
	])

	_change_phase(GamePhase.GAME_OVER)
	game_over.emit(reason)


## Achieve victory (level complete)
func _achieve_victory() -> void:
	_debug_log("=== LEVEL COMPLETE ===")
	_debug_log("Level %d completed on turn %d" % [GameStatus.level, current_turn])
	_debug_log("Resources: Food=%d, Wood=%d, Gold=%d" % [
		GameStatus.food,
		GameStatus.wood,
		GameStatus.gold
	])

	_change_phase(GamePhase.VICTORY)

	# Notify VictoryManager to display victory screen
	VictoryManager.display_victory_screen(GameStatus.level)

	# Note: Main scene will handle "Next Level" button
	# which will call start_next_level() to advance


## Change game phase with logging
func _change_phase(new_phase: GamePhase) -> void:
	if current_phase == new_phase:
		return

	var old_phase_name = GamePhase.keys()[current_phase]
	var new_phase_name = GamePhase.keys()[new_phase]

	_debug_log("Phase transition: %s → %s" % [old_phase_name, new_phase_name])

	current_phase = new_phase
	phase_changed.emit(current_phase)


## Get current phase name as string
func get_phase_name() -> String:
	return GamePhase.keys()[current_phase]


## Check if player can interact (only in PLANNING phase)
func can_player_interact() -> bool:
	return current_phase == GamePhase.PLANNING and not is_executing


## Debug logging helper
func _debug_log(message: String) -> void:
	if DEBUG_MODE:
		print("%s %s" % [DEBUG_PREFIX, message])
