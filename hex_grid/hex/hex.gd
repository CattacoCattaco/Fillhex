@tool
class_name Hex
extends Control

enum State {
	NORMAL,
	HOVERED,
	PRESSED,
	HOVERED_PRESSED,
}

const COLORS: Array[Color] = [
	Color(0.6, 0.6, 0.6),
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
	Color(0.4, 0.4, 0.4),
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

const PRESSED_COLORS: Array[Color] = [
	Color(0.2, 0.2, 0.2),
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


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and not given:
				if number < len(COLORS) - 1:
					number += 1
				else:
					number = 0


func _mouse_entered() -> void:
	if given:
		return
	
	if state == State.NORMAL:
		state = State.HOVERED
	elif state == State.PRESSED:
		state = State.HOVERED_PRESSED
	
	if zoom_tween:
		zoom_tween.kill()
	zoom_tween = create_tween()
	
	zoom_tween.tween_property(self, "color", get_state_color(state), 0.1)
	zoom_tween.tween_property(self, "zoom_factor", 1.1, 0.15)
	z_index = 5


func _mouse_exited() -> void:
	if given:
		return
	
	if state == State.HOVERED:
		state = State.NORMAL
	elif state == State.HOVERED_PRESSED:
		state = State.PRESSED
	
	if zoom_tween:
		zoom_tween.kill()
	zoom_tween = create_tween()
	
	zoom_tween.tween_property(self, "zoom_factor", 1.0, 0.15)
	zoom_tween.tween_property(self, "color", get_state_color(state), 0.1)
	zoom_tween.tween_callback(reset_z)
	z_index = 4


func reset_z() -> void:
	z_index = 0


func _has_point(point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(point, get_hex())


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


func get_state_color(_state) -> Color:
	match _state:
		State.NORMAL:
			return COLORS[number]
		State.HOVERED:
			return HOVERED_COLORS[number]
		State.PRESSED, State.HOVERED_PRESSED:
			return PRESSED_COLORS[number]
	
	return BLACK


func get_scale_factor() -> float:
	return min(size.x / 2, size.y / sqrt(3))
