@tool
class_name Hex
extends Control

enum State {
	NORMAL,
	HOVERED,
	SELECTED,
	HOVERED_SELECTED,
}

enum Fulfillment {
	UNFULFILLED, # Not fulfilled but still room for fulfillment
	FULFILLED, # Fulfilled
	OVERDONE, # Too many of something
}

enum EndShader {
	GREEN,
	DISSOLVE,
}

const COLORS: Array[Color] = [
	Color(0.7, 0.7, 0.7),
	Color(1, 0.6, 0.75),
	Color(1, 0.7, 0.65),
	Color(1, 0.9, 0.7),
	Color(0.7, 1, 0.7),
	Color(0.5, 1, 0.8),
	Color(0.5, 0.9, 1),
	Color(0.55, 0.75, 1),
	Color(0.7, 0.7, 1),
	Color(0.85, 0.65, 1),
	Color(1, 0.7, 0.9),
	Color(1.0, 0.5, 0.85),
]

const HOVERED_COLORS: Array[Color] = [
	Color(0.55, 0.55, 0.55),
	Color(0.8, 0.48, 0.5),
	Color(0.8, 0.56, 0.52),
	Color(0.8, 0.72, 0.52),
	Color(0.52, 0.8, 0.52),
	Color(0.4, 0.8, 0.64),
	Color(0.4, 0.72, 0.8),
	Color(0.44, 0.6, 0.8),
	Color(0.56, 0.56, 0.8),
	Color(0.68, 0.52, 0.8),
	Color(0.8, 0.56, 0.72),
	Color(0.8, 0.4, 0.68),
]

const SELECTED_COLORS: Array[Color] = [
	Color(0.4, 0.4, 0.4),
	Color(0.64, 0.384, 0.4),
	Color(0.64, 0.448, 0.416),
	Color(0.64, 0.576, 0.416),
	Color(0.416, 0.64, 0.416),
	Color(0.32, 0.64, 0.512),
	Color(0.32, 0.576, 0.64),
	Color(0.352, 0.48, 0.64),
	Color(0.448, 0.448, 0.64),
	Color(0.544, 0.416, 0.64),
	Color(0.64, 0.448, 0.576),
	Color(0.64, 0.32, 0.544),
]

const BLACK := Color.BLACK
const GOOD_COLOR := Color(0.52, 1.0, 0.52)
const BAD_COLOR := Color(1.0, 0.3, 0.42)
const BORDER_COLOR := Color(0.94, 0.38, 0.28)

const END_SHADERS: Array[Shader] = [
	preload("res://game/hex_grid/hex/end_shaders/green.gdshader"),
	preload("res://game/hex_grid/hex/end_shaders/dissolve.gdshader"),
]

@export var number: int = 1:
	set(value):
		number = value
		if not hex_grid.in_setup:
			hex_grid.hex_data[pos].number = number
		queue_redraw()
		tween_to_state()
		
		if not is_tool:
			hex_grid.check_for_solution()
		elif not hex_grid.in_setup:
			hex_grid.save_level()

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

@export var update: bool = false:
	set(value):
		update = false
		queue_redraw()


@onready var color: Color = get_state_color(state):
	set(value):
		color = value
		queue_redraw()


var state: State = State.NORMAL:
	set(value):
		if about_to_free:
			return
		
		if hex_grid.in_end:
			if state == State.NORMAL:
				return
			
			state = State.NORMAL
			queue_redraw()
			return
		
		state = value
		hex_grid.hex_data[pos].state = state
		
		queue_redraw()

var fulfillment: Fulfillment = Fulfillment.UNFULFILLED:
	set(value):
		fulfillment = value
		queue_redraw()

var zoom_factor: float = 1.0:
	set(value):
		zoom_factor = value
		queue_redraw()

var zoom_tween: Tween

var hex_grid: HexGrid
var pos: Vector2i
var is_tool: bool = false

var about_to_free: bool = false


func _ready() -> void:
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)


