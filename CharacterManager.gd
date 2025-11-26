extends Node
class_name CharacterManager

## CharacterManager - Manages all characters in the game
## Tracks active characters and provides access for turn execution

signal character_added(character: Character)
signal character_removed(character: Character)
signal character_selected(character: Character)

# All active characters in the game
var characters: Array[Character] = []

# Currently selected character
var selected_character: Character = null

# Debug settings
const DEBUG_MODE = true
const DEBUG_PREFIX = "[CharacterManager]"


func _ready() -> void:
	_debug_log("CharacterManager initialized")


## Add a character to the manager
func add_character(character: Character) -> void:
	if character in characters:
		push_warning("%s Character already added: %s" % [DEBUG_PREFIX, character])
		return

	characters.append(character)
	character_added.emit(character)
	_debug_log("Character added at position %s (Total: %d)" % [character.position, characters.size()])


## Remove a character from the manager
func remove_character(character: Character) -> void:
	if character not in characters:
		push_warning("%s Character not found: %s" % [DEBUG_PREFIX, character])
		return

	characters.erase(character)

	if selected_character == character:
		selected_character = null
		_debug_log("Removed selected character - clearing selection")

	character_removed.emit(character)
	_debug_log("Character removed (Total: %d)" % characters.size())


## Get all characters
func get_all_characters() -> Array[Character]:
	return characters


## Select a character
func select_character(character: Character) -> void:
	if character not in characters:
		push_warning("%s Cannot select character not in manager: %s" % [DEBUG_PREFIX, character])
		return

	selected_character = character
	character_selected.emit(character)
	var char_class = character.character_class if "character_class" in character else "Unknown"
	_debug_log("Character selected at position %s (Type: %s)" % [
		character.position,
		char_class
	])


## Deselect current character
func deselect_character() -> void:
	if selected_character:
		_debug_log("Character deselected at position %s" % selected_character.position)
		selected_character = null
		character_selected.emit(null)


## Get currently selected character
func get_selected_character() -> Character:
	return selected_character


## Check if a character is selected
func has_selected_character() -> bool:
	return selected_character != null


## Get character count
func get_character_count() -> int:
	return characters.size()


## Clear all characters
func clear_all() -> void:
	_debug_log("Clearing all characters (was %d)" % characters.size())
	characters.clear()
	selected_character = null


## Debug logging helper
func _debug_log(message: String) -> void:
	if DEBUG_MODE:
		print("%s %s" % [DEBUG_PREFIX, message])
