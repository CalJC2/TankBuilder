extends Button
class_name ShellSlot

@export var shell_icon: TextureRect
@export var shell_name: Label

func setup_shell(shell_data: ShellData):
	shell_name.text = shell_data.name
	if shell_data.icon:
		shell_icon.texture = shell_data.icon
	else:
		print("no shell icon available")
