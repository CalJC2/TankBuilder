extends Node2D
class_name BattleMap

@onready var grid_tilemap = $Grid
@onready var entities_container = $Entities

# Grid settings ----------------------------------------------------------------
var grid_width = 10
var grid_height = 8
# using a dictionary to keep track of what is on every tile
# keys will be a vector2i coordinate and a value like "Enemy" or "Player"
var grid_data: Dictionary = {}

# used for pathfinding algorithm ------------------------------------------------------
var astar_grid: AStarGrid2D

# player movement 
var player_pos: Vector2i
var player_tanke_node: Node2D
var is_movement_mode_active: bool = false
var valid_movement_tiles: Array[Vector2i] = []
var selected_target_tile: Vector2i = Vector2i(-1, -1) # (-1, -1) means nothing is selected
var current_path_to_draw: Array[Vector2i] = []

# shooting variables
var is_shooting_mode_active: bool = false
var valid_target_tiles: Array[Vector2i] = []
var active_shell: ShellData

# Enemy and entity info
enum TurnState {PLAYER, ENEMY}
var current_state: TurnState = TurnState.PLAYER
# maps a Vector2i coordinate to a tank node
var entity_grid: Dictionary = {}
var enemy_scene: PackedScene

func _ready():
	#Normally call from main map
	generate_level(3,4)
	setup_astar()

func setup_astar():
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0,0, grid_width, grid_height)
	
	# Replace with pixel size for grid tiles
	astar_grid.cell_size = Vector2(64,64)
	# Stops tanks from moving sideways
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()

func generate_level(num_obstacles: int, num_enemies: int):
	grid_data.clear()
	
	spawn_obstacles(num_obstacles)
	spawn_enemies(num_enemies)
	spawn_player()

# Procedural generation --------------------------------------------------------
func spawn_obstacles(amount: int):
	var obstacles_placed = 0
	while obstacles_placed < amount:
		#pick a random tile anywhere on the map
		var random_pos = Vector2i(randi() % grid_width, randi() % grid_height)
		
		# if the tile is empty, place an obstacle
		if not grid_data.has(random_pos):
			grid_data[random_pos] = "Obstacle"
			# add the drawing of obstacles here for the tilemap -------------------------
			astar_grid.set_point_solid(random_pos, true)
			obstacles_placed += 1

func spawn_enemies(amount: int):
	var enemies_placed = 0
	# enemy side is the right side of the screen
	var enemy_side_start_x = grid_width / 2
	
	while enemies_placed < amount:
		# pick a random tile on that right side
		var random_x = randi_range(enemy_side_start_x, grid_width)
		var random_y = randi_range(0, grid_height-1)
		var random_pos = Vector2i(random_x, random_y)
		
		# make sure enemies cant spawn inside another obstacle or enemy etc
		if not grid_data.has(random_pos):
			grid_data[random_pos] = "Enemy"
			# Block path so that the players cant move onto that tile
			astar_grid.set_point_solid(random_pos, true)
			
			var enemy_instance = enemy_scene.instantiate() as EnemyTank
			entities_container.add_child(enemy_instance)
			
			#move visual to correct location
			enemy_instance.global_position = grid_tilemap.map_to_local(random_pos)
			
			# setup enemy data 
			enemy_instance.enemy_setup(random_pos, 50)
			
			#store enemy in entity dictionary
			entity_grid[random_pos] = enemy_instance
			
			enemies_placed += 1

func spawn_player():
	# spawn player anywhere on the left most column
	player_pos = Vector2i(0, randi_range(1, grid_height -1))
	
	# check if there is anything already there
	if grid_data.has(player_pos):
		grid_data.erase(player_pos)
		
	grid_data[player_pos] = "Player"
	astar_grid.set_point_solid(player_pos, true)
	
	entity_grid[player_pos] = player_tanke_node
	# instantiate player tank
	#var tank_scene = preload(add the tank scene reference here)
	#player_tank_node = tank_scene.instantiate()
	#entities_container.add_child(player_tank_node)
	
	# map_to_local converts the grid coordinates into pixel coordinates
	#player_tank_node.global_position = grid_tilemap.map_to_local(player_pos)

func show_movement_options(tank_data: Resource):
	var move_range = tank_data.movement_range
	var valid_tiles: Array[Vector2i] = []
	
	var min_x = max(0, player_pos.x - move_range)
	var max_x = min(grid_width - 1, player_pos.x + move_range)
	var min_y = max(0, player_pos.y - move_range)
	var max_y = min(grid_height - 1, player_pos.y + move_range)
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var target_pos = Vector2i(x, y)
			
			# Skip if the tile is an obstacle, enemy or where the player is
			if astar_grid.is_point_solid(target_pos) or target_pos == player_pos:
				continue
				
				# get the path using Astar, returns from Start to End
				var path = astar_grid.get_id_path(player_pos, target_pos)
				
				# If the path is valid and the distance is within the tanks range
				# subtract 1 cause the path includes starting tile
				if path.size() > 0 and path.size() - 1 <= move_range:
					valid_tiles.append(target_pos)
	
	highlight_tiles(valid_tiles)

func highlight_tiles(tiles_to_highlight: Array[Vector2i]):
	for tile in tiles_to_highlight:
		pass

