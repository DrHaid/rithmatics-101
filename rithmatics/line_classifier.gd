extends RefCounted
class_name LineClassifier

static func classify(points: Array[Vector2], max_line_deviation: float,
					 max_circle_gap: float, max_circle_deviation: float) -> Dictionary:
	if _is_straight_line(points, max_line_deviation):
		return {"type": RithmaticLine.Type.FORBIDDENCE, "strength": 1.0}
	
	var circle_score := _check_circle(points, max_circle_gap, max_circle_deviation)
	if circle_score > 0.5:
		return {"type": RithmaticLine.Type.WARDING, "strength": circle_score}
	
	return {"type": RithmaticLine.Type.NONE, "strength": 0.0}

static func _is_straight_line(points: Array[Vector2], max_deviation: float) -> bool:
	if points.size() < 5:
		return false

	var middle_point: int = round(points.size() / 2.0)
	var start_sample := (points[middle_point] - points[0]).normalized()
	var end_sample := (points[points.size() - 1] - points[middle_point]).normalized()
	var base_dir := (start_sample + end_sample) / 2

	for i in range(1, points.size() - 1):
		var seg_dir := (points[i + 1] - points[i]).normalized()
		var angle := rad_to_deg(base_dir.angle_to(seg_dir))
		if abs(angle) > max_deviation:
			return false
	return true

static func _check_circle(points: Array[Vector2], max_gap: float, max_deviation: float) -> float:
	var result: Array = _check_circle_closed(points, max_gap)
	if not result[0]:
		return 0

	points = points.slice(0, result[1])
	if points.size() < 5:
		return 0 
	
	var center := Vector2.ZERO
	for p: Vector2 in points:
		center += p
	center /= points.size()

	var distances: Array[float] = []
	for p: Vector2 in points:
		distances.append(center.distance_to(p))
	var average_radius: float = distances.reduce(func (a: float, b: float) -> float: return a + b) / distances.size()

	for dist in distances:
		if abs(dist - average_radius) > average_radius * max_deviation:
			return 0

	return 1

static func _check_circle_closed(points: Array[Vector2], max_gap: float) -> Array:
	var gap := points[0].distance_to(points[-1])
	if gap < max_gap:
		return [true, points.size() - 1]

	var overshoot_start := points.size() - 1
	for i in range(points.size() - 2, -1, -1):
		var new_gap := points[0].distance_to(points[i])
		if new_gap < gap:
			gap = new_gap
			overshoot_start = i
		else:
			break
		if i == 0:
			return [false, 0]

	if gap < max_gap:
		return [true, overshoot_start]
	return [false, 0]