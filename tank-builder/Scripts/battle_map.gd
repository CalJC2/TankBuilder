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

func _ready():
	#Normally call from main map
	generate_level(3,4)

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
			# add the drawing of obstacles here for the tilemap
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
			
			# TODO: instantiate enemy tanks scene
			enemies_placed += 1

func spawn_player():
	# spawn player anywhere on the left most column
	var player_start_pos = Vector2i(0, randi_range(1, grid_height -1))
	
	# check if there is anything already there
	if grid_data.has(player_start_pos):
		grid_data.erase(player_start_pos)
		
	grid_data[player_start_pos] = "Player"
	
	# TODO instantiate player tank
