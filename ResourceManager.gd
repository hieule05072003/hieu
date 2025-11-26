## ResourceManager.gd
## Manages all harvestable resources on the hex tilemap.
## Handles placing, tracking, harvesting, and removing resources.
##
## Usage:
##   resource_manager.place_resource(coord, ResourceStatus.ResourceType.TREE)
##   var resource = resource_manager.get_resource_at(coord)
##   var yields = resource_manager.harvest_resource(coord, 5)
##   if resource_manager.is_resource_depleted(coord):
##       resource_manager.remove_resource(coord)
##
## Signals:
##   resource_placed(coordinate, resource) - Emitted when a resource is added
##   resource_harvested(coordinate, resource, yields) - Emitted when harvested
##   resource_depleted(coordinate, resource) - Emitted when resource HP reaches 0

extends Node
class_name ResourceManager

## Emitted when a resource is placed on the map
signal resource_placed(coordinate: HexCoordinate, resource: ResourceStatus)

## Emitted when a resource is harvested
signal resource_harvested(coordinate: HexCoordinate, resource: ResourceStatus, yields: Dictionary)

## Emitted when a resource is depleted and removed
signal resource_depleted(coordinate: HexCoordinate, resource: ResourceStatus)

## Dictionary storing all active resources: {String: ResourceStatus}
## Keys are in format "q,r" (e.g., "8,10")
var _resources: Dictionary = {}

## Reference to the HexTilemap (set externally or via dependency injection)
var tilemap: HexTilemap = null

## Helper function: Convert HexCoordinate to dictionary key string
## @param coordinate: HexCoordinate to convert
## @returns: String key in format "q,r"
func _coord_to_key(coordinate: HexCoordinate) -> String:
	return "%d,%d" % [coordinate.q, coordinate.r]

## Place a new resource on the map at the given coordinate
## @param coordinate: Where to place the resource
## @param resource_type: Type of resource to create
## @param hp: Optional custom HP (uses default if -1)
## @returns: The created ResourceStatus, or null if coordinate is occupied
func place_resource(coordinate: HexCoordinate, resource_type: ResourceStatus.ResourceType, hp: int = -1) -> ResourceStatus:
	# Check if coordinate already has a resource
	if has_resource_at(coordinate):
		push_warning("Cannot place resource at %s - already occupied" % coordinate)
		return null

	# Create the resource
	var resource = ResourceStatus.new(resource_type, coordinate, hp)
	var key = _coord_to_key(coordinate)
	_resources[key] = resource

	# Emit signal for visual updates
	resource_placed.emit(coordinate, resource)

	return resource

## Get the resource at the given coordinate
## @param coordinate: Position to check
## @returns: ResourceStatus if present, null otherwise
func get_resource_at(coordinate: HexCoordinate) -> ResourceStatus:
	var key = _coord_to_key(coordinate)
	if _resources.has(key):
		return _resources[key]
	return null

## Check if a resource exists at the given coordinate
## @param coordinate: Position to check
## @returns: true if resource present
func has_resource_at(coordinate: HexCoordinate) -> bool:
	var key = _coord_to_key(coordinate)
	return _resources.has(key)

## Harvest the resource at the given coordinate
## Reduces resource HP and returns yields
## @param coordinate: Position of resource to harvest
## @param work_amount: How much work to apply
## @returns: Dictionary with {food, wood, gold} yields, or null if no resource
func harvest_resource(coordinate: HexCoordinate, work_amount: int) -> Dictionary:
	var resource = get_resource_at(coordinate)
	if resource == null:
		push_warning("No resource at %s to harvest" % coordinate)
		return {"food": 0, "wood": 0, "gold": 0}

	# Perform harvest
	var yields = resource.harvest(work_amount)

	# Emit signal
	resource_harvested.emit(coordinate, resource, yields)

	# Check if depleted and remove if necessary
	if resource.is_depleted():
		remove_resource(coordinate)

	return yields

## Remove a resource from the map
## @param coordinate: Position of resource to remove
## @returns: The removed ResourceStatus, or null if none existed
func remove_resource(coordinate: HexCoordinate) -> ResourceStatus:
	if not has_resource_at(coordinate):
		return null

	var key = _coord_to_key(coordinate)
	var resource = _resources[key]
	_resources.erase(key)

	# Emit signal
	resource_depleted.emit(coordinate, resource)

	return resource

## Check if the resource at the given coordinate is depleted
## @param coordinate: Position to check
## @returns: true if resource exists and is depleted
func is_resource_depleted(coordinate: HexCoordinate) -> bool:
	var resource = get_resource_at(coordinate)
	if resource == null:
		return false
	return resource.is_depleted()

## Get all active resources on the map
## @returns: Array of ResourceStatus objects
func get_all_resources() -> Array[ResourceStatus]:
	var result: Array[ResourceStatus] = []
	for resource in _resources.values():
		result.append(resource)
	return result

## Get all resources of a specific type
## @param resource_type: Type to filter by
## @returns: Array of ResourceStatus objects matching the type
func get_resources_by_type(resource_type: ResourceStatus.ResourceType) -> Array[ResourceStatus]:
	var result: Array[ResourceStatus] = []
	for resource in _resources.values():
		if resource.resource_type == resource_type:
			result.append(resource)
	return result

## Clear all resources from the map
func clear_all_resources() -> void:
	_resources.clear()

## Get total count of active resources
## @returns: Number of resources on the map
func get_resource_count() -> int:
	return _resources.size()

## Find the nearest resource of a given type to a coordinate
## @param from_coordinate: Starting position
## @param resource_type: Type of resource to find
## @returns: ResourceStatus of nearest resource, or null if none found
func find_nearest_resource(from_coordinate: HexCoordinate, resource_type: ResourceStatus.ResourceType) -> ResourceStatus:
	var nearest: ResourceStatus = null
	var nearest_distance: int = 999999

	for resource in get_resources_by_type(resource_type):
		var distance = from_coordinate.distance_to(resource.coordinate)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = resource

	return nearest

## Get all resources within a given range of a coordinate
## @param center: Center coordinate
## @param range: Maximum distance
## @returns: Array of ResourceStatus objects within range
func get_resources_in_range(center: HexCoordinate, range: int) -> Array[ResourceStatus]:
	var result: Array[ResourceStatus] = []
	for resource in _resources.values():
		if center.distance_to(resource.coordinate) <= range:
			result.append(resource)
	return result

## Debug function to print all active resources
func print_resources() -> void:
	print("=== Active Resources (%d) ===" % get_resource_count())
	for coordinate in _resources.keys():
		var resource = _resources[coordinate]
		print("  %s" % resource)
