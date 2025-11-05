extends Line2D
class_name RithmaticLine

signal dismiss_line(line: RithmaticLine)

var data: RithmaticLineData = RithmaticLineData.new()

var tween: Tween
var debug: bool = false
var timer: Timer = Timer.new()

var start_line_dissolve: float = 0
var end_line_dissolve: float = 0

@onready var static_body: StaticBody2D = $StaticBody2D

func _ready() -> void:
	static_body.connect("hold_start", _on_static_body_hold_start)
	static_body.connect("hold_end", _on_static_body_hold_end)
	timer.connect("timeout", _on_timer_timeout)
	timer.wait_time = data.dismiss_timeout
	add_child(timer)
	start_line_dissolve = material.get("shader_parameter/Dissolve")
	end_line_dissolve = 5.5

func _on_static_body_hold_start() -> void:
	timer.start()	
	tween_dissolve_line(end_line_dissolve, data.dismiss_timeout)

func _on_static_body_hold_end() -> void:
	timer.stop()
	tween_dissolve_line(start_line_dissolve, 0.3)

func tween_dissolve_line(target: float, time: float) -> void:
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "material:shader_parameter/Dissolve", target, time)

func _on_timer_timeout() -> void:
	dismiss_line.emit(self)

func update_line(new_data: RithmaticLineData) -> void:
	data = new_data
	timer.wait_time = data.dismiss_timeout
	default_color = data.color
	_create_colliders()

func _create_colliders() -> void:
	var colliders: Array[CollisionShape2D] = []
	for i in range(0, points.size() - 1):
		var a := points[i]
		var b := points[i + 1]#
		var half_way := (a + b) / 2
		var angle := (b - a).angle() - (PI / 2)
		var capsule := CapsuleShape2D.new()
		capsule.radius = width * 0.3
		capsule.height = (b - a).length() + (capsule.radius * 2)	# adding overlap to ensure coverage
		var collider := CollisionShape2D.new()
		collider.shape = capsule
		collider.rotation = angle
		collider.global_position = half_way
		colliders.append(collider)
		static_body.add_child(collider)
