extends Node2D

@onready var health_component = $HealthComponent

func setup_obstacle(max_health: int):
	health_component.initialise_health(max_health)
	health_component.died.connect(_on_died)

func _on_died():
	queue_free()
