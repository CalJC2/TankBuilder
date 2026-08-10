extends Control

var has_used_actions: bool = false
var is_selecting_swap: bool = false
var swap_index_1: int = -1

@onready var shell_move_menu = $MainHBox/RightSideBox/ActionStationContainer/ShellMoveMenu
@onready var main_action_menu = $MainHBox/RightSideBox/ActionStationContainer/MainActionMenu
@onready var shoot_button = $MainHBox/RightSideBox/ShootButton

func _ready():
	start_new_turn()

func start_new_turn():
	has_used_actions = false
	is_selecting_swap = false
	main_action_menu.modulate = Color(1,1,1,1)
	# enable actions buttons here

func use_action():
	has_used_actions = true
	shell_move_menu.hide()
	main_action_menu.modulate = Color(0.5,0.5,0.5,1)
	
