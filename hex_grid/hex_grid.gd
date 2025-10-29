@tool
class_name HexGrid
extends Control

@export var level: LevelData:
	set(value):
		level = value
		queue_redraw()

@export var hex_width: int = 100:
	set(value):
		hex_width = value
		queue_redraw()

@export var update: bool = false:
	set(value):
		update = false
		queue_redraw()

var grid_hexes: Dictionary[Vector2i, Hex] = {}


func _draw() -> void:
	for pos in grid_hexes:
		grid_hexes[pos].queue_free()
	
	grid_hexes = {}
	
	var hex_size := Vector2i(hex_width, ceili(hex_width * sqrt(3) / 2))
	
	var center_hex_position := Vector2(size) / 2 - Vector2(hex_size) / 2
	var up_vector := Vector2(0, -hex_width / 2.0 * sqrt(3))
	var right_vector := Vector2(3 * hex_width / 4.0, -hex_width / 4.0 * sqrt(3))
	
	for pos in level.hexes:
		var hex := Hex.new()
		
		hex.number = level.hexes[pos]
		hex.given = hex.number != 0
		
		add_child(hex)
		grid_hexes[pos] = hex
		
		hex.size = hex_size
		
		hex.position = center_hex_position + right_vector * pos.x + up_vector * pos.y
