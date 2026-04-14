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

@onready var coord_converter := Node2D.new()

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
var in_end: bool = false
var in_setup: bool = false
var just_saved: bool = false

var zoom: float = 1.0:
	set(value):
		zoom = value
		display()

var zoom_factor_per_scroll: float = 1.1

var offset := Vector2(0, 0):
	set(value):
		offset = value
		display()

var noise_texture: NoiseTexture2D


func _ready() -> void:
	add_child(coord_converter)
	display()
	regenerate_noise_texture()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if selected_hex:
					if not in_end:
						selected_hex.select_deselect()
			elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
				offset *= zoom_factor_per_scroll
				zoom *= zoom_factor_per_scroll
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				if zoom / zoom_factor_per_scroll <= 1:
					offset = offset / zoom
					zoom = 1
					return
				
				offset /= zoom_factor_per_scroll
				zoom /= zoom_factor_per_scroll
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			offset += event.relative


func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			display()


func display() -> void:
	if not level:
		return
	
	in_setup = true
	
	for pos in grid_hexes:
		grid_hexes[pos].about_to_free = true
		grid_hexes[pos].queue_free()
	
	grid_hexes = {}
	
	selected_hex = null
	
	var starting_hexes: Dictionary[Vector2i, HexData] = level.hexes.duplicate()
	
	if is_tool:
		var radius: int = 0
		for pos in starting_hexes:
			var distance_from_center: int = get_distance(Vector2i(0, 0), pos)
			
			if distance_from_center > radius:
				radius = distance_from_center
		
		for pos in get_tiles_in_radius(radius):
			if pos not in starting_hexes:
				starting_hexes[pos] = HexData.new(-1)
	
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
			size.y * 0.8 / (abs_max.y * sqrt(3)), 150)) * zoom
	
	hex_size *= hex_width
	hex_size = hex_size.ceil()
	
	up_vector *= hex_width
	right_vector *= hex_width
	
	var center_hex_position := Vector2(size) / 2 - Vector2(hex_size) / 2
	
	for pos in starting_hexes:
		var hex := Hex.new()
		
		if not hex_data.has(pos):
			hex_data[pos] = starting_hexes[pos]
		
		hex.hex_grid = self
		hex.pos = pos
		hex.is_tool = is_tool
		
		hex.number = hex_data[pos].number
		hex.state = Hex.State.NORMAL
		hex.given = hex_data[pos].given
		hex.clue_type = hex_data[pos].clue_type
		
		if hex.is_selected():
			selected_hex = hex
		
		add_child(hex)
		grid_hexes[pos] = hex
		
		hex.size = hex_size
		
		hex.position = center_hex_position + right_vector * pos.x + up_vector * pos.y + offset
		
		hex.display_state()
	
	in_setup = false
	
	if not is_tool:
		check_for_solution()


