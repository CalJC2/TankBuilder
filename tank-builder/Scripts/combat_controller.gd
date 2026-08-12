extends Node
class_name CombatController

#UI update signals
signal update_ui(current_shells: Array[ShellData])
signal turn_state_changed(hasActed: bool)
signal shell_fired(shell_data: ShellData)
signal actions_rolled(drafted_action: Array[String])

const ACTION_POOL: Array[String] = ["Move Up 1", "Move Down 1", "Move Up 2", "Move Down 2", "Swap"]

var active_shells: Array[ShellData] = []
var has_used_action: bool = false

# Call this when combat starts
func initialise_shells(starting_shells: Array[ShellData]):
	active_shells = starting_shells.duplicate()
	active_shells.shuffle()
	start_new_turn()

func start_new_turn():
	has_used_action = false
	
	var current_pool = ACTION_POOL.duplicate()
	current_pool.shuffle()
	var turn_actions: Array[String] = [current_pool[0], current_pool[1], current_pool[2]] 
	turn_state_changed.emit(has_used_action)
	update_ui.emit(active_shells)
	actions_rolled.emit(turn_actions)

# moving shell actions
func move_shells_up():
	if active_shells.is_empty(): return
	
	active_shells.push_back(active_shells.pop_front())
	finalise_action()
	
func move_shells_down():
	if active_shells.is_empty(): return
	
	active_shells.push_front(active_shells.pop_back())
	finalise_action()

func move_shells_down_twice():
	if active_shells.is_empty(): return
	
	active_shells.push_front(active_shells.pop_back())
	active_shells.push_front(active_shells.pop_back())
	finalise_action()


func move_shells_up_twice():
	if active_shells.is_empty(): return
	
	active_shells.push_back(active_shells.pop_front())
	active_shells.push_back(active_shells.pop_front())
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
	shell_fired.emit(fired_shell)
	print("Fired: ", fired_shell.name)
	update_ui.emit(active_shells)
