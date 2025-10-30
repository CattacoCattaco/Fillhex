@tool
class_name HexGrid
extends Control

@export var level: LevelData:
	set(value):
		level = value
		queue_redraw()

@export var update: bool = false:
	set(value):
		update = false
		queue_redraw()

var grid_hexes: Dictionary[Vector2i, Hex] = {}
var hex_data: Dictionary[Vector2i, HexData] = {}

var selected_hex: Hex


func _draw() -> void:
	for pos in grid_hexes:
		grid_hexes[pos].queue_free()
	
	grid_hexes = {}
	
	selected_hex = null
	
	var hex_size := Vector2(1, sqrt(3) / 2)
	
	var up_vector := Vector2(0, -1 / 2.0 * sqrt(3))
	var right_vector := Vector2(3 / 4.0, -1 / 4.0 * sqrt(3))
	
	var top_left := Vector2(0, 0)
	var bottom_right := Vector2(0, 0)
	
	for pos in level.hexes:
		var hex_position: Vector2 = right_vector * pos.x + up_vector * pos.y
		var hex_top_left := Vector2(hex_position - Vector2(hex_size) / 2.0)
		var hex_bottom_right := Vector2(hex_position + Vector2(hex_size) / 2.0)
		
		if hex_top_left.x < top_left.x:
			top_left.x = floor(hex_top_left.x * 20) / 20
		if hex_top_left.y < top_left.y:
			top_left.y = floor(hex_top_left.y * 20) / 20
		if hex_bottom_right.x > bottom_right.x:
			bottom_right.x = ceil(hex_bottom_right.x * 20) / 20
		if hex_bottom_right.y > bottom_right.y:
			bottom_right.y = ceil(hex_bottom_right.y * 20) / 20
	
	var abs_max := Vector2(max(abs(top_left.x), bottom_right.x),
			max(abs(top_left.y), bottom_right.y))
	
	var hex_width: int = floor(min(size.x * 0.8 / (2 * abs_max.x),
			size.y * 0.8 / (abs_max.y * sqrt(3)), 150))
	
	hex_size *= hex_width
	hex_size = hex_size.ceil()
	
	up_vector *= hex_width
	right_vector *= hex_width
	
	var center_hex_position := Vector2(size) / 2 - Vector2(hex_size) / 2
	
	for pos in level.hexes:
		var hex := Hex.new()
		
		if not hex_data.has(pos):
			var number: int = level.hexes[pos]
			var state: Hex.State = Hex.State.NORMAL
			var is_given: bool = level.hexes[pos] != 0
			
			hex_data[pos] = HexData.new(number, state, is_given)
		
		hex.hex_grid = self
		hex.pos = pos
		
		hex.number = hex_data[pos].number
		hex.state = hex_data[pos].state
		hex.given = hex_data[pos].given
		
		if hex.is_selected():
			selected_hex = hex
		
		add_child(hex)
		grid_hexes[pos] = hex
		
		hex.size = hex_size
		
		hex.position = center_hex_position + right_vector * pos.x + up_vector * pos.y


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selected_hex:
				selected_hex.select_deselect()
