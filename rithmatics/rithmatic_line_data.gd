extends Resource
class_name RithmaticLineData

enum LineType { NONE, WARDING, FORBIDDENCE, VIGOR, MAKING }

var line_type: LineType
var strength: float
var color: Color
var dismiss_timeout: float
var clean_line: Array[Vector2]

func _init(_line_type: LineType = LineType.NONE, _strength: float = 0, _dismiss_timeout: float = 4, debug: bool = false) -> void:
	line_type = _line_type
	strength = _strength
	dismiss_timeout = _dismiss_timeout

	if not debug:
		color = Color.WHITE
	else:
		match line_type:
			LineType.WARDING:
				color = Color.YELLOW
			LineType.FORBIDDENCE:
				color = Color.RED
			LineType.VIGOR:
				color = Color.GREEN
			LineType.MAKING:
				color = Color.BLUE
			LineType.NONE:
				color = Color.WHITE