func check_for_solution() -> void:
	if in_setup:
		return
	
	var success: bool = true
	
	var unchecked_hexes: Array[Vector2i] = []
	
	for pos in grid_hexes:
		if grid_hexes[pos].number == 0:
			success = false
		else:
			unchecked_hexes.append(pos)
	
	while len(unchecked_hexes) > 0:
		var hex: Hex = grid_hexes[unchecked_hexes[-1]]
		
		match hex.clue_type:
			HexData.ClueType.DEFAULT:
				var group: Array[Vector2i] = get_group(unchecked_hexes[-1])
				
				var fulfillment: Hex.Fulfillment
				if len(group) < hex.number:
					fulfillment = Hex.Fulfillment.UNFULFILLED
				elif len(group) == hex.number:
					fulfillment = Hex.Fulfillment.FULFILLED
				else:
					fulfillment = Hex.Fulfillment.OVERDONE
				
				if fulfillment != Hex.Fulfillment.FULFILLED:
					success = false
				
				for pos in group:
					grid_hexes[pos].fulfillment = fulfillment
					unchecked_hexes.erase(pos)
			HexData.ClueType.CIRCLE:
				hex.fulfillment = Hex.Fulfillment.UNFULFILLED
				
				for neighbor_pos: Vector2i in get_neighbors(hex.pos):
					var neighbor: Hex = grid_hexes[neighbor_pos]
					
					if neighbor.clue_type != HexData.ClueType.DEFAULT:
						continue
					
					if neighbor.number == hex.number:
						hex.fulfillment = Hex.Fulfillment.FULFILLED
				
				if hex.fulfillment != Hex.Fulfillment.FULFILLED:
					success = false
				
				unchecked_hexes.pop_back()
			HexData.ClueType.TRIANGLE:
				var appearance_counts: Array[int] = []
				for i in range(10):
					appearance_counts.append(0)
				
				for neighbor_pos in get_neighbors(hex.pos):
					var neighbor: Hex = grid_hexes[neighbor_pos]
					if neighbor.number > 0:
						appearance_counts[neighbor.number - 1] += 1
				
				var biggest_appearance_count: int = 0
				
				for appearance_count in appearance_counts:
					if appearance_count > biggest_appearance_count:
						biggest_appearance_count = appearance_count
				
				if biggest_appearance_count < hex.number:
					hex.fulfillment = Hex.Fulfillment.UNFULFILLED
				elif biggest_appearance_count == hex.number:
					hex.fulfillment = Hex.Fulfillment.FULFILLED
				else:
					hex.fulfillment = Hex.Fulfillment.OVERDONE
				
				if hex.fulfillment != Hex.Fulfillment.FULFILLED:
					success = false
				
				unchecked_hexes.pop_back()
			HexData.ClueType.RECTANGLE:
				var sum: int = 0
				
				for neighbor_pos in get_neighbors(hex.pos):
					var neighbor: Hex = grid_hexes[neighbor_pos]
					if neighbor.number > 0:
						sum += neighbor.number
				
				if sum < hex.number:
					hex.fulfillment = Hex.Fulfillment.UNFULFILLED
				elif sum == hex.number:
					hex.fulfillment = Hex.Fulfillment.FULFILLED
				else:
					hex.fulfillment = Hex.Fulfillment.OVERDONE
				
				if hex.fulfillment != Hex.Fulfillment.FULFILLED:
					success = false
				
				unchecked_hexes.pop_back()
	
	if success:
		print("You win")
		await do_end()
		level_manager.next_level()


func do_end() -> void:
	var last_selected_hex: Hex = selected_hex
	
	in_end = true
	
	for pos in grid_hexes:
		if grid_hexes[pos].state != Hex.State.NORMAL:
			grid_hexes[pos].state = Hex.State.NORMAL
	
	var end_anim_index: int = randi_range(0, len(Hex.END_SHADERS) - 1)
	
	match end_anim_index:
		Hex.EndShader.GREEN:
			await do_green_end(last_selected_hex)
		Hex.EndShader.DISSOLVE:
			await do_dissolve_end(last_selected_hex)
	
	in_end = false


func do_green_end(last_selected_hex: Hex) -> void:
	var end_anim_shader: Shader = Hex.END_SHADERS[Hex.EndShader.GREEN]
	var untouched_hexes: Array[Vector2i] = []
	
	for pos in grid_hexes:
		untouched_hexes.append(pos)
	
	var prev_gen: Array[Vector2i] = []
	
	while len(untouched_hexes) > 0:
		var new_gen: Array[Vector2i] = []
		
		if prev_gen:
			var random_pos: Vector2i = untouched_hexes.pick_random()
			
			new_gen.append(random_pos)
			untouched_hexes.erase(random_pos)
			
			for pos in prev_gen:
				for neighbor in get_neighbors(pos):
					if neighbor in untouched_hexes:
						untouched_hexes.erase(neighbor)
						new_gen.append(neighbor)
		else:
			new_gen = [last_selected_hex.pos]
			
			untouched_hexes.erase(last_selected_hex.pos)
		
		var tween: Tween = get_tree().create_tween().set_parallel()
		
		for pos in new_gen:
			var hex: Hex = grid_hexes[pos]
			
			var hex_material := ShaderMaterial.new()
			hex_material.shader = end_anim_shader
			
			hex.z_index = 6
			
			hex.material = hex_material
			
			tween.tween_method(hex.set_shader_time, 0.0, 1.0, 2)
		
		await get_tree().create_timer(1.25).timeout
		
		tween = get_tree().create_tween().set_parallel()
		
		for pos in new_gen:
			var hex: Hex = grid_hexes[pos]
			
			hex.z_index = 10
			
			hex.pivot_offset = hex.size / 2.0
			
			var top_left: Vector2 = coord_converter.to_local(Vector2(-250, -250))
			var bottom_right: Vector2 = coord_converter.to_local(
					get_viewport_rect().size + Vector2(250, 250))
			
			var end_side: int = randi_range(0, 3)
			var end_position: Vector2
			
			match end_side:
				0:
					end_position = Vector2(top_left.x, randf_range(top_left.y, bottom_right.y))
				1:
					end_position = Vector2(randf_range(top_left.x, bottom_right.x), top_left.y)
				2:
					end_position = Vector2(bottom_right.x, randf_range(top_left.y, bottom_right.y))
				3:
					end_position = Vector2(randf_range(top_left.x, bottom_right.x), bottom_right.y)
			
			tween.tween_property(hex, "rotation", randf_range(-30 * PI, 30 * PI), 6)
			tween.tween_property(hex, "position", end_position, 6)
		
		prev_gen = new_gen
	
	await get_tree().create_timer(6.25).timeout


