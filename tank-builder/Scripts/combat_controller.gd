extends Node
class_name CombatController

#UI update signals
signal update_ui(current_shells: Array[ShellData])
signal turn_state_changed(hasActed: bool)

var active_shells: Array[ShellData] = []
var has_used_action: bool = false

# Call this when combat starts
func initialise_shells(starting_shells: Array[ShellData]):
	active_shells = starting_shells.duplicate()
	active_shells.shuffle()
	start_new_turn()

func start_new_turn():
	has_used_action = false
	turn_state_changed.emit(has_used_action)
	update_ui.emit(active_shells)

# moving shell actions
func move_shells_up():
	if active_shells.is_empty(): return
	
	active_shells.push_back(active_shells.pop_front())
	finalise_action()
	
func move_shells_down():
	if active_shells.is_empty(): return
	
	active_shells.push_front(active_shells.pop_back())
	finalise_action()

func swap_shells(index_a:int, index_b: int):
	if index_a < 0 or index_b < 0 or index_a >= active_shells.size() or index_b >= active_shells.size():
		return
	
	var temp = active_shells[index_a]
	active_shells[index_a] = active_shells[index_b]
	active_shells[index_b] = temp
	finalise_action()

func finalise_action():
	has_used_action = true
	turn_state_changed.emit(has_used_action)
	update_ui.emit(active_shells)

# end of turn actions
func shoot_top_shell():
	if active_shells.is_empty(): return
	
	var fired_shell = active_shells.pop_front()
	print("Fired: ", fired_shell.name)
	update_ui.emit(active_shells)
