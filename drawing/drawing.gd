extends Node2D
class_name Drawing

signal line_finished(line: RithmaticLine)

var line_point_distance_threshold: float = 5

var is_clicked: bool = false
var current_mouse_pos: Vector2 = Vector2.ZERO

var line_template: PackedScene = load("res://rithmatic_line.tscn")
var current_line: RithmaticLine

func _ready() -> void:
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		is_clicked = event.is_pressed() and event.button_index == MOUSE_BUTTON_LEFT
	if event is InputEventMouseMotion:
		current_mouse_pos = get_global_mouse_position()
	
func _process(_delta: float) -> void:
	if not is_clicked and current_line:
		# finish current line
		line_finished.emit(current_line)
		current_line = null
	
	if is_clicked and not current_line:
		# start new line
		current_line = line_template.instantiate()
		current_line.clear_points()
		current_line.add_point(current_mouse_pos)
		add_child(current_line)
	
	if is_clicked and current_line:
		var distance := current_line.points[-1].distance_to(current_mouse_pos)
		if distance > line_point_distance_threshold:
			current_line.add_point(current_mouse_pos)
