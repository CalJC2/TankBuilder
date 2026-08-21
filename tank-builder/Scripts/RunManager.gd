extends Node

var selected_tank: TankData
var player_shells: Array[ShellData] = []
var map_visibility_range: int = 1

func reset_run():
	selected_tank = null
	player_shells.clear()