func do_dissolve_end(last_selected_hex: Hex) -> void:
	var end_anim_shader: Shader = Hex.END_SHADERS[Hex.EndShader.DISSOLVE]
	var untouched_hexes: Array[Vector2i] = []
	
	for pos in grid_hexes:
		untouched_hexes.append(pos)
	
	var prev_gen: Array[Vector2i] = []
	
	while len(untouched_hexes) > 0:
		var new_gen: Array[Vector2i] = []
		
		if prev_gen:
			var random_pos: Vector2i = untouched_hexes.pick_random()
			
			new_gen.append(random_pos)
			untouched_hexes.erase(random_pos)
			
			for pos in prev_gen:
				for neighbor in get_neighbors(pos):
					if neighbor in untouched_hexes:
						untouched_hexes.erase(neighbor)
						new_gen.append(neighbor)
		else:
			new_gen = [last_selected_hex.pos]
			
			untouched_hexes.erase(last_selected_hex.pos)
		
		var tween: Tween = get_tree().create_tween().set_parallel()
		
		for pos in new_gen:
			var hex: Hex = grid_hexes[pos]
			
			hex.z_index = 6
			
			var hex_material := ShaderMaterial.new()
			hex_material.shader = end_anim_shader
			
			hex_material.set_shader_parameter("noise", noise_texture)
			
			hex.material = hex_material
			
			tween.tween_method(hex.set_shader_time, 0.0, 1.0, 2.5)
		
		await get_tree().create_timer(2).timeout
		
		prev_gen = new_gen
	
	regenerate_noise_texture()


func get_group(pos: Vector2i, found: Array[Vector2i] = []) -> Array[Vector2i]:
	var group_number: int = grid_hexes[pos].number
	found.append(pos)
	
	for neighbor_pos in get_neighbors(pos):
		var neighbor: Hex = grid_hexes[neighbor_pos]
		if (neighbor.number == group_number and neighbor.clue_type == HexData.ClueType.DEFAULT
				and neighbor.pos not in found):
			get_group(neighbor_pos, found)
	
	return found


func get_neighbors(pos: Vector2i) -> Array[Vector2i]:
	var neighbors: Array[Vector2i] = []
	
	for direction in ORTHOGONALS:
		if grid_hexes.has(pos + direction):
			neighbors.append(pos + direction)
	
	return neighbors


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


func regenerate_noise_texture() -> void:
	noise_texture = NoiseTexture2D.new()
	noise_texture.width = 1024
	noise_texture.height = 1024
	
	var noise := FastNoiseLite.new()
	noise.frequency = 0.005
	noise_texture.noise = noise
	
	await noise_texture.changed


func save_level() -> void:
	var p_level: LevelData = load(level.resource_path)
	
	for pos in hex_data:
		if hex_data[pos].number == -1:
			p_level.hexes.erase(pos)
		else:
			p_level.hexes[pos] = hex_data[pos]
			p_level.hexes[pos].given = hex_data[pos].number != 0
			if hex_data[pos].number == 0:
				p_level.hexes[pos].clue_type = HexData.ClueType.DEFAULT
	
	ResourceSaver.save(p_level)
	
	just_saved = true
	level = p_level
