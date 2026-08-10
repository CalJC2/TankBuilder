extends Button
class_name ShellSlot

@onready var shell_icon = $HBoxContainer/ShellIcon
@onready var shell_name = $HBoxContainer/ShellName

func setup_shell(shell_data: ShellData):
	shell_name.text = shell_data.name
	if shell_data.icon:
		shell_icon.texture = shell_data.icon
	else:
		print("no shell icon available")
