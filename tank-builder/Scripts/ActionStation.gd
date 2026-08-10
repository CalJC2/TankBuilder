extends PanelContainer

signal action_move_tank
signal move_shells_up
signal move_shells_down
signal swap_shells

# get the 2 vertical boxes that contain the buttons for actions
@onready var main_actions_menu = $MainActionMenu
@onready var shell_move_menu = $ShellMoveMenu

# menu swapping logic --------------------------------------------------
func _on_move_shells_button_pressed() -> void:
	main_actions_menu.hide()
	shell_move_menu.show()

func _on_back_button_pressed() -> void:
	shell_move_menu.hide()
	main_actions_menu.show()

# sending actions to the main screen ----------------------------------------------
func _on_move_up_button_pressed() -> void:
	move_shells_up.emit()
	_on_back_button_pressed()
	
func _on_move_down_button_pressed() -> void:
	move_shells_down.emit()
	_on_back_button_pressed()

func _on_swap_button_pressed() -> void:
	swap_shells.emit()
	_on_back_button_pressed()

func _on_move_tank_button_pressed() -> void:
	action_move_tank.emit()
