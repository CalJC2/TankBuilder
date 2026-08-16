extends Node

@export var starting_test_deck: Array[ShellData]

@onready var battle_map = $BattleMap
@onready var combat_controller = $CombatController
@onready var action_station = $UILayer/MainPlayerScreen/MainHBox/RightSideBox/ActionStationContainer
@onready var main_player_screen = $UILayer/MainPlayerScreen

func _ready() -> void:
	# combat to map ------------------------------------------------------------
	combat_controller.shell_fired.connect(battle_map.show_shooting_options)
	combat_controller.moab_exploded.connect(battle_map.apply_chamber_damage)
	
	# map to combat ------------------------------------------------------------
	battle_map.player_turn_started.connect(combat_controller.start_new_turn)
	battle_map.player_moved.connect(combat_controller.finalise_action)
	
	# UI visibility toggles ----------------------------------------------------
	combat_controller.shell_fired.connect(main_player_screen.hide.unbind(1))
	action_station.action_move_tank.connect(main_player_screen.hide)
	battle_map.map_action_finished.connect(main_player_screen.show)
	
	# map to UI-----------------------------------------------------------------
	action_station.action_move_tank.connect(battle_map.show_movement_options)
	
	# start the game -----------------------------------------------------------
	combat_controller.initialise_shells(starting_test_deck)
