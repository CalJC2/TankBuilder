extends Control

@export var map_node_scene: PackedScene
@export var default_border_texture: Texture2D
@export var default_icon_texture: Texture2D

@onready var lines_container = $LinesContainer
@onready var nodes_container = $NodesContainer

var current_active_node: MapNode = null
var total_tiers: int = 10
var node_dictionary: Dictionary = {} # Stores node_id -> MapNode
var tier_dictionary: Dictionary = {} # Stores tier_level -> Array of MapNodes
var line_dictionary: Dictionary = {} # Stores "startID_endID" -> Line2D

func _ready():
	randomize()
	generate_nodes()
	generate_connections()
	draw_lines()
	unlock_starting_nodes()

func generate_nodes():
	var screen_size = get_viewport_rect().size
	var column_spacing = screen_size.x / (total_tiers + 1)
	
	for tier in range(total_tiers):
		tier_dictionary[tier] = []
		
		# Determine how many nodes in this column
		var nodes_in_tier = 1
		if tier > 0 and tier < total_tiers - 1:
			nodes_in_tier = randi_range(2, 4)
			
		# Space them vertically
		var row_spacing = screen_size.y / (nodes_in_tier + 1)
		
		for row in range(nodes_in_tier):
			var node_id = "node_" + str(tier) + "_" + str(row)
			var node_instance = map_node_scene.instantiate() as MapNode
			nodes_container.add_child(node_instance)
			
			# Calculate position with a slight random jitter so it looks organic
			var base_x = column_spacing * (tier + 1)
			var base_y = row_spacing * (row + 1)
			var jitter_x = randf_range(-15.0, 15.0) if tier > 0 and tier < total_tiers - 1 else 0.0
			var jitter_y = randf_range(-20.0, 20.0) if tier > 0 and tier < total_tiers - 1 else 0.0
			
			# Center the TextureButton based on a 64x64 assumed size
			node_instance.position = Vector2(base_x + jitter_x - 32, base_y + jitter_y - 32)
			
			node_instance.setup_node(node_id, tier, [], default_border_texture, default_icon_texture)
			
			node_instance.node_selected.connect(_on_node_selected)
			
			node_dictionary[node_id] = node_instance
			tier_dictionary[tier].append(node_instance)

func generate_connections():
	# Loop through every tier except the final boss tier
	for tier in range(total_tiers - 1):
		var current_tier_nodes = tier_dictionary[tier]
		var next_tier_nodes = tier_dictionary[tier + 1]
		
		# Rule 1: Every node in the current tier must connect to at least one node forward
		for node in current_tier_nodes:
			var target_node = next_tier_nodes.pick_random()
			if not target_node.node_id in node.next_nodes:
				node.next_nodes.append(target_node.node_id)
				
		# Rule 2: Every node in the NEXT tier must have at least one incoming connection
		for next_node in next_tier_nodes:
			var has_incoming = false
			for current_node in current_tier_nodes:
				if next_node.node_id in current_node.next_nodes:
					has_incoming = true
					break
			
			if not has_incoming:
				var rescuer_node = current_tier_nodes.pick_random()
				if not next_node.node_id in rescuer_node.next_nodes:
					rescuer_node.next_nodes.append(next_node.node_id)

func draw_lines():
	for node in node_dictionary.values():
		for target_id in node.next_nodes:
			var target_node = node_dictionary[target_id]
			
			var line = Line2D.new()
			# Draw from the center of the buttons (assuming 64x64 size)
			var start_pos = node.position + Vector2(32, 32)
			var end_pos = target_node.position + Vector2(32, 32)
			
			line.add_point(start_pos)
			line.add_point(end_pos)
			
			# Styling the path
			line.width = 4.0
			line.default_color = Color(0.4, 0.4, 0.4, 1.0) 
			line.z_index = -1 # Keeps it firmly behind the map nodes
			
			lines_container.add_child(line)
			
			var line_key = node.node_id + "_" + target_id
			line_dictionary[line_key] = line

func unlock_starting_nodes():
	# lock all nodes on the map
	for node in node_dictionary.values():
		node.set_available(false)
	
	# unlock the first colomn of nodes
	for node in tier_dictionary[0]:
		node.set_available(true)
		node.modulate = Color(0.5, 1, 0.5, 1)
	
	update_fog_of_war(0)

func _on_node_selected(selected_node: MapNode):
	print("Player moved toL ", selected_node.node_id)
	current_active_node = selected_node
	
	# lock the whole map
	for node in node_dictionary.values():
		node.set_available(false)
	
	# keep the node the player is on a different colour
	selected_node.modulate = Color(1,1,1,1)
	
	# only unlock nodes that are connected to this one
	for next_id in selected_node.next_nodes:
		var next_node = node_dictionary[next_id]
		next_node.set_available(true)
	
	update_fog_of_war(selected_node.tier)
	
	#TODO: read the node type and load the correct battle
	

func update_fog_of_war(current_tier: int):
	# calculate how far ahead we are allowed to look
	var visible_tier_limit = current_tier + RunManager.map_visibility_range
	
	# hide of show nodes
	for node in node_dictionary.values():
		if node.tier <= visible_tier_limit:
			node.show()
		else:
			node.hide()
	
	# hide or shot connecting lines
	for node in node_dictionary.values():
		for target_id in node.next_nodes:
			var target_node = node_dictionary[target_id]
			var line_key = node.node_id + "_" + target_id
			var line = line_dictionary[line_key]
			
			# only show the line if both nodes it connects to are visible
			if node.visible and target_node.visible:
				line.show()
			else:
				line.hide()