func _draw() -> void:
	var scale_factor: float = get_scale_factor()
	
	var corners: PackedVector2Array = get_hex_zoomed()
	var uvs: PackedVector2Array = get_uvs()
	
	draw_colored_polygon(corners, color, uvs)
	
	#draw_polyline(corners, BLACK, max(scale_factor * 0.1, 3))
	
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
		
		var text_color: Color = BLACK
		if fulfillment == Fulfillment.FULFILLED:
			text_color = GOOD_COLOR
		elif fulfillment == Fulfillment.OVERDONE:
			text_color = BAD_COLOR
		
		draw_string(font, text_pos, str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
				text_color)
		
		if text_color != BLACK:
			draw_string_outline(font, text_pos, str(number), HORIZONTAL_ALIGNMENT_LEFT, -1,
					font_size, 3, BLACK)
		
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
		elif event.is_action_pressed("hex_20s"):
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


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if number == -1:
				number = 0
			elif is_tool or not given:
				select_deselect()
			elif hex_grid.selected_hex:
				hex_grid.selected_hex.select_deselect()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_tool:
				number = -1
			elif not given:
				number = 0
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			hex_grid.offset += event.relative


func _mouse_entered() -> void:
	if state == State.NORMAL:
		state = State.HOVERED
	elif state == State.SELECTED:
		state = State.HOVERED_SELECTED
	
	tween_to_state()


func _mouse_exited() -> void:
	if state == State.HOVERED:
		state = State.NORMAL
	elif state == State.HOVERED_SELECTED:
		state = State.SELECTED
	
	tween_to_state()


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, get_hex_zoomed())


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


func get_hex() -> PackedVector2Array:
	var scale_factor: float = get_scale_factor()
	
	return PackedVector2Array([
		Vector2(scale_factor / 2, 0),
		Vector2(3 * scale_factor / 2, 0),
		Vector2(scale_factor * 2, scale_factor * sqrt(3) / 2),
		Vector2(3 * scale_factor / 2, scale_factor * sqrt(3)),
		Vector2(scale_factor / 2, scale_factor * sqrt(3)),
		Vector2(0, scale_factor * sqrt(3) / 2),
		Vector2(scale_factor / 2, 0),
	])


func get_uvs() -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(1 / 4.0, 0),
		Vector2(3 / 4.0, 0),
		Vector2(1, 1 / 2.0),
		Vector2(3 / 4.0, 1),
		Vector2(1 / 4.0, 1),
		Vector2(0, 1 / 2.0),
		Vector2(1 / 4.0, 0),
	])


func get_hex_zoomed() -> PackedVector2Array:
	var scale_factor: float = get_scale_factor()
	
	var offset := Vector2(scale_factor * 2, scale_factor * sqrt(3)) * (1 - zoom_factor) / 2
	
	var zoomed: PackedVector2Array = get_hex()
	
	for i in len(zoomed):
		zoomed[i] = zoomed[i] * zoom_factor + offset
	
	return zoomed


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


func tween_to_state() -> void:
	if zoom_tween:
		zoom_tween.kill()
	zoom_tween = create_tween().set_parallel()
	
	zoom_tween.tween_property(self, "color", get_state_color(state), 0.1)
	zoom_tween.tween_property(self, "zoom_factor", get_state_zoom(state), 0.15)
	z_index = get_state_z(state)


func display_state() -> void:
	color = get_state_color(state)
	zoom_factor = get_state_zoom(state)
	z_index = get_state_z(state)


func get_state_color(_state) -> Color:
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


func get_state_zoom(_state) -> float:
	match _state:
		State.NORMAL:
			return 0.9
		State.SELECTED, State.HOVERED_SELECTED, State.HOVERED:
			return 0.925
	
	return 0.9


func get_state_z(_state) -> int:
	match _state:
		State.NORMAL:
			return 0
		State.HOVERED:
			return 5
		State.SELECTED, State.HOVERED_SELECTED:
			return 10
	
	return 1


func get_scale_factor() -> float:
	return min(size.x / 2, size.y / sqrt(3))


func is_selected() -> bool:
	return state in [State.SELECTED, State.HOVERED_SELECTED]


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
