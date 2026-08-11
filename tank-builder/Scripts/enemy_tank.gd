extends Node2D

class_name EnemyTank

@onready var turret = $TankTurret
@onready var health_component = $HealthComponent

var current_grif_pos: Vector2i

func enemy_setup(start_pos: Vector2i, max_health: int):
	current_grif_pos = start_pos
	health_component.initialise_health(max_health)
	
	health_component.died.connect(_on_died)

func _on_died():
	#will emit a signal later to let the BattleMap know to free up the tile
	
	queue_free()
