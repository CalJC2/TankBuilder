extends Node

@export var starting_test_deck: Array[ShellData]

@onready var battle_map = $BattleMap
@onready var combat_controller = $CombatController
@onready var action_station = $UILayer/MainPlayerScreen/MainHBox/RightSideBox/ActionStationContainer
@onready var main_player_screen = $UILayer/MainPlayerScreen
@onready var view_map_button = $UILayer/MainPlayerScreen/MainHBox/RightSideBox/ActionStationContainer/MainActionMenu/ViewMapButton
@onready var return_to_ui_button = $UILayer/ReturnToUIButton

func _ready() -> void:
	# View map button ----------------------------------------------------------
	view_map_button.pressed.connect(_on_view_map_pressed)
	return_to_ui_button.pressed.connect(_on_return_to_ui_pressed)
	
	# combat to map ------------------------------------------------------------
	combat_controller.shell_fired.connect(battle_map.show_shooting_options)
	combat_controller.moab_exploded.connect(battle_map.apply_chamber_damage)
	
	# map to combat ------------------------------------------------------------
	battle_map.player_turn_started.connect(combat_controller.start_new_turn)
	battle_map.player_moved.connect(combat_controller.finalise_action)
	battle_map.shooting_canceled.connect(combat_controller.refund_shell)
	
	# UI visibility toggles ----------------------------------------------------
	combat_controller.shell_fired.connect(main_player_screen.hide.unbind(1))
	combat_controller.shell_fired.connect(return_to_ui_button.show.unbind(1))
	action_station.action_move_tank.connect(main_player_screen.hide)
	action_station.action_move_tank.connect(return_to_ui_button.show)
	battle_map.map_action_finished.connect(main_player_screen.show)
	battle_map.map_action_finished.connect(return_to_ui_button.hide)
	
	# map to UI-----------------------------------------------------------------
	action_station.action_move_tank.connect(battle_map.show_movement_options)
	
	# start the game -----------------------------------------------------------
	combat_controller.initialise_shells(starting_test_deck)

func _on_view_map_pressed():
	main_player_screen.hide()
	return_to_ui_button.show()

func _on_return_to_ui_pressed():
	return_to_ui_button.hide()
	main_player_screen.show()
	
	battle_map.cancel_movement_mode()
	battle_map.abort_shooting()
