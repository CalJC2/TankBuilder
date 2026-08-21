extends TextureButton
class_name MapNode

signal node_selected(node: MapNode)

@export var reward_icon_rect: TextureRect

var node_id: String
var next_nodes: Array[String] = []
var tier: int = 0

func setup_node(id: String, node_tier: int, connected_to: Array[String], border_texture: Texture2D, icon_texture: Texture2D):
	node_id = id
	tier = node_tier
	next_nodes = connected_to
	
	texture_normal = border_texture
	
	if reward_icon_rect and icon_texture:
		reward_icon_rect.texture = icon_texture

func _pressed() -> void:
	node_selected.emit(self)

func set_available(is_available: bool):
	disabled = not is_available
	if is_available:
		modulate = Color(1, 1, 1, 1) 
	else:
		modulate = Color(0.3, 0.3, 0.3, 1)
