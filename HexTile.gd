class_name HexTile
extends RefCounted

## Represents a single hexagonal tile with coordinate, terrain type, and owner
## Based on design document requirements:
## - Coordinate: Fixed position on the grid
## - Terrain: Type of terrain (hill, mountain, flower, grass, empty, etc.)
## - Owner: The object occupying the tile (character, resource, etc.)

enum TerrainType {
	EMPTY,      ## Empty/walkable tile
	GRASS,      ## Grass terrain
	FLOWER,     ## Flower terrain
	HILL,       ## Hill terrain (may affect movement)
	MOUNTAIN,   ## Mountain terrain (may block movement)
	WATER,      ## Water terrain
	FOREST,     ## Forest terrain
	SAND,       ## Sand/desert terrain
	ICE,        ## Ice terrain
	STONE       ## Stone terrain
}

## Fixed position on the grid (using HexCoordinate)
var coordinate: HexCoordinate

## Type of terrain on this tile
var terrain: TerrainType

## The object occupying this tile (can be character, resource, or null)
var owner: Variant

func _init(p_coordinate: HexCoordinate, p_terrain: TerrainType = TerrainType.EMPTY, p_owner: Variant = null) -> void:
	coordinate = p_coordinate
	terrain = p_terrain
	owner = p_owner

## Check if tile is occupied
func is_occupied() -> bool:
	return owner != null

## Clear the owner (make tile unoccupied)
func clear_owner() -> void:
	owner = null

## Set new owner
func set_owner(new_owner: Variant) -> void:
	owner = new_owner

## Get terrain name as string
func get_terrain_name() -> String:
	return TerrainType.keys()[terrain]

## Check if terrain is walkable (basic implementation)
func is_walkable() -> bool:
	match terrain:
		TerrainType.MOUNTAIN, TerrainType.WATER:
			return false
		_:
			return true

## Convert to string for debugging
func _to_string() -> String:
	var owner_str = "None" if owner == null else str(owner)
	return "HexTile[%s, Terrain: %s, Owner: %s]" % [coordinate, get_terrain_name(), owner_str]
