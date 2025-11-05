extends RefCounted
class_name Junction

var position: Vector2
var lines: Array[RithmaticLine]

func _init(pos: Vector2, line: RithmaticLine) -> void:
    position = pos
    lines.append(line)

func add_line(line: RithmaticLine) -> void:
    var index := lines.find(line)
    if index < 0:
        lines.append(line)

func remove_line(line: RithmaticLine) -> void:
    var index := lines.find(line)
    if index >= 0:
        lines.erase(line)

func has_line(line: RithmaticLine) -> bool:
    return lines.has(line)

func is_valid() -> bool:
    return lines.size() >= 2