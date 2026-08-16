extends Node2D
class_name BattleMap

@onready var grid_tilemap = $Grid
@onready var entities_container = $Entities
@onready var grid_manager = $GridManager

signal map_action_finished 
signal player_turn_started
signal player_moved
signal shooting_canceled(shell_data: ShellData)

# Grid settings ----------------------------------------------------------------
var grid_width = 10
var grid_height = 8

# player movement --------------------------------------------------------------
var player_pos: Vector2i
var player_tank_node: Node2D
var is_movement_mode_active: bool = false
var valid_movement_tiles: Array[Vector2i] = []
var selected_target_tile: Vector2i = Vector2i(-1, -1) # (-1, -1) means nothing is selected
var current_path_to_draw: Array[Vector2i] = []
@export var player_scene: PackedScene

# shooting variables -----------------------------------------------------------------
var is_shooting_mode_active: bool = false
var valid_target_tiles: Array[Vector2i] = []
var active_shell: ShellData

# Enemy and entity info --------------------------------------------------------------
enum TurnState {PLAYER, ENEMY}
var current_state: TurnState = TurnState.PLAYER
var highlight_nodes: Array[Node] = []
@export var enemy_scene: PackedScene

# obstacle info -----------------------------------------------------------------
@export var obstacle_scene: PackedScene
var hazard_visuals: Dictionary = {}

func _ready():
	#Normally call from main map
	grid_manager.setup_grid(grid_width, grid_height, Vector2i(64, 64))
	generate_level(3,4)
	center_map()

func center_map():
	var map_pixel_width = grid_width * 64
	var map_pixel_height = grid_height * 64
	
	var screen_size = get_viewport_rect().size
	
	self.position = (screen_size - Vector2(map_pixel_width, map_pixel_height)) / 2.0

func generate_level(num_obstacles: int, num_enemies: int):
	grid_manager.grid_data.clear()
	grid_manager.entity_grid.clear()
	
	spawn_obstacles(num_obstacles)
	spawn_enemies(num_enemies)
	spawn_player()

# Procedural generation --------------------------------------------------------
func spawn_obstacles(amount: int):
	var obstacles_placed = 0
	while obstacles_placed < amount:
		#pick a random tile anywhere on the map
		var random_pos = Vector2i(randi() % grid_width, randi() % grid_height)
		
		if not grid_manager.grid_data.has(random_pos):
			grid_manager.add_obstacle(random_pos)
			obstacles_placed += 1

func spawn_enemies(amount: int):
	var enemies_placed = 0
	# enemy side is the right side of the screen
	var enemy_side_start_x = grid_width / 2
	
	while enemies_placed < amount:
		# pick a random tile on that right side
		var random_x = randi_range(enemy_side_start_x, grid_width - 1)
		var random_y = randi_range(0, grid_height - 1)
		var random_pos = Vector2i(random_x, random_y)
		
		if not grid_manager.grid_data.has(random_pos):
			var enemy_instance = enemy_scene.instantiate() as EnemyTank
			entities_container.add_child(enemy_instance)
			enemy_instance.position = grid_tilemap.map_to_local(random_pos)
			enemy_instance.enemy_setup(random_pos, 10, 2)
			
			grid_manager.add_entity(random_pos, enemy_instance, "Enemy")
			enemies_placed += 1

func spawn_player():
	# spawn player anywhere on the left most column
	player_pos = Vector2i(0, randi_range(1, grid_height -1))
	if grid_manager.grid_data.has(player_pos):
		grid_manager.remove_entity(player_pos)
	
	player_tank_node = player_scene.instantiate() as PlayerTank
	entities_container.add_child(player_tank_node)
	# map_to_local converts the grid coordinates into pixel coordinates
	player_tank_node.position = grid_tilemap.map_to_local(player_pos)
	
	grid_manager.add_entity(player_pos, player_tank_node, "Player")

func show_movement_options():
	is_movement_mode_active = true
	valid_movement_tiles.clear()
	
	var move_range = player_tank_node.tank_data.movement_range
	var min_x = max(0, player_pos.x - move_range)
	var max_x = min(grid_width - 1, player_pos.x + move_range)
	var min_y = max(0, player_pos.y - move_range)
	var max_y = min(grid_height - 1, player_pos.y + move_range)
	
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var target_pos = Vector2i(x, y)
			
			# Skip if the tile is an obstacle, enemy or where the player is
			if grid_manager.astar_grid.is_point_solid(target_pos) or target_pos == player_pos:
				continue
				
			# get the path using Astar, returns from Start to End
			var path = grid_manager.calculate_grid_path(player_pos, target_pos)
			
			# If the path is valid and the distance is within the tanks range
			# subtract 1 cause the path includes starting tile
			if path.size() > 0 and path.size() - 1 <= move_range:
				valid_movement_tiles.append(target_pos)
	
	highlight_tiles(valid_movement_tiles, Color(0,0,1,0.5))

