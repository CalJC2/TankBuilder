extends Node
class_name CombatController

var active_shells: Array[ShellData] = []

# Call this when combat starts
func initialise_shells(starting_shells: Array[ShellData]):
	active_shells = starting_shells.duplicate()
	active_shells.shuffle()
	update_ui()

# moving shell actions
func move_shells_up():
	if active_shells.is_empty(): return
	
	var top_shell = active_shells.pop_front()
	active_shells.push_back(top_shell)
	update_ui()

func move_shells_down():
	if active_shells.is_empty(): return
	
	var bottom_shell = active_shells.pop_back()
	active_shells.push_front(bottom_shell)
	update_ui()

func swap_shells(index_a:int, index_b: int):
	if index_a < 0 or index_b < 0 or index_a >= active_shells.size() or index_b >= active_shells.size():
		return
	
	var temp = active_shells[index_a]
	active_shells[index_a] = active_shells[index_b]
	active_shells[index_b] = temp
	update_ui()

# end of turn actions
func shoot_top_shell():
	if active_shells.is_empty(): return
	
	var fired_shell = active_shells.pop_front()
	print("Fired: ", fired_shell.name)
	update_ui()

func update_ui():
	pass
