extends Node
class_name HealthComponent

signal health_changed(current_health: int, max_health: int)
signal died

var max_health: int
var current_health: int

func initialise_health(starting_max_health: int):
	max_health = starting_max_health
	current_health = max_health
	health_changed.emit(current_health, max_health)

func take_damage(amount: int):
	# clamp health so it doesnt drop below 0
	current_health -= amount
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
