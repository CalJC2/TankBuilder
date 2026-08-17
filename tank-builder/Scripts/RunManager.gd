extends Node

var selected_tank: TankData
var player_shells: Array[ShellData] = []

func reset_run():
	selected_tank = null
	player_shells.clear()
