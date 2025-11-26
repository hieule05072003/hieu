extends Node

## DebugManager - Singleton for debug features and error tracking
## Press F12 to toggle debug panel

signal error_occurred(error_message: String)
signal debug_toggled(enabled: bool)

# Debug settings
var debug_enabled: bool = true
var show_debug_panel: bool = true
var log_to_console: bool = true
var log_to_file: bool = false

# Error tracking
var error_count: int = 0
var warning_count: int = 0
var errors: Array[String] = []
var warnings: Array[String] = []

# Performance tracking
var frame_count: int = 0
var fps: float = 0.0

const DEBUG_PREFIX = "[DEBUG]"
const MAX_ERRORS_STORED = 50


func _ready() -> void:
	print("%s DebugManager initialized" % DEBUG_PREFIX)
	print("%s Press F12 to toggle debug panel" % DEBUG_PREFIX)
	print("%s Press F11 to print system status" % DEBUG_PREFIX)


func _process(delta: float) -> void:
	if debug_enabled:
		frame_count += 1
		fps = Engine.get_frames_per_second()


## Log debug message
func debug_log(message: String, category: String = "INFO") -> void:
	if not debug_enabled and category != "ERROR":
		return

	var timestamp = Time.get_time_string_from_system()
	var formatted = "[%s] %s: %s" % [timestamp, category, message]

	if log_to_console:
		print(formatted)

	if log_to_file:
		_write_to_log_file(formatted)


## Log error and track it
func log_error(message: String, context: String = "") -> void:
	error_count += 1
	var full_message = message
	if context:
		full_message = "%s (Context: %s)" % [message, context]

	errors.append(full_message)
	if errors.size() > MAX_ERRORS_STORED:
		errors.pop_front()

	debug_log(full_message, "ERROR")
	error_occurred.emit(full_message)


## Log warning and track it
func log_warning(message: String, context: String = "") -> void:
	warning_count += 1
	var full_message = message
	if context:
		full_message = "%s (Context: %s)" % [message, context]

	warnings.append(full_message)
	if warnings.size() > MAX_ERRORS_STORED:
		warnings.pop_front()

	debug_log(full_message, "WARNING")


## Print current game state (for debugging)
func print_game_state() -> void:
	print("\n" + "=".repeat(60))
	print("=== DEBUG: GAME STATE ===")
	print("=".repeat(60))

	# GameStatus
	print("\n[GameStatus]")
	print("  Level: %d" % GameStatus.level)
	print("  Food: %d" % GameStatus.food)
	print("  Wood: %d" % GameStatus.wood)
	print("  Gold: %d" % GameStatus.gold)
	print("  Turn: %d" % GameStatus.turn_count)
	print("  Upkeep: %d food/turn" % GameStatus.food_expense_per_turn)

	# TurnManager
	print("\n[TurnManager]")
	print("  Phase: %s" % TurnManager.get_phase_name())
	print("  Turn: %d" % TurnManager.current_turn)
	print("  Is Executing: %s" % TurnManager.is_executing)

	# LevelManager
	print("\n[LevelManager]")
	print("  Current Level: %d" % LevelManager.current_level)
	print("  Levels Played: %d" % LevelManager.get_total_levels_played())
	print("  Unique Seeds Used: %d" % LevelManager.used_seeds.size())

	# Errors/Warnings
	print("\n[Debug Stats]")
	print("  Errors: %d" % error_count)
	print("  Warnings: %d" % warning_count)
	print("  FPS: %.1f" % fps)

	if errors.size() > 0:
		print("\n[Recent Errors]")
		for i in range(min(5, errors.size())):
			print("  %d. %s" % [i + 1, errors[errors.size() - 1 - i]])

	if warnings.size() > 0:
		print("\n[Recent Warnings]")
		for i in range(min(5, warnings.size())):
			print("  %d. %s" % [i + 1, warnings[warnings.size() - 1 - i]])

	print("\n" + "=".repeat(60))