func highlight_tiles(tiles_to_highlight: Array[Vector2i], colour: Color):
	clear_highlights()
	
	for tile in tiles_to_highlight:
		var highlight_rect = ColorRect.new()
		highlight_rect.color = colour
		
		highlight_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
		highlight_rect.size = Vector2(64,64)
		
		var center_pos = grid_tilemap.map_to_local(tile)
		highlight_rect.position = Vector2(center_pos.x - 32, center_pos.y - 32)
		
		highlight_rect.z_index = 10
		add_child(highlight_rect)
		highlight_nodes.append(highlight_rect)

func clear_highlights():
	for node in highlight_nodes:
		node.queue_free()
	highlight_nodes.clear()

func spawn_hazard_visual(tile: Vector2i, type: String):
	if hazard_visuals.has(tile):
		hazard_visuals[tile].queue_free()
	
	var rect = ColorRect.new()
	if type == "acid":
		rect.color = Color(0.2, 0.8, 0.2, 0.5)
	elif type == "mud":
		rect.color = Color(0.4, 0.3, 0.1, 0.5)
	
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.size = Vector2(64, 64)
	var center_pos = grid_tilemap.map_to_local(tile)
	rect.position = Vector2(center_pos.x - 32, center_pos.y - 32)
	rect.z_index = 1
	
	add_child(rect)
	hazard_visuals[tile] = rect

func _unhandled_input(event: InputEvent) -> void:
	if is_movement_mode_active:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var clicked_cell = grid_tilemap.local_to_map(get_local_mouse_position())
				if clicked_cell in valid_movement_tiles:
					if clicked_cell == selected_target_tile:
						if current_path_to_draw.size() > 0:
							execute_movement(current_path_to_draw)
					else:
						selected_target_tile = clicked_cell
						current_path_to_draw = grid_manager.calculate_grid_path(player_pos, clicked_cell)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				cancel_movement_mode()
				map_action_finished.emit()
	
	if is_shooting_mode_active:
		if event is InputEventMouseButton and event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				var clicked_cell = grid_tilemap.local_to_map(get_local_mouse_position())
				if clicked_cell in valid_target_tiles:
					execute_shot(clicked_cell)
			elif event.button_index == MOUSE_BUTTON_RIGHT:
				abort_shooting()
				map_action_finished.emit()

func execute_movement(path: Array[Vector2i]):
	var actual_path: Array[Vector2i] = []
	var final_destination = player_pos
	
	# Drive the path step-by-step in memory to check for hazards
	for point in path:
		actual_path.append(point)
		final_destination = point
		
		# If this tile has mud, we get stuck and stop plotting the path!
		if grid_manager.hazard_grid.has(point):
			var hazard = grid_manager.hazard_grid[point]
			if hazard["type"] == "mud" and point != player_pos:
				break 
	
	# 2. Safely swap coordinates to wherever we ended up
	grid_manager.move_entity(player_pos, final_destination)
	player_pos = final_destination
	
	# 3. Create the animation using our new, potentially shortened path
	var tween = create_tween()
	for point in actual_path:
		var target_pixel_pos = grid_tilemap.map_to_local(point)
		tween.tween_property(player_tank_node, "position", target_pixel_pos, 0.2)
	
	cancel_movement_mode()
	tween.finished.connect(_on_movement_visually_finished)

func cancel_movement_mode():
	is_movement_mode_active = false
	selected_target_tile = Vector2i(-1,-1)
	valid_movement_tiles.clear()
	current_path_to_draw.clear()
	clear_highlights()
	# also clear any visual highlights on the tilemaplayer
	#grid_tilemap.clear_layer(highlight_layer_id) 

func _on_movement_visually_finished():
	player_moved.emit()
	map_action_finished.emit()