func _unhandled_input(event: InputEvent) -> void:
	if not is_movement_mode_active:
		return
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# convert screen tap pixel position into grid coorinates
		var clicked_cell = grid_tilemap.local_to_map(get_local_mouse_position())
		# checks if the tap a valid highlighted tile
		if clicked_cell in valid_movement_tiles:
			# checks if the second tap is on the same tile
			if clicked_cell == selected_target_tile:
				execute_movement(current_path_to_draw)
			# if not, is it the first tap or tap on a different valid tile
			else:
				selected_target_tile = clicked_cell
				
				current_path_to_draw = astar_grid.get_id_path(player_pos, clicked_cell)
	else:
		cancel_movement_mode()
	
	if is_shooting_mode_active and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var clicked_cell = grid_tilemap.local_to_map(get_local_mouse_position())
		
		if clicked_cell in valid_target_tiles:
			execute_shot(clicked_cell)
		else:
			cancel_shooting_mode()

func execute_movement(path: Array[Vector2i]):
	
	var final_destination = path[-1]
	
	#update data and Astar grid by freeing old tile, blocking new one and updating player pos
	grid_data.erase(player_pos)
	astar_grid.set_point_solid(player_pos, false)
	grid_data[final_destination] = "Player"
	astar_grid.set_point_solid(final_destination, true)
	player_pos = final_destination
	# clean up
	cancel_movement_mode()
	
	# create a twee for visual
	var tween = create_tween()
	
	# loop through the path and chain movements together
	for point in path:
		var target_picel_pos = grid_tilemap.map_to_local(point)
		# move the player tank node to the next tile over 0.2 seconds
		tween.tween_property(player_tanke_node, "global_position", target_picel_pos, 0.2)
	
	tween.finished.connect(_on_movement_visually_finished)

func cancel_movement_mode():
	is_movement_mode_active = false
	selected_target_tile = Vector2i(-1,-1)
	valid_movement_tiles.clear()
	current_path_to_draw.clear()
	
	# also clear any visual highlights on the tilemaplayer
	# grid_tilemap.clear_layer(highlight_layer_id) 

func _on_movement_visually_finished():
	print("tank reached destination")
	# emit a signal here to tell the action station/combat coordinatior that the action is consumed

func has_line_of_sight(start_cell: Vector2i, target_cell: Vector2i) -> bool:
	# using Bresenhams line algorithm to check line of sight from the player to the target
	var dx = abs(target_cell.x - start_cell.x)
	var dy = -abs(target_cell.y - start_cell.y)
	var err = dx + dy
	var e2 = 0
	var sx = 1 if start_cell.x < target_cell.x else -1
	var sy = 1 if start_cell.y < target_cell.y else -1
	
	var current = start_cell
	
	while true:
		if current == target_cell:
			break
		
		# check if there is an obstacle in the way
		if current != start_cell and grid_data.has(current):
			if grid_data[current] == "Obstacle":
				return false
		
		e2 = 2 * err
		if e2 >= dy:
			err += dy
			current.x += sx
		if e2 <= dx:
			err += dx
			current.y += sy
		
	return true

func show_shooting_options(shell_data: ShellData):
	active_shell = shell_data
	valid_target_tiles.clear()
	is_shooting_mode_active = true
	
	var shoot_range = shell_data.range
	
	# create bounding bos based on weapon range
	var min_x = max(0, player_pos.x - shoot_range)
	var max_x = min(grid_width - 1, player_pos.x + shoot_range)
	var min_y = max(0, player_pos.y - shoot_range)
	var max_y = min(grid_height - 1, player_pos.y + shoot_range)
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var target_pos = Vector2i(x,y)
			
			# stop player shooting themselves
			if target_pos == player_pos:
				continue
			
			# check if its within a circular/diamon grid distance, not just a square box
			var distance = abs(target_pos.x - player_pos.x) + abs(target_pos.y - player_pos.y)
			if distance <= shoot_range:
				
				#check lin of sight
				if not shell_data.is_arcing or has_line_of_sight(player_pos, target_pos):
					valid_target_tiles.append(target_pos)
	
	highlight_tiles(valid_target_tiles)

func execute_shot(target_tile: Vector2i):
	
	var target_pixel_pos = grid_tilemap.map_to_local(target_tile)
	
	await player_tanke_node.aim_turret(target_pixel_pos)
	
	#check if there is an entity on the tile hit
	if grid_data.has(target_tile):
		var hit_entity = grid_data[target_tile]
		
		# check if the entity has a health component before damage
		if hit_entity.has_node("HealthComponent"):
			var health = hit_entity.get_node("HealthComponent")
			
			health.take_damage(active_shell.damage)
			
			if health.current_health <= 0:
				grid_data.erase(target_tile)
				entity_grid.erase(target_tile)
				astar_grid.set_point_solid(target_tile, false)
	else:
		print("shot missed?")
	
	cancel_shooting_mode()
	
	start_enemy_phase()


func cancel_shooting_mode():
	is_shooting_mode_active = false
	selected_target_tile = Vector2i(-1,-1)
	valid_target_tiles.clear()
	
	# remove highlighted ui

func start_enemy_phase():
	current_state = TurnState.ENEMY
	
	await get_tree().create_timer(0.5).timeout
	
	var all_enemies = []
	for coord in entity_grid:
		if entity_grid[coord] is EnemyTank:
			all_enemies.append(entity_grid[coord])
	
	for enemy in all_enemies:
		if is_instance_valid(enemy):
			await process_single_enemy_ai(enemy)
	
	current_state = TurnState.PLAYER

func process_single_enemy_ai(enemy: EnemyTank):
	# basic ai logic here
	await get_tree().create_timer(0.5).timeout
	
