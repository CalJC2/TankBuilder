extends Control

@export var combat_controller: CombatController
@export var shell_slot_scene: PackedScene

@onready var action_station = $MainHBox/RightSideBox/ActionStationContainer
@onready var shoot_button = $MainHBox/RightSideBox/ShootButton
@onready var shell_list = $MainHBox/ShellPanel/ShellContainter

var is_selecting_swap: bool = false
var swap_index_1: int = -1

func _ready():
	combat_controller.update_ui.connect(_on_update_ui)
	combat_controller.turn_state_changed.connect(_on_turn_state_changed)
	
	action_station.move_shells_up.connect(combat_controller.move_shells_up())
	action_station.move_shells_down.connect(combat_controller.move_shells_down())
	action_station.swap_shells.connect(_start_swap_selection)
	shoot_button.pressed.connect(combat_controller.shoot_top_shell())

func _on_update_ui(shells: Array[ShellData]):
	for child in shell_list.get_children():
		child.queue_free()
	
	var index = 0
	for shell in shells:
		var shell_btn = shell_slot_scene.instantiate() as ShellSlot
		shell_btn.setup_shell(shell)
		
		shell_btn.pressed.connect(_on_shell_tapped.bind(index))
		shell_list.add_child(shell_btn)
		index += 1

func _on_turn_state_changed(has_acted: bool):
	shoot_button.disabled = not has_acted
	if has_acted:
		action_station.modulate = Color(0.5,0.5,0.5,1)
	else:
		action_station.modulate = Color(1,1,1,1)


func _start_swap_selection():
	is_selecting_swap = true
	swap_index_1 = -1
	print("Tap two shells to swap")

func _on_shell_tapped(index: int):
	if is_selecting_swap:
		if swap_index_1 == -1:
			swap_index_1 = index
			print("first shell selected")
			#optional: highlight the tapped shell button visualyl
		else:
			combat_controller.swap_shells(swap_index_1, index)
			is_selecting_swap = false
			swap_index_1 = -1
