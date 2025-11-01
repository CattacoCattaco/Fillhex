@tool
class_name HexGrid
extends Control

const ORTHOGONALS: Array[Vector2i] = [
	Vector2i(-1, 1),
	Vector2i(0, 1),
	Vector2i(1, 0),
	Vector2i(1, -1),
	Vector2i(0, -1),
	Vector2i(-1, 0),
]

@export var level_manager: LevelManager

@export var is_tool: bool = false

@export var update: bool = false:
	set(value):
		update = false
		display()

var level: LevelData:
	set(value):
		level = value
		if not just_saved:
			in_setup = true
			hex_data = {}
		just_saved = false
		display()

var grid_hexes: Dictionary[Vector2i, Hex] = {}
var hex_data: Dictionary[Vector2i, HexData] = {}

var selected_hex: Hex
var in_setup: bool = false
var just_saved: bool = false


func _ready() -> void:
	display()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selected_hex:
				selected_hex.select_deselect()


func display() -> void:
	if not level:
		return
	
	in_setup = true
	
	print("setup start")
	
	for pos in grid_hexes:
		grid_hexes[pos].about_to_free = true
		grid_hexes[pos].queue_free()
	
	grid_hexes = {}
	
	selected_hex = null
	
	var starting_hexes: Dictionary[Vector2i, int] = level.hexes.duplicate()
	
	if is_tool:
		var radius: int = 0
		for pos in starting_hexes:
			var distance_from_center: int = get_distance(Vector2i(0, 0), pos)
			
			if distance_from_center > radius:
				radius = distance_from_center
		
		for pos in get_tiles_in_radius(radius):
			if pos not in starting_hexes:
				starting_hexes[pos] = -1
	
	var hex_size := Vector2(1, sqrt(3) / 2)
	
	var up_vector := Vector2(0, -1 / 2.0 * sqrt(3))
	var right_vector := Vector2(3 / 4.0, -1 / 4.0 * sqrt(3))
	
	var top_left := Vector2(0, 0)
	var bottom_right := Vector2(0, 0)
	
	for pos in starting_hexes:
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
	
	for pos in starting_hexes:
		var hex := Hex.new()
		
		if not hex_data.has(pos):
			var number: int = starting_hexes[pos]
			var state: Hex.State = Hex.State.NORMAL
			var is_given: bool = starting_hexes[pos] != 0 and not is_tool
			
			hex_data[pos] = HexData.new(number, state, is_given)
		
		hex.hex_grid = self
		hex.pos = pos
		hex.is_tool = is_tool
		
		hex.number = hex_data[pos].number
		hex.state = hex_data[pos].state
		hex.given = hex_data[pos].given
		
		if hex.is_selected():
			selected_hex = hex
		
		add_child(hex)
		grid_hexes[pos] = hex
		
		hex.size = hex_size
		
		hex.position = center_hex_position + right_vector * pos.x + up_vector * pos.y
	
	print("setup end")
	in_setup = false


func check_for_solution() -> void:
	if in_setup:
		return
	
	var unchecked_hexes: Array[Vector2i] = []
	
	for pos in grid_hexes:
		if grid_hexes[pos].number == 0:
			return
		
		unchecked_hexes.append(pos)
	
	while len(unchecked_hexes) > 0:
		var hex: Hex = grid_hexes[unchecked_hexes[0]]
		var group: Array[Vector2i] = get_group(unchecked_hexes[0])
		
		if len(group) != hex.number:
			return
		
		for pos in group:
			unchecked_hexes.erase(pos)
	
	level_manager.next_level()


func get_group(pos: Vector2i, found: Array[Vector2i] = []) -> Array[Vector2i]:
	var group_number: int = grid_hexes[pos].number
	found.append(pos)
	
	for direction in ORTHOGONALS:
		if not grid_hexes.has(pos + direction):
			continue
		
		var neighbor: Hex = grid_hexes[pos + direction]
		if neighbor.number == group_number and neighbor.pos not in found:
			get_group(neighbor.pos, found)
	
	return found


func get_distance(start: Vector2i, end: Vector2i) -> int:
	if start == end:
		return 0
	elif start.x < end.x and start.y > end.y:
		return get_distance(start + Vector2i(1, -1), end) + 1
	elif start.x > end.x and start.y < end.y:
		return get_distance(start + Vector2i(-1, 1), end) + 1
	elif start.x < end.x:
		return get_distance(start + Vector2i(1, 0), end) + 1
	elif start.x > end.x:
		return get_distance(start + Vector2i(-1, 0), end) + 1
	elif start.y < end.y:
		return get_distance(start + Vector2i(0, 1), end) + 1
	else:
		return get_distance(start + Vector2i(0, -1), end) + 1


func get_tiles_in_radius(radius: int) -> Array[Vector2i]:
	if radius == 0:
		return []
	
	var found: Array[Vector2i] = [Vector2i(0, 0)]
	
	for i in len(ORTHOGONALS):
		var direction_a: Vector2i = ORTHOGONALS[i]
		var direction_b: Vector2i = (
				ORTHOGONALS[i + 1] if i + 1 < len(ORTHOGONALS) else ORTHOGONALS[0])
		
		found.append_array(get_triangle_of_hexes(direction_a, direction_a, direction_b, radius - 1))
	
	return found


func get_triangle_of_hexes(from: Vector2i, direction_a: Vector2i, direction_b: Vector2i,
		max_distance: int) -> Array[Vector2i]:
	var found: Array[Vector2i] = [from]
	
	for distance in range(1, max_distance + 1):
		for i in range(distance + 1):
			found.append(from + direction_a * i + direction_b * (distance - i))
	
	return found


func save_level() -> void:
	var p_level: LevelData = load(level.resource_path)
	
	for pos in hex_data:
		if hex_data[pos].number == -1:
			p_level.hexes.erase(pos)
		else:
			p_level.hexes[pos] = hex_data[pos].number
	
	ResourceSaver.save(p_level)
	
	just_saved = true
	level = p_level