## Print character info
func print_characters(character_manager) -> void:
	if not character_manager:
		log_error("CharacterManager not found")
		return

	print("\n" + "=".repeat(60))
	print("=== DEBUG: CHARACTERS ===")
	print("=".repeat(60))

	var characters = character_manager.get_all_characters()
	print("Total Characters: %d" % characters.size())

	for char in characters:
		print("\n[%s]" % char.name)
		print("  Position: (%d, %d)" % [char.position.q, char.position.r])
		print("  HP: %d/%d" % [char.currentHP, char.maxHP])
		print("  Class: %s" % char.character_class)
		print("  Attack: %d" % char.attackDamage)
		print("  Abilities: Hunt=%s, Chop=%s, Mine=%s" % [char.canHunt, char.canChop, char.canMine])

		if char.assigned_resource:
			print("  Assignment: Resource at (%d, %d)" % [
				char.assigned_resource.coordinate.q,
				char.assigned_resource.coordinate.r
			])
		elif char.assigned_enemy:
			print("  Assignment: Enemy at (%d, %d)" % [
				char.assigned_enemy.current_coordinate.q,
				char.assigned_enemy.current_coordinate.r
			])
		else:
			print("  Assignment: None")

	print("=".repeat(60))


## Print enemy info
func print_enemies(enemy_manager) -> void:
	if not enemy_manager:
		log_error("EnemyManager not found")
		return

	print("\n" + "=".repeat(60))
	print("=== DEBUG: ENEMIES ===")
	print("=".repeat(60))

	var enemies = enemy_manager.get_all_enemies()
	var alive = enemy_manager.get_alive_enemy_count()

	print("Total Enemies: %d (Alive: %d)" % [enemies.size(), alive])

	for enemy in enemies:
		var status = "ALIVE" if enemy.is_alive() else "DEAD"
		print("\n[%s] %s" % [status, enemy.name])
		print("  Position: (%d, %d)" % [enemy.position.q, enemy.position.r])
		print("  HP: %d/%d" % [enemy.currentHP, enemy.maxHP])
		print("  Damage: %d" % enemy.attackDamage)

	print("=".repeat(60))


## Print resource info
func print_resources(resource_manager) -> void:
	if not resource_manager:
		log_error("ResourceManager not found")
		return

	print("\n" + "=".repeat(60))
	print("=== DEBUG: RESOURCES ===")
	print("=".repeat(60))

	var resource_count = resource_manager.get_resource_count()
	print("Total Resources: %d" % resource_count)

	# Count by type
	var sheep = resource_manager.get_resources_by_type(ResourceStatus.ResourceType.SHEEP).size()
	var trees = resource_manager.get_resources_by_type(ResourceStatus.ResourceType.TREE).size()
	var rocks = resource_manager.get_resources_by_type(ResourceStatus.ResourceType.ROCK).size()
	var gold = resource_manager.get_resources_by_type(ResourceStatus.ResourceType.GOLD_DEPOSIT).size()

	print("  Sheep: %d" % sheep)
	print("  Trees: %d" % trees)
	print("  Rocks: %d" % rocks)
	print("  Gold Deposits: %d" % gold)

	print("=".repeat(60))


## Toggle debug panel
func toggle_debug_panel() -> void:
	show_debug_panel = !show_debug_panel
	debug_toggled.emit(show_debug_panel)
	debug_log("Debug panel toggled: %s" % ("ON" if show_debug_panel else "OFF"))


## Clear error/warning history
func clear_history() -> void:
	errors.clear()
	warnings.clear()
	error_count = 0
	warning_count = 0
	debug_log("Debug history cleared")


## Write to log file
func _write_to_log_file(message: String) -> void:
	var file = FileAccess.open("user://debug.log", FileAccess.WRITE_READ)
	if file:
		file.seek_end()
		file.store_line(message)
		file.close()


## Get debug info as dictionary
func get_debug_info() -> Dictionary:
	return {
		"errors": error_count,
		"warnings": warning_count,
		"fps": fps,
		"level": GameStatus.level if GameStatus else 0,
		"turn": TurnManager.current_turn if TurnManager else 0,
		"phase": TurnManager.get_phase_name() if TurnManager else "UNKNOWN"
	}
