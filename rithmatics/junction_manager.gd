extends RefCounted
class_name JunctionManager

var junctions: Array[Junction] = []
var debug_junctions: Array[Line2D] = []

var debug_line_template: PackedScene = load("res://debug_line.tscn")

func _init() -> void:
	junctions = []

func add_junctions(new_line: RithmaticLine, lines: Array[RithmaticLine]) -> void:
	for line: RithmaticLine in lines:
		var intersections := JunctionManager.find_intersections(new_line.points, line.points, 8)
		for intersection: Vector2 in intersections:
			var junction := Junction.new(intersection, new_line)
			junction.add_line(line)
			junctions.append(junction)

func remove_junctions(removed_line: RithmaticLine) -> void:
	var to_remove: Array[Junction] = []
	for j: Junction in junctions:
		j.remove_line(removed_line)
		if not j.is_valid():
			to_remove.append(j)
	for r in to_remove:
		junctions.erase(r)

func debug_draw_junctions(parent: Node, color: Color) -> void:
	for junc in debug_junctions:
		junc.queue_free()
	debug_junctions.clear()
	
	for junc: Junction in junctions:
		var debug_line: Line2D = debug_line_template.instantiate()
		parent.add_child(debug_line)
		debug_junctions.append(debug_line)

		debug_line.default_color = color
		debug_line.clear_points()
		debug_line.add_point(junc.position)
		debug_line.add_point(junc.position + Vector2(0.1, 0.1))

static func find_intersections(line_a: Array[Vector2], line_b: Array[Vector2], buffer: float) -> Array[Vector2]:
	var intersections: Array[Vector2] = []
	var close_segments: Array[Vector2] = []
	
	for i in range(line_a.size() - 1):
		var a1 := line_a[i]
		var a2 := line_a[i + 1]
		
		for j in range(line_b.size() - 1):
			var b1 := line_b[j]
			var b2 := line_b[j + 1]
			
			var intersection: Variant = Geometry2D.segment_intersects_segment(a1, a2, b1, b2)
			if intersection != null:
				intersections.append(intersection)

			if (a1.distance_to(b1) < buffer or
				a1.distance_to(b2) < buffer or
				a2.distance_to(b1) < buffer or
				a2.distance_to(b2) < buffer):
				close_segments.append((a1 + a2 + b1 + b2) / 4)

	var close_points := _cluster_consecutive_points(close_segments, 10)
	return _cluster_close_points(intersections + close_points, 30)

static func _cluster_consecutive_points(points: Array[Vector2], buffer: float) -> Array[Vector2]:
	if points.is_empty():
		return []
	
	var average_points: Array[Vector2] = []
	var current_cluster: Array[Vector2] = [points[0]]
	
	var sum := Vector2.ZERO
	for i in range(1, points.size()):
		if points[i].distance_to(points[i-1]) <= buffer:
			current_cluster.append(points[i])
		else:
			sum = Vector2.ZERO
			for point in current_cluster:
				sum += point
			average_points.append(sum / current_cluster.size())
			current_cluster = [points[i]]
	
	sum = Vector2.ZERO
	for point in current_cluster:
		sum += point
	average_points.append(sum / current_cluster.size())
	return average_points

static func _cluster_close_points(points: Array[Vector2], buffer: float) -> Array[Vector2]:
	if points.is_empty():
		return []
	
	var clusters: Array[Array] = []
	var used: Array[bool] = []
	used.resize(points.size())
	
	for i in range(points.size()):
		if used[i]:
			continue
		
		var cluster: Array[Vector2] = [points[i]]
		used[i] = true
		
		var j := i + 1
		while j < points.size():
			if used[j]:
				j += 1
				continue
			
			var found_close := false
			for point in cluster:
				if points[j].distance_to(point) <= buffer:
					cluster.append(points[j])
					used[j] = true
					found_close = true
					break
			
			if found_close:
				j = i + 1
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
