## Enemy.gd
## Represents an enemy/monster in the game
## Similar to Character class but simpler (no abilities, just HP and attack)
##
## Usage:
##   var enemy = Enemy.new("enemy_1", "Monster", "res://Character/Enemy/Torch_Red.png", coordinate)
##   enemy.take_damage(10)
##   if enemy.is_alive():
##       print("Enemy still alive with %d HP" % enemy.currentHP)

class_name Enemy
extends RefCounted

## Unique identifier for this enemy
var id: String

## Display name
var name: String = "Monster"

## Path to sprite texture
var sprite_path: String = "res://Character/Enemy/Torch_Red.png"

## Position on the hex grid
var current_coordinate: HexCoordinate

## Alias for position (for consistency with Character class)
var position: HexCoordinate:
	get:
		return current_coordinate
	set(value):
		current_coordinate = value

## Current hit points
var currentHP: int = 50

## Maximum hit points
var maxHP: int = 50

## Attack damage dealt to characters
var attackDamage: int = 8

## Attack range (1 = adjacent only)
var range: int = 1

## Flag to track if enemy is dead
var is_dead: bool = false


## Constructor
func _init(p_id: String, p_name: String, p_sprite_path: String, p_coordinate: HexCoordinate) -> void:
	id = p_id
	name = p_name
	sprite_path = p_sprite_path
	current_coordinate = p_coordinate


## Take damage from an attack
## @param damage: Amount of damage to take
## @returns: true if still alive, false if died
func take_damage(damage: int) -> bool:
	currentHP -= damage

	if currentHP <= 0:
		currentHP = 0
		is_dead = true
		return false

	return true


## Check if enemy is alive
## @returns: true if HP > 0
func is_alive() -> bool:
	return currentHP > 0 and not is_dead


## Get HP as percentage (for health bar rendering)
## @returns: Value from 0.0 to 1.0
func get_hp_percentage() -> float:
	if maxHP <= 0:
		return 0.0
	return float(currentHP) / float(maxHP)


## Check if character is adjacent (within attack range)
## @param character: The character to check
## @returns: true if character is within range
func can_attack_character(character: Character) -> bool:
	if not is_alive():
		return false

	if not character or not character.is_alive():
		return false

	var distance = current_coordinate.distance_to(character.current_coordinate)
	return distance <= range


## Get enemy info as string (for debugging)
func _to_string() -> String:
	return "%s (%s) at (%d, %d) - HP: %d/%d, Damage: %d" % [
		name, id, current_coordinate.q, current_coordinate.r,
		currentHP, maxHP, attackDamage
	]
