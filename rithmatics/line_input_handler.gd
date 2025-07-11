extends StaticBody2D

signal hold_start()
signal hold_end()

@export var mouse_motion_buffer: int = 5	# buffer before mouse hold is cancelled

var mouse_down: bool = false
var mouse_start_position: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if not mouse_down:
			return
		
		if mouse_motion_buffer < get_global_mouse_position().distance_to(mouse_start_position):
			cancel_mouse_hold()

func _mouse_exit() -> void:
	cancel_mouse_hold()

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton && event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			mouse_down = event.is_pressed()
			mouse_start_position = get_global_mouse_position()
			hold_start.emit()
		if event.is_released():
			cancel_mouse_hold()

func cancel_mouse_hold() -> void:
	if mouse_down:
		mouse_down = false
		hold_end.emit()