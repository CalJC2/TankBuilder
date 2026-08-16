extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal died

var max_health: int
var current_health: int
var armour: int = 0

var active_dots: Array[Dictionary] = []

var cryo_turns: int = 0
var emp_turns: int = 0
var vulnerable_turns: int = 0

func initialise_health(starting_max_health: int, starting_armour: int = 0):
	max_health = starting_max_health
	current_health = max_health
	armour = starting_armour
	active_dots.clear()
	cryo_turns = 0
	emp_turns = 0
	vulnerable_turns = 0
	health_changed.emit(current_health, max_health)

func take_damage(amount: int, ignores_armour: bool = false):
	var final_damage = amount
	
	if not ignores_armour:
		final_damage -= armour
		final_damage = max(1, final_damage)
	
	if vulnerable_turns > 0:
		final_damage *= 2
	
	# clamp health so it doesnt drop below 0
	current_health -= final_damage
	current_health = max(0, current_health)
	
	health_changed.emit(current_health, max_health)
	
	if current_health == 0:
		died.emit()

func heal_to_max():
	current_health = max_health
	health_changed.emit(current_health, max_health)

func heal(amount: int):
	current_health += amount
	current_health = min(current_health, max_health)
	
	health_changed.emit(current_health, max_health)

func apply_dot(damage_per_turn: int, duration_in_turns: int):
	if duration_in_turns > 0 and damage_per_turn >0:
		active_dots.append({"Damage": damage_per_turn, "turns_left": duration_in_turns})

func apply_status(type: String, duration: int):
	match type:
		"cryo":
			cryo_turns = max(cryo_turns, duration)
		"emp":
			emp_turns = max(emp_turns, duration)
		"vulnerable":
			vulnerable_turns = max(vulnerable_turns, duration)

func process_start_of_turn_effects():
	var total_dot_damage = 0
	
	for i in range(active_dots.size() -1, -1, -1):
		var dot = active_dots[i]
		total_dot_damage += dot["Damage"]
		dot["turns_left"] -= 1
		
		if dot["turns_left"] <= 0: 
			active_dots.remove_at(i)
	
	if total_dot_damage > 0:
		take_damage(total_dot_damage, true)
	
	if cryo_turns > 0: cryo_turns -= 1
	if emp_turns > 0: emp_turns -= 1
	if vulnerable_turns > 0: vulnerable_turns -= 1
