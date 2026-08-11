extends Node2D
class_name PlayerTank

@export var tank_data: TankData

@onready var turret = $TankTurret
@onready var health_component = $HealthComponent

func _ready():
	if tank_data:
		health_component.initialise_health(tank_data.max_health)
	
	health_component.died.connect(_on_tank_died)

func _on_tank_died():
	print("Game Over")

func aim_turret(target_pixel_pos: Vector2):
	var tween = create_tween()
	
	#calculate angle
	var target_angle = turret.global_position.direction_to(target_pixel_pos).angle()
	#rotate turret
	tween.tween_property(turret, "global_rotation", target_angle, 0.3)
	await tween.finished
