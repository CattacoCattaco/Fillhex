class_name LevelData
extends Resource

@export var hexes: Dictionary[Vector2i, int]


func _init(_hexes: Dictionary[Vector2i, int] = {}) -> void:
	hexes = _hexes
