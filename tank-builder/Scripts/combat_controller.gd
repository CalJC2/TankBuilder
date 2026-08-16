extends Node
class_name CombatController

#UI update signals
signal update_ui(current_shells: Array[ShellData])
signal turn_state_changed(hasActed: bool)
signal shell_fired(shell_data: ShellData)
signal actions_rolled(drafted_action: Array[String])
signal moab_exploded(damage_to_player: int)

const ACTION_POOL: Array[String] = ["Move Up 1", "Move Down 1", "Move Up 2", 
"Move Down 2", "Swap", "Reverse", "Send to Top", "Pin", "life Steal", "Panic Shuffle"]

var active_shells: Array[ShellData] = []
var has_used_action: bool = false

# Call this when combat starts
func initialise_shells(starting_shells: Array[ShellData]):
	active_shells.clear()
	
	for shell in starting_shells:
		var new_shell = shell.duplicate()
		new_shell.chamber_turns = 0
		active_shells.append(new_shell)
	
	active_shells.shuffle()
	start_new_turn()

func start_new_turn():
	has_used_action = false
	process_chamber_mechanics()
	
	var current_pool = ACTION_POOL.duplicate()
	current_pool.shuffle()
	var turn_actions: Array[String] = [current_pool[0], current_pool[1], current_pool[2]] 
	turn_state_changed.emit(has_used_action)
	update_ui.emit(active_shells)
	actions_rolled.emit(turn_actions)

# --- NEW SMART MOVEMENT LOGIC ---
func execute_smart_movement(direction: String, steps: int):
	var unpinned_indices = []
	var unpinned_shells = []
	
	# 1. Extract only the shells that can move
	for i in range(active_shells.size()):
		if not active_shells[i].is_pinned:
			unpinned_indices.append(i)
			unpinned_shells.append(active_shells[i])
			
	if unpinned_shells.size() <= 1:
		finalise_action()
		return
		
	# 2. Shift them around
	for step in range(steps):
		if direction == "up":
			unpinned_shells.push_back(unpinned_shells.pop_front())
		elif direction == "down":
			unpinned_shells.push_front(unpinned_shells.pop_back())
	
	if direction == "reverse":
		unpinned_shells.reverse()
		
	# 3. Slide them safely back into the empty unpinned slots!
	for i in range(unpinned_indices.size()):
		active_shells[unpinned_indices[i]] = unpinned_shells[i]
		
	finalise_action()

# Route the buttons to the smart movement function
func move_shells_up(): execute_smart_movement("up", 1)
func move_shells_down(): execute_smart_movement("down", 1)
func move_shells_up_twice(): execute_smart_movement("up", 2)
func move_shells_down_twice(): execute_smart_movement("down", 2)
func reverse_shells(): execute_smart_movement("reverse", 1)

# --- TARGETED & INSTANT ACTIONS ---
func toggle_pin(index: int):
	if index >= 0 and index < active_shells.size():
		active_shells[index].is_pinned = not active_shells[index].is_pinned
		print("Toggled pin on: ", active_shells[index].name)
		finalise_action()

func apply_life_steal():
	if not active_shells.is_empty():
		active_shells[0].has_life_steal = true # Applies to the chambered shell!
		print("Life Steal applied to: ", active_shells[0].name)
		finalise_action()
# moving shell actions


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

func process_chamber_mechanics():
	for i in range(active_shells.size() -1, -1, -1):
		var shell = active_shells[i]
		
		if shell.is_moab:
			shell.chamber_turns += 1
			shell.damage += 10
			
			if randf() < shell.explosion_chance:
				trigger_moab_explosion(i, shell.chamber_turns)
				break

func trigger_moab_explosion(moab_index: int, turns: int):
	# Turn 1 = 0 radius (itself). Turn 2 = 1 radius (3 shells). Turn 3 = 2 radius (5 shells).
	var blast_radius = max(0, turns - 1)
	
	var start_index = max(0, moab_index - blast_radius)
	var end_index = min(active_shells.size() - 1, moab_index + blast_radius)
	var destroyed_count = end_index - start_index + 1
	
	# Remove the shells from the chamber
	for j in range(destroyed_count):
		active_shells.remove_at(start_index)
		
	print("MOAB wiped out ", destroyed_count, " shells!")
	
	# If the active deck is completely destroyed, punish the player!
	if active_shells.is_empty():
		moab_exploded.emit(40) # Deal 40 damage to the player

func send_shell_to_top(index: int):
	if index <= 0 or index >= active_shells.size():
		return
	
	var shell = active_shells.pop_at(index)
	active_shells.push_front(shell)
	finalise_action()

func panic_shuffle():
	if active_shells.is_empty(): return
	
	var unpinned_indices = []
	var unpinned_shells = []
	
	# 1. Extract only the shells that can move
	for i in range(active_shells.size()):
		if not active_shells[i].is_pinned:
			unpinned_indices.append(i)
			unpinned_shells.append(active_shells[i])
			
	if unpinned_shells.size() <= 1:
		finalise_action()
		return
		
	# 2. Randomize them!
	unpinned_shells.shuffle()
		
	# 3. Slide them safely back into the empty unpinned slots
	for i in range(unpinned_indices.size()):
		active_shells[unpinned_indices[i]] = unpinned_shells[i]
		
	print("Panic Shuffle executed!")
	finalise_action()
