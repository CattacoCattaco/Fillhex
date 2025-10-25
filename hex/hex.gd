@tool
class_name Hex
extends Control

const COLORS: Array[Color] = [
	Color(0.5, 0.5, 0.5),
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

@export var number: int = 1:
	set(value):
		number = value
		queue_redraw()


@export var update: bool = false:
	set(value):
		update = false
		queue_redraw()

var label: Label


func _draw() -> void:
	var scale_factor: float = get_scale_factor()
	
	var corners: PackedVector2Array = get_hex()
	
	draw_colored_polygon(corners, COLORS[number])
	
	draw_polyline(corners, Color.BLACK, max(scale_factor * 0.1, 3))
	
	if not label:
		label = Label.new()
		
		add_child(label)
		
		label.label_settings = LabelSettings.new()
	
	label.label_settings.font_color = Color.BLACK
	label.label_settings.font_size = floori(scale_factor * 0.7)
	
	label.size.x = scale_factor * 2
	label.size.y = scale_factor * sqrt(3)
	
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	if number != 0:
		label.text = str(number)
	else:
		label.text = ""


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if number < len(COLORS) - 1:
					number += 1
				else:
					number = 0


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


func get_scale_factor() -> float:
	return min(size.x / 2, size.y / sqrt(3))