func show_shooting_options(shell_data: ShellData):
	active_shell = shell_data
	valid_target_tiles.clear()
	is_shooting_mode_active = true
	var shoot_range = shell_data.max_range
	
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
				if shell_data.is_arcing or shell_data.is_piercing or grid_manager.has_line_of_sight(player_pos, target_pos):
					valid_target_tiles.append(target_pos)
	
	highlight_tiles(valid_target_tiles, Color(1,0,0,0.5))

func execute_shot(target_tile: Vector2i):
	var target_local_pos = grid_tilemap.map_to_local(target_tile)
	var target_global_pos = grid_tilemap.to_global(target_local_pos)
	await player_tank_node.aim_turret(target_global_pos)
	
	# grapple check
	if active_shell.is_grapple:
		if target_tile.x >= 0 and target_tile.x < grid_width and target_tile.y >= 0 and target_tile.y < grid_height:
			if not grid_manager.grid_data.has(target_tile):
				grid_manager.move_entity(player_pos, target_tile)
				player_pos = target_tile
				var tween = create_tween()
				tween.tween_property(player_tank_node, "position", target_global_pos, 0.3)
				cancel_shooting_mode()
				start_enemy_phase()
				return
			
	
	# spawn check
	if active_shell.spawns_smoke:
		grid_manager.add_smoke(target_tile)
	if active_shell.spawns_obstacles:
		var obstacle = obstacle_scene.instantiate() 
		entities_container.add_child(obstacle)
		obstacle.position = grid_tilemap.map_to_local(target_tile)
		
		obstacle.setup_obstacle(30)
		grid_manager.add_entity(target_tile, obstacle, "Obstacle")
	
	var tiles_to_damage: Array[Vector2i] = []
	if active_shell.is_piercing:
		tiles_to_damage = grid_manager.get_piercing_line(player_pos, target_tile)
	elif active_shell.splash_radius > 0:
		tiles_to_damage = grid_manager.get_tiles_in_radius(target_tile, active_shell.splash_radius)
	else:
		tiles_to_damage.append(target_tile)
	
	for tile in tiles_to_damage:
		if tile == player_pos:
			continue
		
		if active_shell.hazard_type != "":
			grid_manager.add_hazard(tile, active_shell.hazard_type, active_shell.hazard_duration, active_shell.hazard_damage)
			
		
		if grid_manager.grid_data.has(tile):
			var hit_entity = grid_manager.entity_grid.get(tile)
			
			# check if the entity has a health component before damage
			if hit_entity and hit_entity.has_node("HealthComponent"):
				var health = hit_entity.get_node("HealthComponent")
				
				if active_shell.knockback_distance > 0:
					var kb_dest = grid_manager.get_knockback_destination(player_pos, tile, active_shell.knockback_distance)
					
					if grid_manager.grid_data.has(kb_dest):
						print("Knockback collision")
						health.take_damage(active_shell.damage)
					elif kb_dest.x >= 0 and kb_dest.x < grid_width and kb_dest.y >= 0 and kb_dest.y < grid_height:
						grid_manager.move_entity(tile, kb_dest)
						hit_entity.current_grid_pos = kb_dest
						
						var kb_pixel_pos = grid_tilemap.map_to_local(kb_dest)
						var tween = create_tween()
						tween.tween_property(hit_entity,"position", kb_pixel_pos, 0.2)
				
				health.take_damage(active_shell.damage)
				print("Shell damage = ", active_shell.damage)
				
				if active_shell.has_life_steal:
					if is_instance_valid(player_tank_node) and player_tank_node.has_node("HealthComponent"):
						player_tank_node.get_node("HealthComponent").heal(active_shell.damage)
				
				if active_shell.dot_duration > 0:
					health.apply_dot(active_shell.dot_damage, active_shell.dot_duration)
				if active_shell.cryo_duration > 0:
					health.apply_status("cryo", active_shell.cryo_duration)
				if active_shell.emp_duration > 0:
					health.apply_status("emp", active_shell.emp_duration)
				if active_shell.vulnerable_duration > 0:
					health.apply_status("vulnerable", active_shell.vulnerable_duration)
				
				
				if health.current_health <= 0:
					grid_manager.remove_entity(target_tile)
					if active_shell.knockback_distance > 0 and not grid_manager.grid_data.has(tile):
						var kb_dest = grid_manager.get_knockback_destination(player_pos, tile, active_shell.knockback_distance)
						grid_manager.remove_entity(kb_dest)
						
					check_win_condition()
	
	active_shell = null
	cancel_shooting_mode()
	start_enemy_phase()


