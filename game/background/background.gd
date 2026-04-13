@tool
class_name Background
extends Control

const BACKGROUND_COLOR := Color(0.17, 0.11, 0.36)
const STAR_COLOR := Color(0.75, 0.70, 0.39)
const BUFFER_PERCENT: float = 0.05

@export_tool_button("Redraw") var redraw: Callable = queue_redraw
@export_tool_button("Regenerate") var regenerate_button: Callable = regenerate

var star_parents: Array[Node2D] = []

var old_size: Vector2


func regenerate() -> void:
	for star_parent in star_parents:
		star_parent.queue_free()
	
	star_parents = []
	
	queue_redraw()


func _draw() -> void:
	draw_rect(get_rect(), BACKGROUND_COLOR)
	
	if star_parents:
		return
	
	old_size = size
	
	var star_positions: Array[Vector2] = []
	
	for i in range(randi_range(20, 35)):
		var star_parent := Node2D.new()
		add_child(star_parent)
		
		var top_left_margin := size * BUFFER_PERCENT
		var bottom_right_margin := size - top_left_margin
		star_parent.position = rand_vec2_range(top_left_margin, bottom_right_margin)
		
		var min_distance: float = (size * BUFFER_PERCENT).length()
		while too_close(star_parent.position, star_positions, min_distance):
			star_parent.position = rand_vec2_range(top_left_margin, bottom_right_margin)
		
		star_positions.append(star_parent.position)
		
		var star := Star.new()
		star.background = self
		star.max_scale = randf_range(0.6, 0.9)
		star.min_scale = star.max_scale * 0.5
		star.transition_time = randf_range(1.1, 3.3)
		
		star_parent.add_child(star)
		
		star.color = STAR_COLOR
		star.position = Vector2(0, 0)
		star.rotation = randf_range(0, 2 * PI)
		
		star_parents.append(star_parent)


func _notification(what):
	match what:
		NOTIFICATION_RESIZED:
			for star_parent: Node2D in star_parents:
				star_parent.position = star_parent.position * size / old_size
			old_size = size


func too_close(check: Vector2, others: Array[Vector2], min_distance: float) -> bool:
	for other in others:
		if (other - check).length() <= min_distance:
			return true
	
	return false


func rand_vec2_range(_min: Vector2, _max: Vector2) -> Vector2:
	return Vector2(randf_range(_min.x, _max.x), randf_range(_min.y, _max.y))
