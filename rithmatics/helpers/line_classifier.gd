extends RefCounted
class_name LineClassifier

## returns Dictionary:
## [codeblock]
## {
##	"type": RithmaticLineData.LineType
##	"strength": float
##	"angle": float (optional, only for lines of vigor)
##	"clean_line": Array[Vector2] (cleaned up representation of the line for calculations)
## }
## [/codeblock]
static func classify(points: Array[Vector2], max_line_deviation: float,
					 max_circle_gap: float, max_circle_deviation: float,
					 max_sine_deviation: float) -> Dictionary:
	var straight_result := _check_straight_line(points, max_line_deviation)
	if straight_result.score > 0.5:
		return {"type": RithmaticLineData.LineType.FORBIDDENCE, "strength": straight_result.score, "clean_line": points}
	
	var circle_result := _check_circle(points, max_circle_gap, max_circle_deviation)
	if circle_result.score > 0.5:
		return {"type": RithmaticLineData.LineType.WARDING, "strength": circle_result.score, "clean_line": circle_result.clean_line}
	
	var sine_check_result := _check_sine(points, max_sine_deviation)
	if sine_check_result.score > 0.5:
		return {"type": RithmaticLineData.LineType.VIGOR, "strength": sine_check_result.score, "clean_line": points, "angle": sine_check_result.angle}

	return {"type": RithmaticLineData.LineType.NONE, "strength": 0.0, "clean_line": points}

static func _check_straight_line(points: Array[Vector2], max_deviation: float) -> Dictionary:
	if points.size() < 5:
		return {"score": 0.0}

	var start := points[0]
	var end := points[-1]
	var line_dir := (end - start).normalized()

	var max_dist: float = 0.0
	for i in range(1, points.size() - 1):
		var to_point := points[i] - start
		var proj_length := to_point.dot(line_dir)
		var proj_point := start + line_dir * proj_length
		var perp_dist := points[i].distance_to(proj_point)
		max_dist = max(max_dist, perp_dist)

	var score: float = clamp(1.0 - (max_dist / max_deviation), 0.0, 1.0)
	return {"score": score}

## returns Dictionary:
## [codeblock]
## {
##	"score": float (how much circle is the circle)
##	"clean_line": Array[Vector2] (cleaned up representation of the line for calculations)
## }
## [/codeblock]
static func _check_circle(points: Array[Vector2], max_gap: float, max_deviation: float) -> Dictionary:
	var result: Dictionary = _check_circle_closed(points, max_gap)
	if not result.is_loop:
		return {"score": 0, "clean_line": points}

	points = points.slice(0, result.loop_end)
	if points.size() < 5:
		return {"score": 0, "clean_line": points}
	
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
			return {"score": 0, "clean_line": points}

	return {"score": 1, "clean_line": points}

## returns Dictionary:
## [codeblock]
## {
##	"is_loop": bool (is the line actually a closed-ish loop)
##	"loop_end": int (index of segment that closes loop (excludes overshoot))
## }
## [/codeblock]
static func _check_circle_closed(points: Array[Vector2], max_gap: float) -> Dictionary:
	var gap := points[0].distance_to(points[-1])
	if gap < max_gap:
		return {"is_loop": true, "loop_end": points.size() - 1}

	var overshoot_start := points.size() - 1
	for i in range(points.size() - 2, -1, -1):
		var new_gap := points[0].distance_to(points[i])
		if new_gap < gap:
			gap = new_gap
			overshoot_start = i
		else:
			break
		if i == 0:
			return {"is_loop": false, "loop_end": 0}

	if gap < max_gap:
		return {"is_loop": true, "loop_end": overshoot_start}
	return {"is_loop": false, "loop_end": 0}

static func _check_sine(points: Array[Vector2], _max_deviation: float) -> Dictionary:
	var pca_result := principal_axis_angle(points)
	var refined_points := rotate_and_center_points(points, pca_result.centroid, pca_result.angle)

	# separate axes
	var ys: Array[float] = []
	var xs: Array[float] = []
	for p: Vector2 in refined_points:
		xs.append(p.x)
		ys.append(p.y)

	var pt := find_peaks_and_troughs(ys)
	var zero_crossings := count_zero_crossings(ys)

	# TODO: refine this: check amplitude
	var is_sine: bool = pt.peaks.size() >= 2 and pt.troughs.size() >= 2 and zero_crossings >= 6

	return { "angle": pca_result.angle, "score": 1.0 if is_sine else 0.0 }

## determine x-axis of sine wave by doing some matrix shid, Chad Chippity said so
static func principal_axis_angle(points: Array) -> Dictionary:
	var n := points.size()
	var centroid := Vector2.ZERO
	for p: Vector2 in points:
		centroid += p
	centroid /= n
	var sxx: float = 0.0
	var syy: float = 0.0
	var sxy: float = 0.0
	for p: Vector2 in points:
		var dx: float = p.x - centroid.x
		var dy: float = p.y - centroid.y
		sxx += dx * dx
		syy += dy * dy
		sxy += dx * dy
	sxx /= n
	syy /= n
	sxy /= n
	# analytic PCA angle for 2x2 covariance something something big words:
	var angle := 0.5 * atan2(2.0 * sxy, sxx - syy)
	return { "angle": angle, "centroid": centroid }

static func rotate_and_center_points(points: Array[Vector2], pivot: Vector2, angle: float) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p: Vector2 in points:
		out.append((p - pivot).rotated(-angle))
	return out

static func find_peaks_and_troughs(y_vals: Array[float]) -> Dictionary:
	var peaks: Array[float] = []
	var troughs: Array[float] = []
	for i in range(1, y_vals.size() - 1):
		if y_vals[i] > y_vals[i - 1] and y_vals[i] >= y_vals[i + 1]:
			peaks.append(y_vals[i])
		elif y_vals[i] < y_vals[i - 1] and y_vals[i] <= y_vals[i + 1]:
			troughs.append(y_vals[i])
	return { "peaks": peaks, "troughs": troughs }

static func count_zero_crossings(vals: Array[float], min_delta: float = 0.0) -> int:
	var count: int = 0
	for i: int in range(vals.size() - 1):
		var a: float = vals[i]
		var b: float = vals[i + 1]
		if a == 0.0 or b == 0.0:
			continue
		if a * b < 0.0 and abs(b - a) > min_delta:
			count += 1
	return count