func cancel_shooting_mode():
	is_shooting_mode_active = false
	selected_target_tile = Vector2i(-1,-1)
	valid_target_tiles.clear()
	clear_highlights()

func start_enemy_phase():
	current_state = TurnState.ENEMY
	await get_tree().create_timer(0.5).timeout
	
	# --- Process Hazards & Visuals ---
	var expired_tiles = grid_manager.tick_hazards()
	for tile in expired_tiles:
		if hazard_visuals.has(tile):
			hazard_visuals[tile].queue_free()
			hazard_visuals.erase(tile)
	
	# --- Apply Hazard Effects to Entities ---
	for coord in grid_manager.entity_grid.keys():
		if grid_manager.hazard_grid.has(coord):
			var hazard = grid_manager.hazard_grid[coord]
			var entity = grid_manager.entity_grid[coord]
			
			# Safety check: Is the entity still alive before we melt it?
			if is_instance_valid(entity) and hazard["type"] == "acid" and entity.has_node("HealthComponent"):
				entity.get_node("HealthComponent").take_damage(hazard["damage"], true)
				print(entity.name, " took Acid damage from the floor!")
				
				if entity.get_node("HealthComponent").current_health <= 0:
					grid_manager.remove_entity(coord)
	
	# --- Gather Enemies & Apply DoT ---
	var all_enemies = []
	for coord in grid_manager.entity_grid.keys():
		var entity = grid_manager.entity_grid[coord]
		
		# Safety check: ONLY check 'is EnemyTank' if the entity is actually still alive!
		if is_instance_valid(entity) and entity is EnemyTank:
			all_enemies.append(entity)
			
			if entity.has_node("HealthComponent"):
				entity.get_node("HealthComponent").process_start_of_turn_effects()
				
				if entity.get_node("HealthComponent").current_health <= 0:
					grid_manager.remove_entity(coord)
	
	# --- Execute AI for surviving enemies ---
	for enemy in all_enemies:
		if is_instance_valid(enemy) and enemy.get_node("HealthComponent").current_health > 0:
			await process_single_enemy_ai(enemy)
	
	current_state = TurnState.PLAYER
	map_action_finished.emit()
	
	if is_instance_valid(player_tank_node) and player_tank_node.has_node("HealthComponent"):
		player_tank_node.get_node("HealthComponent").process_start_of_turn_effects()
		
	player_turn_started.emit()

func process_single_enemy_ai(enemy: EnemyTank):
	var enemy_range = 4
	var enemy_damage = 10
	var distance_to_player = abs(player_pos.x - enemy.current_grid_pos.x) + abs(player_pos.y - enemy.current_grid_pos.y)
	
	if distance_to_player <= enemy_range and grid_manager.has_line_of_sight(enemy.current_grid_pos, player_pos):
		var target_local_pos = grid_tilemap.map_to_local(player_pos)
		var target_global_pos = grid_tilemap.to_global(target_local_pos)
		await enemy.aim_turret(target_global_pos)
		
		if grid_manager.entity_grid.has(player_pos):
			var player = grid_manager.entity_grid[player_pos]
			if player.has_node("HealthComponent"):
				player.get_node("HealthComponent").take_damage(enemy_damage)
	else:
		var path = grid_manager.calculate_grid_path(enemy.current_grid_pos, player_pos)
		
		if path.size() > 1:
			var next_step = path[1]
			
			grid_manager.move_entity(enemy.current_grid_pos, next_step)
			enemy.current_grid_pos = next_step
			
			var target_pixel_pos = grid_tilemap.map_to_local(next_step)
			var tween = create_tween()
			tween.tween_property(enemy, "position", target_pixel_pos, 0.3)
			await tween.finished
	
	
	await get_tree().create_timer(0.2).timeout


func check_win_condition():
	var enemies_alive = false
	
	for coord in grid_manager.entity_grid:
		if grid_manager.entity_grid[coord] is EnemyTank:
			enemies_alive = true
			break
	
	if not enemies_alive:
		print("Victory")
		get_tree().quit()


func apply_chamber_damage(amount: int):
	if is_instance_valid(player_tank_node) and player_tank_node.has_node("HealthComponent"):
		var health = player_tank_node.get_node("HealthComponent")
		health.take_damage(amount)
		print("MOAB Damage")
	
		if health.current_health <= 0:
			get_tree().quit()

func abort_shooting():
	if is_shooting_mode_active and active_shell != null:
		shooting_canceled.emit(active_shell)
		active_shell = null
		
		cancel_shooting_mode()
