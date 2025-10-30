@tool
class_name Hex
extends Control

enum State {
	NORMAL,
	HOVERED,
	SELECTED,
	HOVERED_SELECTED,
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
]

const BLACK = Color.BLACK


@export var number: int = 1:
	set(value):
		number = value
		color = get_state_color(state)
		queue_redraw()

@export var given: bool = true:
	set(value):
		given = value
		queue_redraw()

@export var update: bool = false:
	set(value):
		update = false
		queue_redraw()


@onready var color: Color = COLORS[number]:
	set(value):
		color = value
		queue_redraw()


var state: State = State.NORMAL:
	set(value):
		state = value
		queue_redraw()

var zoom_factor: float = 1.0:
	set(value):
		zoom_factor = value
		queue_redraw()

var zoom_tween: Tween

var hex_grid: HexGrid


func _ready() -> void:
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)


func _draw() -> void:
	var scale_factor: float = get_scale_factor()
	
	var corners: PackedVector2Array = get_hex_zoomed()
	
	draw_colored_polygon(corners, color)
	
	draw_polyline(corners, BLACK, max(scale_factor * 0.1, 3))
	
	if number != 0:
		var font: Font = get_theme_default_font()
		var font_size: int = floori(scale_factor * 0.7 * zoom_factor)
		var text_width: int = floori(
				font.get_string_size(str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		
		var hex_center := Vector2(scale_factor, scale_factor * sqrt(3) / 2)
		var text_pos := Vector2(hex_center.x - text_width / 2.0, hex_center.y + font_size / 2.0 - 4)
		draw_string(font, text_pos, str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, BLACK)
		
		if given:
			var underline_start := text_pos + Vector2(0, 5)
			var underline_end := text_pos + Vector2(text_width, 5)
			draw_line(underline_start, underline_end, BLACK, 5)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and is_selected():
		if event.is_action_pressed("hex_1"):
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
			number = 2
		elif event.is_action_pressed("hex_10"):
			number = 10
		elif event.is_action_pressed("hex_clear"):
			number = 0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not given:
				select_deselect()


func _mouse_entered() -> void:
	if given:
		return
	
	if state == State.NORMAL:
		state = State.HOVERED
	elif state == State.SELECTED:
		state = State.HOVERED_SELECTED
	
	if not is_selected():
		tween_to_state()


func _mouse_exited() -> void:
	if given:
		return
	
	if state == State.HOVERED:
		state = State.NORMAL
	elif state == State.HOVERED_SELECTED:
		state = State.SELECTED
	
	if not is_selected():
		tween_to_state()


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, get_hex())


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
			
			if hex_grid.selected_hex:
				hex_grid.selected_hex.select_deselect()
			hex_grid.selected_hex = self
		State.HOVERED:
			state = State.HOVERED_SELECTED
			
			if hex_grid.selected_hex:
				hex_grid.selected_hex.select_deselect()
			hex_grid.selected_hex = self
	
	tween_to_state()


func reset_z() -> void:
	z_index = 0


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


func get_hex_zoomed() -> PackedVector2Array:
	var scale_factor: float = get_scale_factor()
	
	var offset := Vector2(scale_factor * 2, scale_factor * sqrt(3)) * (1 - zoom_factor) / 2
	
	var zoomed: PackedVector2Array = get_hex()
	
	for i in len(zoomed):
		zoomed[i] = zoomed[i] * zoom_factor + offset
	
	return zoomed


func tween_to_state() -> void:
	if zoom_tween:
		zoom_tween.kill()
	zoom_tween = create_tween().set_parallel()
	
	zoom_tween.tween_property(self, "color", get_state_color(state), 0.1)
	zoom_tween.tween_property(self, "zoom_factor", get_state_zoom(state), 0.15)
	z_index = get_state_z(state)


func get_state_color(_state) -> Color:
	match _state:
		State.NORMAL:
			return COLORS[number]
		State.HOVERED:
			return HOVERED_COLORS[number]
		State.SELECTED, State.HOVERED_SELECTED:
			return SELECTED_COLORS[number]
	
	return BLACK


func get_state_zoom(_state) -> float:
	match _state:
		State.NORMAL:
			return 1.0
		State.SELECTED, State.HOVERED_SELECTED, State.HOVERED:
			return 1.1
	
	return 1.0


func get_state_z(_state) -> int:
	match _state:
		State.NORMAL:
			return 1
		State.HOVERED:
			return 5
		State.SELECTED, State.HOVERED_SELECTED:
			return 10
	
	return 1


func get_scale_factor() -> float:
	return min(size.x / 2, size.y / sqrt(3))


func is_selected() -> bool:
	return state in [State.SELECTED, State.HOVERED_SELECTED]
