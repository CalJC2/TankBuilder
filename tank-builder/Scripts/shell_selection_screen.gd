extends Control

@export var all_possible_shells: Array[ShellData] = []
@export var shell_slot_scene: PackedScene

var current_deck: Array[ShellData] = []
var max_deck_size: int = 10

@onready var available_grid = $CenterContainer/MainPanel/MarginContainer/MainSplit/AvailableSection/ScrollContainer/AvailableGrid
@onready var shell_list = $CenterContainer/MainPanel/MarginContainer/MainSplit/DeckSection/ScrollContainer/ShellList
@onready var deck_count_label = $CenterContainer/MainPanel/MarginContainer/MainSplit/DeckSection/DeckSectionLabel
@onready var start_button = $CenterContainer/MainPanel/MarginContainer/MainSplit/DeckSection/StartRunButton

func _ready():
	start_button.pressed.connect(_on_start_run_pressed)
	
	if RunManager.selected_tank:
		max_deck_size = RunManager.selected_tank.total_shells
	
	_show_available_shells()
	_update_deck_display()

func _show_available_shells():
	for shell in all_possible_shells:
		var shell_btn = shell_slot_scene.instantiate() as ShellSlot
		shell_btn.setup_shell(shell)
		
		shell_btn.pressed.connect(_add_shell_to_deck.bind(shell))
		available_grid.add_child(shell_btn)

func _add_shell_to_deck(shell: ShellData):
	if current_deck.size() < max_deck_size:
		current_deck.append(shell)
		_update_deck_display()
	else:
		print("Deck is full")

func _remove_shell_from_deck(index: int):
	current_deck.remove_at(index)
	_update_deck_display()

func _update_deck_display():
	for child in shell_list.get_children():
		child.queue_free()
	
	for i in range(current_deck.size()):
		var shell = current_deck[i]
		var shell_btn = shell_slot_scene.instantiate() as ShellSlot
		shell_btn.setup_shell(shell)
		
		shell_btn.pressed.connect(_remove_shell_from_deck.bind(i))
		shell_list.add_child(shell_btn)
	
	deck_count_label.text = "Selected Shells: %d / %d" % [current_deck.size(), max_deck_size]
	start_button.disabled = current_deck.size() == 0

func _on_start_run_pressed():
	RunManager.player_shells = current_deck.duplicate()
	
	get_tree().change_scene_to_file("res://Scenes/main.tscn")
