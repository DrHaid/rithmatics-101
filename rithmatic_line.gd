extends Line2D
class_name RithmaticLine

enum Type { NONE, WARDING, FORBIDDENCE, VIGOR, MAKING }

var line_type: Type = Type.NONE
var strength: float = 0
var debug_color: Color = Color.WHITE

var debug: bool = false

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