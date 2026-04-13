class_name LevelData
extends Resource

@export var hexes: Dictionary[Vector2i, HexData]


func _init(p_hexes: Dictionary[Vector2i, HexData] = {}) -> void:
	hexes = p_hexes
