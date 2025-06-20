extends Node2D
class_name Rithmatics

@onready var drawing: Drawing = %Drawing

@export var max_circle_gap: float = 15
@export var max_circle_deviation: float = 0.3   # radius deviation in percent
@export var max_line_deviation: float = 20     # angle deviation in degrees
@export var debug_draw: bool = true

var debug_line_template: PackedScene = load("res://debug_line.tscn")

var lines: Array[RithmaticLine] = []

func _ready() -> void:
    drawing.connect("line_finished", _on_drawing_line_finished)

func _on_drawing_line_finished(line: RithmaticLine) -> void:
    if check_straight_line(line.points):
        line.line_type = RithmaticLine.Type.FORBIDDENCE
        line.strength = 1
    else:
        var circle_score := check_circle(line.points)
        if circle_score > 0.5:
            line.line_type = RithmaticLine.Type.WARDING
            line.strength = circle_score

    line.debug = debug_draw
    line.update_line()
    lines.append(line)

func check_straight_line(points: Array[Vector2]) -> bool:
    if points.size() < 5:
        # line too short
        return false

    var middle_point: int = round(points.size() / 2.0)
    var start_sample := (points[middle_point] - points[0]).normalized()
    var end_sample := (points[points.size() - 1] - points[middle_point]).normalized()
    var base_dir := (start_sample + end_sample) / 2

    for i in range(1, points.size() - 1):
        var seg_dir := (points[i + 1] - points[i]).normalized()
        var angle := rad_to_deg(base_dir.angle_to(seg_dir))
        if abs(angle) > max_line_deviation:
            return false  # Too much deviation, not straight
    return true

### check if circle is closed enough [br]
## returns array like:
## [codeblock][is_closed, index_without_overshoot][/codeblock]
func check_circle_closed(points: Array[Vector2]) -> Array:
    var gap := points[0].distance_to(points[-1])
    if gap < max_circle_gap:
        return [true, points.size() - 1]

    # test for overshoot when closing circle
    # move back point by point and check if gap to beginning shrinks/widens
    var overshoot_start := points.size() - 1
    for i in range(points.size() - 2, -1, -1):
        var new_gap := points[0].distance_to(points[i])
        if new_gap < gap:
            gap = new_gap
            overshoot_start = i
        else:
            # break means gap widened again, overshoot ended
            break

        if i == 0:
            # if loop runs through without breaking, probably not a circle
            return [false, 0]

    # finally test actual gap without overshoot
    if gap < max_circle_gap:
        return [true, overshoot_start]
    return [false, 0]

func check_circle(points: Array[Vector2]) -> float:
    var result: Array = check_circle_closed(points)
    var is_closed: bool = result[0]
    var overshoot_start: int = result[1]

    if not is_closed:
        return 0

    points = points.slice(0, overshoot_start)

    # circle too small
    if points.size() < 5:
        return 0 
    
    # approximate center of potential circle
    var center := Vector2.ZERO
    for p: Vector2 in points:
        center += p
    center /= points.size()
    if debug_draw:
        draw_debug(center)

    # determine average radius
    var distances: Array[float] = []
    for p: Vector2 in points:
        distances.append(center.distance_to(p))
    var average_radius: float = distances.reduce(func (a: float, b: float) -> float: return a + b) / distances.size()

    # check deviation between radiuses 
    for dist in distances:
        if abs(dist - average_radius) > average_radius * max_circle_deviation:
            return 0

    #TODO: check curvature along the circle

    return 1

func draw_debug(point: Vector2, point_two: Variant = null) -> void:
    var debug_line: Line2D = debug_line_template.instantiate()
    add_child(debug_line)

    debug_line.clear_points()
    debug_line.add_point(point)
    debug_line.add_point(point + Vector2(0.1, 0.1))

    if point_two is Vector2:
        debug_line.add_point(point_two)