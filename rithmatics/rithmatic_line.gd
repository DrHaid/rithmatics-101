extends Line2D
class_name RithmaticLine

enum Type { NONE, WARDING, FORBIDDENCE, VIGOR, MAKING }

var line_type: Type = Type.NONE
var strength: float = 0
var debug_color: Color = Color.WHITE

var debug: bool = false

@onready var collision_polygon: CollisionPolygon2D = $StaticBody2D/CollisionShape2D

func update_line() -> void:
	match line_type:
		Type.WARDING:
			debug_color = Color.YELLOW
		Type.FORBIDDENCE:
			debug_color = Color.RED
		Type.VIGOR:
			debug_color = Color.GREEN
		Type.MAKING:
			debug_color = Color.BLUE
		Type.NONE:
			debug_color = Color.WHITE

	if debug:
		default_color = debug_color
	else:
		default_color = Color.WHITE

	_build_collider()

func _build_collider() -> void:
	var line_width := width * 0.3     # use halfed width because shader fades edges
	var polygon_side_a: Array[Vector2] = []
	var polygon_side_b: Array[Vector2] = []
	var dir := Vector2.ZERO
	for i in range(0, points.size()):
		var point := points[i]
		if i < points.size() - 1:   # if last point use previous direction
			dir = (points[i + 1] - point).normalized()

		if i == 0:
			point = point - dir * 7    # move first point back to cover beninging
		elif i == points.size() - 1:
			point = point + dir * 7    # move last point forward to cover end

		var a:= point + (dir.rotated(PI / 2) * line_width)
		var b:= point - (dir.rotated(PI / 2) * line_width)
		polygon_side_a.append(a)
		polygon_side_b.append(b)
	polygon_side_b.reverse()
	collision_polygon.polygon = polygon_side_a + polygon_side_b

func check_intersection(other_points: Array[Vector2], buffer: float) -> Array[Vector2]:
	var intersections: Array[Vector2] = []
	var close_segments: Array[Vector2] = []
	for i in range(points.size() - 1):
		var a1 := points[i]
		var a2 := points[i + 1]
		
		for j in range(other_points.size() - 1):
			var b1 := other_points[j]
			var b2 := other_points[j + 1]
			
			var intersection: Variant = Geometry2D.segment_intersects_segment(a1, a2, b1, b2)
			if intersection != null:
				intersections.append(intersection)

			if (a1.distance_to(b1) < buffer or
				a1.distance_to(b2) < buffer or
				a2.distance_to(b1) < buffer or
				a2.distance_to(b2) < buffer):
				close_segments.append((a1 + a2 + b1 + b2) / 4)

	var close_points := cluster_consecutive_points(close_segments, 10)
	return cluster_close_points(intersections + close_points, 30)

### check array of points for clusters of consecutive points separated by <= buffer and averages them
## returning an array of points each representing one cluster.
func cluster_consecutive_points(other_points: Array[Vector2], buffer: float) -> Array[Vector2]:
	if other_points.is_empty():
		return []
	
	var average_points: Array[Vector2] = []
	var current_cluster: Array[Vector2] = [other_points[0]]
	
	for i in range(1, other_points.size()):
		if other_points[i].distance_to(other_points[i-1]) <= buffer:
			current_cluster.append(other_points[i])
		else:
			@warning_ignore("CONFUSABLE_LOCAL_DECLARATION")
			var sum := Vector2.ZERO
			for point in current_cluster:
				sum += point
			average_points.append(sum / current_cluster.size())
			current_cluster = [other_points[i]]
	
	var sum := Vector2.ZERO
	for point in current_cluster:
		sum += point
	average_points.append(sum / current_cluster.size())
	return average_points

### check array of points for clusters of any close points separated by <= buffer and averages them
## returning an array of points each representing one cluster.
## idk man ai wrote ts
func cluster_close_points(other_points: Array[Vector2], buffer: float) -> Array[Vector2]:
	if other_points.is_empty():
		return []
	
	var clusters: Array[Array] = []
	var used: Array[bool] = []
	used.resize(other_points.size())
	
	for i in range(other_points.size()):
		if used[i]:
			continue
		
		var cluster: Array[Vector2] = [other_points[i]]
		used[i] = true
		
		var j := i + 1
		while j < other_points.size():
			if used[j]:
				j += 1
				continue
			
			var found_close := false
			for point in cluster:
				if other_points[j].distance_to(point) <= buffer:
					cluster.append(other_points[j])
					used[j] = true
					found_close = true
					break
			
			if found_close:
				j = i + 1  # Restart to check all unused points against expanded cluster
			else:
				j += 1
		
		clusters.append(cluster)
	
	var average_points: Array[Vector2] = []
	for cluster: Array[Vector2] in clusters:
		var sum := Vector2.ZERO
		for point in cluster:
			sum += point
		average_points.append(sum / cluster.size())
	
	return average_points
