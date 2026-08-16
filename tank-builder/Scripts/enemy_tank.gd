extends Node2D

class_name EnemyTank

@onready var turret = $TankTurret
@onready var health_component = $HealthComponent

var current_grid_pos: Vector2i

func enemy_setup(start_pos: Vector2i, max_health: int, starting_armour: int = 0):
	current_grid_pos = start_pos
	health_component.initialise_health(max_health, starting_armour)
	
	health_component.died.connect(_on_died)

func _on_died():
	#will emit a signal later to let the BattleMap know to free up the tile
	
	queue_free()

func aim_turret(target_pixel_pos: Vector2):
	var tween = create_tween()
	
	#calculate angle
	var target_angle = turret.global_position.direction_to(target_pixel_pos).angle()
	#rotate turret
	tween.tween_property(turret, "global_rotation", target_angle, 0.3)
	await tween.finished
