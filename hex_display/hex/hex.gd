@tool
class_name Hex
extends HexDisplay

enum Fulfillment {
	UNFULFILLED, # Not fulfilled but still room for fulfillment
	FULFILLED, # Fulfilled
	OVERDONE, # Too many of something
}

enum EndShader {
	GREEN,
	DISSOLVE,
}

const END_SHADERS: Array[Shader] = [
	preload("res://hex_display/hex/end_shaders/green.gdshader"),
	preload("res://hex_display/hex/end_shaders/dissolve.gdshader"),
]

@export var given: bool = true:
	set(value):
		given = value
		if not hex_grid.in_setup:
			hex_grid.hex_data[pos].given = given
		queue_redraw()

@export var clue_type: HexData.ClueType = HexData.ClueType.DEFAULT:
	set(value):
		clue_type = value
		if not hex_grid.in_setup:
			hex_grid.hex_data[pos].clue_type = value
		queue_redraw()
		tween_to_state()
		
		if not is_tool:
			hex_grid.check_for_solution()
		elif not hex_grid.in_setup:
			hex_grid.save_level()

@export_flags(
		"Top Left",
		"Top",
		"Top Right",
		"Bottom Right",
		"Bottom",
		"Bottom Left",
		) var borders: int = 0:
	set(value):
		borders = value
		if not hex_grid.in_setup:
			hex_grid.hex_data[pos].borders = value
		queue_redraw()
		tween_to_state()
		
		if not is_tool:
			hex_grid.check_for_solution()
		elif not hex_grid.in_setup:
			hex_grid.save_level()

var fulfillment: Fulfillment = Fulfillment.UNFULFILLED:
	set(value):
		fulfillment = value
		queue_redraw()

var hex_grid: HexGrid
var pos: Vector2i

var about_to_free: bool = false


func _ready() -> void:
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)


