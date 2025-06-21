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
        #TODO: extend first and last points outwards to cover caps
        polygon_side_a.append(a)
        polygon_side_b.append(b)
    polygon_side_b.reverse()
    collision_polygon.polygon = polygon_side_a + polygon_side_b