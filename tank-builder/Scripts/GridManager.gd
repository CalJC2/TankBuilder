extends Node
class_name GridManager

var width: int = 10
var height: int = 8

var grid_data: Dictionary = {}
var entity_grid: Dictionary = {}
var hazard_grid: Dictionary = {}

var astar_grid: AStarGrid2D

func setup_grid(map_width: int, map_height: int, cell_size: Vector2i):
	width = map_width
	height = map_height
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0,0, width, height)
	astar_grid.cell_size = cell_size
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

# entity and obstacle tracking ------------------------------------------------------------

func add_obstacle(pos: Vector2i):
	grid_data[pos] = "Obstacle"
	astar_grid.set_point_solid(pos, true)

func add_entity(pos: Vector2i, entity: Node2D, entity_type: String):
	grid_data[pos] = entity_type
	entity_grid[pos] = entity
	astar_grid.set_point_solid(pos, true)

func move_entity(from_pos: Vector2i, to_pos: Vector2i):
	var entity = entity_grid[from_pos]
	var entity_type = grid_data[from_pos]
	
	remove_entity(from_pos)
	add_entity(to_pos, entity, entity_type)

func remove_entity(pos: Vector2i):
	grid_data.erase(pos)
	entity_grid.erase(pos)
	astar_grid.set_point_solid(pos, false)

# pathfinding and line of sight -------------------------------------------------

func calculate_grid_path(start: Vector2i, target: Vector2i) -> Array[Vector2i]:
	# unblock start/end for calculation
	astar_grid.set_point_solid(start, false)
	astar_grid.set_point_solid(target, false)
	
	var path = astar_grid.get_id_path(start, target)
	
	# reblock them
	astar_grid.set_point_solid(start, true)
	# only reblock target if something is actually there
	if grid_data.has(target): 
		astar_grid.set_point_solid(target, true)
	
	return path

# Bresenham's line algorithm
func has_line_of_sight(starting_cell: Vector2i, target_cell: Vector2i) -> bool:
	var dx = abs(target_cell.x - starting_cell.x)
	var dy = -abs(target_cell.y - starting_cell.y)
	var err = dx + dy
	var e2 = 0
	var sx = 1 if starting_cell.x < target_cell.x else -1
	var sy = 1 if starting_cell.y < target_cell.y else -1
	
	var current = starting_cell
	
	while true:
		if current == target_cell:
			break
		
		if current != starting_cell and grid_data.has(current):
			if grid_data[current] == "Obstacle" or grid_data[current] == "Smoke":
				return false
		
		e2 = 2 * err
		if e2 >= dy:
			err += dy
			current.x += sx
		if e2 <= dx:
			err += dx
			current.y += sy
	
	return true

func get_piercing_line(starting_cell: Vector2i, target_cell: Vector2i) -> Array[Vector2i]:
	var line_tiles: Array[Vector2i] = []
	
	var dx = abs(target_cell.x - starting_cell.x)
	var dy = -abs(target_cell.y - starting_cell.y)
	var err = dx + dy
	var e2 = 0
	var sx = 1 if starting_cell.x < target_cell.x else -1
	var sy = 1 if starting_cell.y < target_cell.y else -1
	
	var current = starting_cell
	
	while true:
		if current != starting_cell:
			line_tiles.append(current)
		
		if current == target_cell:
			break
		
		e2 = 2 * err
		if e2 >= dy:
			err += dy
			current.x += sx
		if e2 <= dx:
			err += dx
			current.y += sy
	
	return line_tiles

func get_tiles_in_radius(center_cell: Vector2i, radius: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	
	var min_x = max(0, center_cell.x - radius)
	var max_x = min(width - 1, center_cell.x + radius)
	var min_y = max(0, center_cell.y - radius)
	var max_y = min(height - 1, center_cell.y + radius)
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var target_pos = Vector2i(x, y)
			
			var distance = abs(target_pos.x - center_cell.x) + abs(target_pos.y - center_cell.y)
			if distance <= radius:
				tiles.append(target_pos)
	
	return tiles

func add_smoke(pos: Vector2i):
	grid_data[pos] = "Smoke"

func get_knockback_destination(pusher_pos: Vector2i, target_pos: Vector2i, distance: int) -> Vector2i:
	var direction = Vector2i(sign(target_pos.x - pusher_pos.x), sign(target_pos.y - pusher_pos.y))
	if abs(target_pos.x - pusher_pos.x) > abs(target_pos.y - pusher_pos.y):
		direction.y = 0
	else:
		direction.x = 0
	
	return target_pos + (direction * distance)

func add_hazard(pos: Vector2i, type: String, duration: int, damage:int):
	hazard_grid[pos] = {
		"type": type, 
		"turns_left": duration, 
		"damage": damage
	}

func tick_hazards() -> Array[Vector2i]:
	var expired_hazards: Array[Vector2i] = []
	
	for pos in hazard_grid.keys():
		hazard_grid[pos]["turns_left"] -= 1
		if hazard_grid[pos]["turns_left"] <= 0:
			expired_hazards.append(pos)
	
	for pos in expired_hazards:
		hazard_grid.erase(pos)
	
	return expired_hazards