func _draw() -> void:
	super()
	
	var scale_factor: float = get_scale_factor()
	
	if borders:
		var border_points := PackedVector2Array()
		for i in len(HexGrid.ORTHOGONALS):
			if (borders >> i) & 1:
				border_points.append_array(get_border_points(i as HexGrid.Orthogonal))
		
		var border_thickness: float = max(scale_factor * 0.07, 2.5)
		draw_multiline(border_points, BORDER_COLOR, border_thickness)
	
	if number > 0:
		var font: Font = get_theme_default_font()
		var font_size: int = floori(scale_factor * 0.7 * zoom_factor)
		var text_width: int = floori(
				font.get_string_size(str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		
		var hex_center := Vector2(scale_factor, scale_factor * sqrt(3) / 2)
		var text_pos := Vector2(hex_center.x - text_width / 2.0, hex_center.y + font_size / 2.0 - 4)
		
		var line_thickness: float = max(scale_factor * 0.06, 2)
		if given:
			var underline_start := text_pos + Vector2(0, scale_factor * 0.08)
			var underline_end := text_pos + Vector2(text_width, scale_factor * 0.08)
			draw_line(underline_start, underline_end, BLACK, line_thickness)
		
		match clue_type:
			HexData.ClueType.CIRCLE:
				draw_circle(hex_center, text_width * 1.25, BLACK, false, line_thickness)
			HexData.ClueType.TRIANGLE:
				var center := Vector2(hex_center.x, hex_center.y * 1.15)
				var points: PackedVector2Array
				points = get_regular_polygon(center, text_width * 0.85, 3)
				draw_polyline(points, BLACK, line_thickness)
			HexData.ClueType.RECTANGLE:
				var height: float = (font_size + scale_factor * 0.24 + line_thickness * 2)
				var width: float = (text_width + scale_factor * 0.16 + line_thickness)
				
				var half_thickness: float =  line_thickness / 2
				var start_x: float = text_pos.x - scale_factor * 0.08 - half_thickness
				var start_y: float = text_pos.y - font_size - scale_factor * 0.08 - half_thickness
				
				var rect := Rect2(start_x, start_y, width, height)
				
				draw_rect(rect, BLACK, false, line_thickness)
			HexData.ClueType.PENTAGON:
				var points: PackedVector2Array
				points = get_regular_polygon(hex_center, text_width * 1.25, 5)
				draw_polyline(points, BLACK, line_thickness)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and is_selected():
		if event.is_action_pressed("hex_10s"):
			if not (is_tool and clue_type == HexData.ClueType.RECTANGLE):
				return
			
			if 11 <= number and number <= 19:
				number -= 10
			else:
				number = number % 10 + 10
		elif event.is_action_pressed("hex_20s"):
			if not (is_tool and clue_type == HexData.ClueType.RECTANGLE):
				return
			
			if 21 <= number and number <= 29:
				number -= 20
			elif number == 20:
				number = 10
			else:
				number = number % 10 + 20
		elif event.is_action_pressed("hex_30s"):
			if not (is_tool and clue_type == HexData.ClueType.RECTANGLE):
				return
			
			if 31 <= number and number <= 39:
				number -= 30
			elif number == 30:
				number = 10
			else:
				number = number % 10 + 30
		elif event.is_action_pressed("hex_40s"):
			if not (is_tool and clue_type == HexData.ClueType.RECTANGLE):
				return
			
			if 41 <= number and number <= 49:
				number -= 40
			elif number == 40:
				number = 10
			else:
				number = number % 10 + 40
		elif event.is_action_pressed("hex_50s"):
			if not (is_tool and clue_type == HexData.ClueType.RECTANGLE):
				return
			
			if 51 <= number and number <= 59:
				number -= 50
			elif number == 50:
				number = 10
			else:
				number = number % 10 + 50
		elif event.is_action_pressed("hex_60"):
			if not (is_tool and clue_type == HexData.ClueType.RECTANGLE):
				return
			
			if number == 60:
				number = 10
			else:
				number = 60
		elif event.is_action_pressed("hex_1"):
			number = 1
		elif event.is_action_pressed("hex_2"):
			number = 2
		elif event.is_action_pressed("hex_3"):
			number = 3
		elif event.is_action_pressed("hex_4"):
			number = 4
		elif event.is_action_pressed("hex_5"):
			number = 5
		elif event.is_action_pressed("hex_6"):
			number = 6
		elif event.is_action_pressed("hex_7"):
			number = 7
		elif event.is_action_pressed("hex_8"):
			number = 8
		elif event.is_action_pressed("hex_9"):
			number = 9
		elif event.is_action_pressed("hex_10"):
			number = 10
		elif event.is_action_pressed("hex_clear"):
			if number == 0 and is_tool:
				number = -1
				select_deselect()
				return
			
			number = 0
		elif event.is_action_pressed("hex_deselect"):
			select_deselect()
		elif event.is_action_pressed("hex_circle"):
			if is_tool:
				if clue_type != HexData.ClueType.CIRCLE:
					clue_type = HexData.ClueType.CIRCLE
				else:
					clue_type = HexData.ClueType.DEFAULT
		elif event.is_action_pressed("hex_triangle"):
			if is_tool:
				if clue_type != HexData.ClueType.TRIANGLE:
					clue_type = HexData.ClueType.TRIANGLE
				else:
					clue_type = HexData.ClueType.DEFAULT
		elif event.is_action_pressed("hex_rectangle"):
			if is_tool:
				if clue_type != HexData.ClueType.RECTANGLE:
					clue_type = HexData.ClueType.RECTANGLE
				else:
					if number > 10:
						number = number % 10
						if number == 0:
							number = 10
					
					clue_type = HexData.ClueType.DEFAULT
		elif event.is_action_pressed("hex_pentagon"):
			if is_tool:
				if clue_type != HexData.ClueType.PENTAGON:
					clue_type = HexData.ClueType.PENTAGON
				else:
					clue_type = HexData.ClueType.DEFAULT
		elif event.is_action_pressed("hex_bottom_right"):
			if is_tool:
				flip_border(HexGrid.Orthogonal.DOWN_RIGHT, HexGrid.Orthogonal.UP_LEFT)
		elif event.is_action_pressed("hex_bottom"):
			if is_tool:
				flip_border(HexGrid.Orthogonal.DOWN, HexGrid.Orthogonal.UP)
		elif event.is_action_pressed("hex_bottom_left"):
			if is_tool:
				flip_border(HexGrid.Orthogonal.DOWN_LEFT, HexGrid.Orthogonal.UP_RIGHT)
		elif event.is_action_pressed("hex_top_left"):
			if is_tool:
				flip_border(HexGrid.Orthogonal.UP_LEFT, HexGrid.Orthogonal.DOWN_RIGHT)
		elif event.is_action_pressed("hex_top"):
			if is_tool:
				flip_border(HexGrid.Orthogonal.UP, HexGrid.Orthogonal.DOWN)
		elif event.is_action_pressed("hex_top_right"):
			if is_tool:
				flip_border(HexGrid.Orthogonal.UP_RIGHT, HexGrid.Orthogonal.DOWN_LEFT)
		else:
			return
		get_viewport().set_input_as_handled()


func _left_clicked() -> void:
	if number == -1:
		number = 0
	elif is_tool or not given:
		select_deselect()
	elif hex_grid.selected_hex:
		hex_grid.selected_hex.select_deselect()


func _right_clicked() -> void:
	if is_tool:
		number = -1
	elif not given:
		number = 0


func _dragged(event: InputEventMouseMotion) -> void:
	hex_grid.offset += event.relative


func select_deselect() -> void:
	match state:
		State.SELECTED:
			state = State.NORMAL
			
			if hex_grid.selected_hex == self:
				hex_grid.selected_hex = null
		State.HOVERED_SELECTED:
			state = State.HOVERED
			
			if hex_grid.selected_hex == self:
				hex_grid.selected_hex = null
		State.NORMAL:
			state = State.SELECTED
			
			if hex_grid.selected_hex and hex_grid.selected_hex != self:
				hex_grid.selected_hex.select_deselect()
			
			hex_grid.selected_hex = self
		State.HOVERED:
			state = State.HOVERED_SELECTED
			
			if hex_grid.selected_hex and hex_grid.selected_hex != self:
				hex_grid.selected_hex.select_deselect()
			hex_grid.selected_hex = self
	
	tween_to_state()


## Returns the points of a regular polygon for special clues
func get_regular_polygon(center: Vector2, apothem: float, side_count: int) -> PackedVector2Array:
	var circumradius: float = apothem / cos(PI / side_count)
	
	var points := PackedVector2Array()
	
	for i in range(side_count + 1):
		var theta: float = 2 * PI * i / side_count
		points.append(center + circumradius * Vector2(sin(theta), -cos(theta)))
	
	return points


func get_border_points(side: HexGrid.Orthogonal) -> PackedVector2Array:
	var scale_factor: float = get_scale_factor()
	var points := PackedVector2Array()
	
	match side:
		HexGrid.Orthogonal.UP_LEFT:
			points.append(Vector2(0, scale_factor * sqrt(3) / 2))
			points.append(Vector2(scale_factor / 2, 0))
		HexGrid.Orthogonal.UP:
			points.append(Vector2(scale_factor / 2, 0))
			points.append(Vector2(3 * scale_factor / 2, 0))
		HexGrid.Orthogonal.UP_RIGHT:
			points.append(Vector2(3 * scale_factor / 2, 0))
			points.append(Vector2(2 * scale_factor, scale_factor * sqrt(3) / 2))
		HexGrid.Orthogonal.DOWN_RIGHT:
			points.append(Vector2(2 * scale_factor, scale_factor * sqrt(3) / 2))
			points.append(Vector2(3 * scale_factor / 2, scale_factor * sqrt(3)))
		HexGrid.Orthogonal.DOWN:
			points.append(Vector2(3 * scale_factor / 2, scale_factor * sqrt(3)))
			points.append(Vector2(scale_factor / 2, scale_factor * sqrt(3)))
		HexGrid.Orthogonal.DOWN_LEFT:
			points.append(Vector2(scale_factor / 2, scale_factor * sqrt(3)))
			points.append(Vector2(0, scale_factor * sqrt(3) / 2))
	
	return points


func _get_state_color(_state: State) -> Color:
	match _state:
		State.NORMAL:
			if number == -1:
				var translucent_color: Color = COLORS[0]
				translucent_color.a = 0.5
				return translucent_color
			elif clue_type != HexData.ClueType.DEFAULT or number > 10:
				return COLORS[11]
			
			return COLORS[number]
		State.HOVERED:
			if number == -1:
				var translucent_color: Color = HOVERED_COLORS[0]
				translucent_color.a = 0.5
				return translucent_color
			elif clue_type != HexData.ClueType.DEFAULT or number > 10:
				return HOVERED_COLORS[11]
			
			return HOVERED_COLORS[number]
		State.SELECTED, State.HOVERED_SELECTED:
			if number == -1:
				var translucent_color: Color = SELECTED_COLORS[0]
				translucent_color.a = 0.5
				return translucent_color
			elif clue_type != HexData.ClueType.DEFAULT or number > 10:
				return SELECTED_COLORS[11]
			
			return SELECTED_COLORS[number]
	
	return BLACK


func _get_text_color() -> Color:
	if fulfillment == Fulfillment.UNFULFILLED:
		return BLACK
	elif fulfillment == Fulfillment.FULFILLED:
		return GOOD_COLOR
	else:
		return BAD_COLOR


func set_shader_time(time: float) -> void:
	var shader_material: ShaderMaterial = material
	shader_material.set_shader_parameter("time", time)


func flip_border(direction: HexGrid.Orthogonal, inverse: HexGrid.Orthogonal) -> void:
	var neighbor_pos: Vector2i = pos + HexGrid.ORTHOGONALS[direction]
	if neighbor_pos not in hex_grid.grid_hexes:
		return
	
	borders ^= 1 << direction
	var neighbor: Hex = hex_grid.grid_hexes[neighbor_pos]
	if (borders >> direction) & 1 != (neighbor.borders >> inverse) & 1:
		neighbor.borders ^= 1 << inverse
