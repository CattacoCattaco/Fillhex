class_name Star
extends Polygon2D

var background: Background
var min_scale: float
var max_scale: float
var transition_time: float

var scale_tween: Tween = create_tween()


func _ready() -> void:
	# Circumradius of the internal pentagon
	var pent_radius: float = 4 / ((1 + sqrt(5)) ** 2)
	
	# Internal and external vertices
	polygon = PackedVector2Array([
		Vector2(0, 1),
		pent_radius * Vector2(sin(4 * PI / 5), -cos(4 * PI / 5)),
		Vector2(sin(2 * PI / 5), cos(2 * PI / 5)),
		pent_radius * Vector2(sin(2 * PI / 5), -cos(2 * PI / 5)),
		Vector2(sin(4 * PI / 5), cos(4 * PI / 5)),
		pent_radius * Vector2(0, -1),
		Vector2(sin(-4 * PI / 5), cos(-4 * PI / 5)),
		pent_radius * Vector2(sin(-2 * PI / 5), -cos(-2 * PI / 5)),
		Vector2(sin(-2 * PI / 5), cos(-2 * PI / 5)),
		pent_radius * Vector2(sin(-4 * PI / 5), -cos(-4 * PI / 5)),
	])
	
	scale.x = randf_range(min_scale, max_scale)
	scale.y = scale.x
	
	tween_to_max_scale()


func tween_to_max_scale() -> void:
	if scale_tween.is_valid():
		scale_tween.stop()
	
	var buffer_percent: float = Background.BUFFER_PERCENT
	var short_dimension: float = min(background.size.x, background.size.y)
	var max_scale_vec := Vector2(max_scale, max_scale)
	var end_scale: Vector2 = buffer_percent * short_dimension * max_scale_vec
	
	scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", end_scale, transition_time)
	
	scale_tween.finished.connect(tween_to_min_scale)


func tween_to_min_scale() -> void:
	if scale_tween.is_valid():
		scale_tween.stop()
	
	var buffer_percent: float = Background.BUFFER_PERCENT
	var short_dimension: float = min(background.size.x, background.size.y)
	var min_scale_vec := Vector2(min_scale, min_scale)
	var end_scale: Vector2 = buffer_percent * short_dimension * min_scale_vec
	
	scale_tween = create_tween()
	scale_tween.tween_property(self, "scale", end_scale, transition_time)
	
	scale_tween.finished.connect(tween_to_max_scale)
