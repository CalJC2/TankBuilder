extends Resource
class_name ShellData

@export_group("Shell Information")
@export var name: String
@export var icon: Texture2D
@export var damage: int
@export var max_range: int
@export var is_arcing: bool


@export_group("Advanced Mechanics")
@export var is_piercing: bool = false
@export var splash_radius: int = 0
@export var dot_damage: int = 0
@export var dot_duration: int

@export_group("Status Effects")
@export var cryo_duration: int = 0
@export var emp_duration: int = 0
@export var vulnerable_duration: int = 0

@export_group("Grid Manipulation")
@export var is_grapple: bool = false
@export var knockback_distance: int = 0
@export var spawns_obstacles: bool = false
@export var obstacle_icon: Texture2D
@export var spawns_smoke: bool = false
@export var smoke_icon: Texture2D

@export_group("Tile Hazards")
@export var hazard_type: String = ""
@export var hazard_duration: int = 0
@export var hazard_damage: int = 0

@export_group("Chamber Mechanics")
@export var is_moab: bool = false
@export var explosion_chance: float = 0.25

var chamber_turns: int = 0
