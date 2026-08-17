extends Control


@export var available_tanks: Array[TankData] = []
var current_index: int = 0

@onready var prev_button = $CenterContainer/MainPanel/MarginContainer/MainSplit/TopRow/PrevButton
@onready var next_button = $CenterContainer/MainPanel/MarginContainer/MainSplit/TopRow/NextButton
@onready var select_button = $CenterContainer/MainPanel/MarginContainer/MainSplit/BottomRow/SelectButton

@onready var tank_name = $CenterContainer/MainPanel/MarginContainer/MainSplit/TopRow/TankDisplay/TankName
@onready var tank_image = $CenterContainer/MainPanel/MarginContainer/MainSplit/TopRow/TankDisplay/TankImage
@onready var stats_label = $CenterContainer/MainPanel/MarginContainer/MainSplit/BottomRow/StatsLabel

func _ready():
	prev_button.pressed.connect(_on_prev_pressed)
	next_button.pressed.connect(_on_next_pressed)
	select_button.pressed.connect(_on_select_pressed)
	
	if available_tanks.size() > 0:
		_update_display()

func _update_display():
	var current_tank = available_tanks[current_index]
	
	tank_name.text = current_tank.tank_class_name
	tank_image.texture = current_tank.tank_full_image
	
	stats_label.text = "Max Health: %d\nArmour: %d\nMovement Range: %d\nTotal Shells: %d" % [
		current_tank.max_health,
		current_tank.armour,
		current_tank.movement_range,
		current_tank.total_shells
	]
	

func _on_prev_pressed():
	current_index -= 1
	if current_index < 0:
		current_index = available_tanks.size() - 1
	_update_display()

func _on_next_pressed():
	current_index += 1
	if current_index >= available_tanks.size():
		current_index = 0
	_update_display()

func _on_select_pressed():
	var chosen_tank = available_tanks[current_index]
	
	RunManager.selected_tank = chosen_tank
	
	get_tree().change_scene_to_file("res://Scenes/shell_selection_screen.tscn")
