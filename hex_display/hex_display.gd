@tool
@abstract
class_name HexDisplay
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

@export var number: int = 1:
	set(value):
		number = value
		if self is Hex and not self.hex_grid.in_setup:
			self.hex_grid.hex_data[self.pos].number = number
		queue_redraw()
		tween_to_state()
		
		if self is not Hex:
			return
		
		if not is_tool:
			self.hex_grid.check_for_solution()
		elif not self.hex_grid.in_setup:
			self.hex_grid.save_level()

@export var update: bool = false:
	set(value):
		update = false
		queue_redraw()


@onready var color: Color = _get_state_color(state):
	set(value):
		color = value
		queue_redraw()


var state: State = State.NORMAL:
	set(value):
		if self is Hex and self.about_to_free:
			return
		
		if self is Hex and self.hex_grid.in_end:
			if state == State.NORMAL:
				return
			
			state = State.NORMAL
			queue_redraw()
			return
		
		state = value
		if self is Hex:
			self.hex_grid.hex_data[self.pos].state = state
		
		queue_redraw()

var zoom_factor: float = 1.0:
	set(value):
		zoom_factor = value
		queue_redraw()

var zoom_tween: Tween

var is_tool: bool = false


func _ready() -> void:
	mouse_entered.connect(_mouse_entered)
	mouse_exited.connect(_mouse_exited)


func _draw() -> void:
	var scale_factor: float = get_scale_factor()
	
	var corners: PackedVector2Array = get_hex_zoomed()
	var uvs: PackedVector2Array = get_uvs()
	
	draw_colored_polygon(corners, color, uvs)
	
	if number > 0:
		var font: Font = get_theme_default_font()
		var font_size: int = floori(scale_factor * 0.7 * zoom_factor)
		var text_width: int = floori(
				font.get_string_size(str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
		
		var hex_center := Vector2(scale_factor, scale_factor * sqrt(3) / 2)
		var text_pos := Vector2(hex_center.x - text_width / 2.0, hex_center.y + font_size / 2.0 - 4)
		
		var text_color: Color = _get_text_color()
		
		draw_string(font, text_pos, str(number), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
				text_color)
		
		if text_color != BLACK:
			draw_string_outline(font, text_pos, str(number), HORIZONTAL_ALIGNMENT_LEFT, -1,
					font_size, 3, BLACK)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_left_clicked()
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			_right_clicked()
	elif event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_dragged(event)


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


func _left_clicked() -> void:
	pass


func _right_clicked() -> void:
	pass


func _dragged(_event: InputEventMouseMotion) -> void:
	pass


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, get_hex_zoomed())


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


func tween_to_state() -> void:
	if zoom_tween:
		zoom_tween.kill()
	zoom_tween = create_tween().set_parallel()
	
	zoom_tween.tween_property(self, "color", _get_state_color(state), 0.1)
	zoom_tween.tween_property(self, "zoom_factor", get_state_zoom(state), 0.15)
	z_index = get_state_z(state)


func display_state() -> void:
	color = _get_state_color(state)
	zoom_factor = get_state_zoom(state)
	z_index = get_state_z(state)


@abstract func _get_state_color(_state: State) -> Color

func get_state_zoom(_state: State) -> float:
	match _state:
		State.NORMAL:
			return 0.9
		State.SELECTED, State.HOVERED_SELECTED, State.HOVERED:
			return 0.925
	
	return 0.9


func get_state_z(_state: State) -> int:
	match _state:
		State.NORMAL:
			return 0
		State.HOVERED:
			return 5
		State.SELECTED, State.HOVERED_SELECTED:
			return 10
	
	return 1


@abstract func _get_text_color() -> Color


func get_scale_factor() -> float:
	return min(size.x / 2, size.y / sqrt(3))


func is_selected() -> bool:
	return state in [State.SELECTED, State.HOVERED_SELECTED]
