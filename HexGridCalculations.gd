class_name HexGridCalculations
extends RefCounted

## Utility class for hexagonal grid calculations
## Provides coordinate conversions, distance calculations, and pathfinding helpers
## Uses flat-top hexagon orientation by default

## Hex size (distance from center to corner)
const HEX_SIZE: float = 32.0

## Hex layout constants for flat-top hexagons
const SQRT_3: float = 1.732050808

## Convert axial coordinate to pixel position (flat-top orientation)
## @param coordinate: HexCoordinate to convert
## @param hex_size: Size of hexagon (default: HEX_SIZE)
## @return: Vector2 pixel position
static func axial_to_pixel(coordinate: HexCoordinate, hex_size: float = HEX_SIZE) -> Vector2:
	var x = hex_size * (3.0 / 2.0 * coordinate.q)
	var y = hex_size * (SQRT_3 / 2.0 * coordinate.q + SQRT_3 * coordinate.r)
	return Vector2(x, y)

## Convert pixel position to axial coordinate (flat-top orientation)
## @param pixel: Vector2 pixel position
## @param hex_size: Size of hexagon (default: HEX_SIZE)
## @return: HexCoordinate (rounded to nearest hex)
static func pixel_to_axial(pixel: Vector2, hex_size: float = HEX_SIZE) -> HexCoordinate:
	var q = (2.0 / 3.0 * pixel.x) / hex_size
	var r = (-1.0 / 3.0 * pixel.x + SQRT_3 / 3.0 * pixel.y) / hex_size
	return axial_round(q, r)

## Round fractional axial coordinates to nearest integer coordinates
## @param q: Fractional q coordinate
## @param r: Fractional r coordinate
## @return: Rounded HexCoordinate
static func axial_round(q: float, r: float) -> HexCoordinate:
	var x = q
	var z = r
	var y = -x - z

	var rx = round(x)
	var ry = round(y)
	var rz = round(z)

	var x_diff = abs(rx - x)
	var y_diff = abs(ry - y)
	var z_diff = abs(rz - z)

	if x_diff > y_diff and x_diff > z_diff:
		rx = -ry - rz
	elif y_diff > z_diff:
		ry = -rx - rz
	else:
		rz = -rx - ry

	return HexCoordinate.new(int(rx), int(rz))

## Calculate Manhattan distance between two coordinates
## @param a: First coordinate
## @param b: Second coordinate
## @return: Integer distance
static func distance(a: HexCoordinate, b: HexCoordinate) -> int:
	return a.distance_to(b)

## Get all coordinates within a certain range of a center coordinate
## @param center: Center coordinate
## @param range: Maximum distance from center
## @return: Array of HexCoordinates within range
static func get_coordinates_in_range(center: HexCoordinate, range: int) -> Array[HexCoordinate]:
	var results: Array[HexCoordinate] = []

	for q in range(-range, range + 1):
		for r in range(max(-range, -q - range), min(range, -q + range) + 1):
			var coord = HexCoordinate.new(center.q + q, center.r + r)
			results.append(coord)

	return results

## Get all coordinates in a ring at a specific distance from center
## @param center: Center coordinate
## @param radius: Distance from center
## @return: Array of HexCoordinates forming a ring
static func get_ring(center: HexCoordinate, radius: int) -> Array[HexCoordinate]:
	var results: Array[HexCoordinate] = []

	if radius == 0:
		results.append(center)
		return results

	# Start at a coordinate radius steps away
	var coord = center.add(HexCoordinate.new(-radius, radius))

	# Walk around the ring
	var directions = HexCoordinate.get_directions()
	for i in range(6):
		for _j in range(radius):
			results.append(coord)
			coord = coord.add(directions[i])

	return results

## Check if a coordinate is within grid bounds
## @param coordinate: Coordinate to check
## @param width: Grid width
## @param height: Grid height
## @return: true if within bounds
static func is_within_bounds(coordinate: HexCoordinate, width: int, height: int) -> bool:
	return coordinate.q >= 0 and coordinate.q < width and coordinate.r >= 0 and coordinate.r < height

## Get line of coordinates from a to b (for line of sight, etc.)
## @param a: Start coordinate
## @param b: End coordinate
## @return: Array of coordinates forming a line
static func get_line(a: HexCoordinate, b: HexCoordinate) -> Array[HexCoordinate]:
	var results: Array[HexCoordinate] = []
	var dist = distance(a, b)

	if dist == 0:
		results.append(a)
		return results

	for i in range(dist + 1):
		var t = float(i) / float(dist)
		var q = lerp(float(a.q), float(b.q), t)
		var r = lerp(float(a.r), float(b.r), t)
		results.append(axial_round(q, r))

	return results

## Get all neighbors of a coordinate that are within bounds
## @param coordinate: Center coordinate
## @param width: Grid width
## @param height: Grid height
## @return: Array of valid neighbor coordinates
static func get_valid_neighbors(coordinate: HexCoordinate, width: int, height: int) -> Array[HexCoordinate]:
	var results: Array[HexCoordinate] = []
	for neighbor in coordinate.get_neighbors():
		if is_within_bounds(neighbor, width, height):
			results.append(neighbor)
	return results

## Linear interpolation helper
static func lerp(a: float, b: float, t: float) -> float:
	return a + (b - a) * t

## Calculate the angle from one hex to another (in radians)
## @param from: Starting coordinate
## @param to: Target coordinate
## @return: Angle in radians
static func get_angle_between(from: HexCoordinate, to: HexCoordinate) -> float:
	var from_pixel = axial_to_pixel(from)
	var to_pixel = axial_to_pixel(to)
	return from_pixel.angle_to_point(to_pixel)
