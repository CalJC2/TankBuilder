extends Control

@export var combat_controller: CombatController
@export var shell_slot_scene: PackedScene

@onready var action_station = $MainHBox/RightSideBox/ActionStationContainer
@onready var shoot_button = $MainHBox/RightSideBox/ShootButton
@onready var shell_list = $MainHBox/ShellPanel/ShellContainter

var targeting_mode: String = ""
var swap_index_1: int = -1

func _ready():
	# listen to Combat Controller ---------------------------------------------
	combat_controller.update_ui.connect(_on_update_ui)
	combat_controller.turn_state_changed.connect(_on_turn_state_changed)
	combat_controller.actions_rolled.connect(action_station.setup_drafted_actions)
	
	# listen to UI inputs ------------------------------------------------------
	shoot_button.pressed.connect(combat_controller.shoot_top_shell)
	action_station.shell_action_selected.connect(_route_selected_action)
	

func _route_selected_action(action_name: String):
	match action_name:
		"Move Up 1":
			combat_controller.move_shells_up()
		"Move Down 1":
			combat_controller.move_shells_down()
		"Move Up 2":
			combat_controller.move_shells_up_twice()
		"Move Down 2":
			combat_controller.move_shells_down_twice()
		"Swap":
			_start_targeting("swap")
		"Reverse":
			combat_controller.reverse_shells()
		"Send to Top":
			_start_targeting("send_to_top")
		"Pin":
			_start_targeting("pin")
		"Life Steal":
			combat_controller.apply_life_steal()
		"Panic Shuffle":
			combat_controller.panic_shuffle()

func _on_update_ui(shells: Array[ShellData]):
	for child in shell_list.get_children():
		child.queue_free()
	
	targeting_mode = ""
	swap_index_1 = -1
	
	for index in range(shells.size()):
		var shell = shells[index]
		var shell_btn = shell_slot_scene.instantiate() as ShellSlot
		shell_btn.setup_shell(shell)
		
		shell_btn.pressed.connect(_on_shell_tapped.bind(index))
		shell_list.add_child(shell_btn)

func _on_turn_state_changed(has_acted: bool):
	if has_acted:
		action_station.modulate = Color(0.5,0.5,0.5,1)
	else:
		action_station.modulate = Color(1,1,1,1)

func _start_targeting(mode: String):
	targeting_mode = mode
	swap_index_1 = -1

func _on_shell_tapped(index: int):
	if targeting_mode == "swap":
		if swap_index_1 == -1:
			swap_index_1 = index
			print("first shell selected")
			#optional: highlight the tapped shell button visualyl
		else:
			combat_controller.swap_shells(swap_index_1, index)
			targeting_mode = ""
			swap_index_1 = -1
	elif targeting_mode == "send_to_top":
		combat_controller.send_shell_to_top(index)
		targeting_mode = ""
	elif targeting_mode == "pin":
		combat_controller.toggle_pin(index)
		targeting_mode = ""
