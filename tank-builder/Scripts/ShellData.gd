extends Resource

class_name ShellData

@export_group("Shell Information")
@export var name: String
@export var icon: Texture2D
@export var damage: float
@export var max_range: int
@export var tiles_effected: int


@export_group("Types Of Effect")
@export var is_penetrating: bool
@export var is_DOT: bool
@export var is_arcing: bool
