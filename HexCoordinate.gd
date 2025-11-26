class_name HexCoordinate
extends RefCounted

## Represents a hexagonal coordinate using axial coordinate system (q, r)
## q = column, r = row
## Cube coordinates: x = q, y = -q-r, z = r

var q: int
var r: int

func _init(p_q: int = 0, p_r: int = 0) -> void:
	q = p_q
	r = p_r

## Convert to cube coordinates (x, y, z)
func to_cube() -> Vector3i:
	var x = q
	var z = r
	var y = -x - z
	return Vector3i(x, y, z)

## Create from cube coordinates
static func from_cube(x: int, y: int, z: int) -> HexCoordinate:
	return HexCoordinate.new(x, z)

## Check equality with another coordinate
func equals(other: HexCoordinate) -> bool:
	return q == other.q and r == other.r

## Get hash for dictionary keys
func hash() -> int:
	return (q << 16) | (r & 0xFFFF)

## Convert to string for debugging
func _to_string() -> String:
	return "HexCoordinate(%d, %d)" % [q, r]

## Add two coordinates
func add(other: HexCoordinate) -> HexCoordinate:
	return HexCoordinate.new(q + other.q, r + other.r)

## Subtract two coordinates
func subtract(other: HexCoordinate) -> HexCoordinate:
	return HexCoordinate.new(q - other.q, r - other.r)

## Calculate distance to another coordinate
func distance_to(other: HexCoordinate) -> int:
	var cube_a = to_cube()
	var cube_b = other.to_cube()
	return (abs(cube_a.x - cube_b.x) + abs(cube_a.y - cube_b.y) + abs(cube_a.z - cube_b.z)) / 2

## Get all 6 neighbor directions
static func get_directions() -> Array[HexCoordinate]:
	var directions: Array[HexCoordinate] = []
	directions.append(HexCoordinate.new(1, 0))   # Right
	directions.append(HexCoordinate.new(1, -1))  # Upper-right
	directions.append(HexCoordinate.new(0, -1))  # Upper-left
	directions.append(HexCoordinate.new(-1, 0))  # Left
	directions.append(HexCoordinate.new(-1, 1))  # Lower-left
	directions.append(HexCoordinate.new(0, 1))   # Lower-right
	return directions

## Get neighbor in a specific direction (0-5)
func get_neighbor(direction: int) -> HexCoordinate:
	var directions = get_directions()
	return add(directions[direction % 6])

## Get all 6 neighbors
func get_neighbors() -> Array[HexCoordinate]:
	var neighbors: Array[HexCoordinate] = []
	for direction in get_directions():
		neighbors.append(add(direction))
	return neighbors
