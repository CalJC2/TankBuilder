extends PanelContainer

signal action_move_tank
signal shell_action_selected(action_name: String)

# get the 2 vertical boxes that contain the buttons for actions
@onready var main_actions_menu = $MainActionMenu
@onready var shell_move_menu = $ShellMoveMenu

@onready var button_1 = $ShellMoveMenu/ActionButton1
@onready var button_2 = $ShellMoveMenu/ActionButton2
@onready var button_3 = $ShellMoveMenu/ActionButton3

func _ready():
	button_1.pressed.connect(_on_dynamic_action_pressed.bind(button_1))
	button_2.pressed.connect(_on_dynamic_action_pressed.bind(button_2))
	button_3.pressed.connect(_on_dynamic_action_pressed.bind(button_3))

func setup_drafted_actions(actions: Array[String]):
	button_1.text = actions[0]
	button_2.text = actions[1]
	button_3.text = actions[2]

func _on_dynamic_action_pressed(clicked_button: Button):
	shell_action_selected.emit(clicked_button.text)
	_on_back_button_pressed()

func _on_move_shells_button_pressed() -> void:
	main_actions_menu.hide()
	shell_move_menu.show()

func _on_back_button_pressed() -> void:
	shell_move_menu.hide()
	main_actions_menu.show()

func _on_move_tank_button_pressed() -> void:
	action_move_tank.emit()
