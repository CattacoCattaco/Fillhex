@tool
class_name LevelManager
extends Node

@export var current_level: int = 0
@export var hex_grid: HexGrid

var levels: Array[LevelData] = []


func _ready() -> void:
	var i: int = 0
	var path: String = "res://game/hex_grid/level/data/levels/level_%d.tres" % i
	
	while FileAccess.file_exists(path):
		levels.append(load(path))
		
		i += 1
		path = "res://game/hex_grid/level/data/levels/level_%d.tres" % i
	
	load_level(current_level)


func next_level() -> void:
	if current_level >= len(levels) - 1:
		return
	
	load_level(current_level + 1)


func load_level(level_num: int) -> void:
	if level_num >= len(levels):
		return
	
	current_level = level_num
	
	hex_grid.level = levels[level_num]
