extends Node2D
class_name Rithmatics

@onready var drawing: Drawing = %Drawing

@export var max_circle_gap: float = 15
@export var max_circle_deviation: float = 0.3   # radius deviation in percent
@export var max_line_deviation: float = 20     # angle deviation in degrees
@export var max_sine_deviation: float = 0     # angle deviation in degrees
@export var dismiss_time: float = 4
@export var debug_draw: bool = true

var debug_line_template: PackedScene = load("res://debug_line.tscn")
var line_dismiss_particles: PackedScene = load("res://rithmatics/vfx/line_dismiss_particles.tscn")

var lines: Array[RithmaticLine] = []
var junction_manager := JunctionManager.new()
var debug_junctions: Array[Line2D] = []

func _ready() -> void:
	drawing.connect("line_finished", _on_drawing_line_finished)

func _on_drawing_line_finished(line: RithmaticLine) -> void:
	var classification := LineClassifier.classify(line.points, max_line_deviation, max_circle_gap, max_circle_deviation, max_sine_deviation)
	var data := RithmaticLineData.new(
		classification.type,
		classification.clean_line,
		classification.score,
		dismiss_time,
		debug_draw
	)
	line.update_line(data)

	if line.data.line_type == RithmaticLineData.LineType.VIGOR:
		# TODO: handle lines of vigor behavior
		_on_dismiss_line(line)
		return

	line.connect("dismiss_line", _on_dismiss_line)
	junction_manager.add_junctions(line, lines)
	if debug_draw:
		junction_manager.debug_draw_junctions(self, Color.BLUE)
	lines.append(line)

func _on_dismiss_line(line: RithmaticLine) -> void:
	var particles: CPUParticles2D = line_dismiss_particles.instantiate()
	particles.emission_points = line.points
	particles.amount = line.points.size() * 25
	particles.emitting = true
	particles.connect("finished", particles.queue_free)
	add_child(particles)

	junction_manager.remove_junctions(line)
	if debug_draw:
		junction_manager.debug_draw_junctions(self, Color.BLUE)
	
	var index := lines.find(line)
	if index >= 0:
		lines.remove_at(index)
	line.queue_free()

func draw_debug(point: Vector2, color: Color = Color.RED, point_two: Variant = null) -> void:
	var debug_line: Line2D = debug_line_template.instantiate()
	add_child(debug_line)
	debug_junctions.append(debug_line)

	debug_line.default_color = color
	debug_line.clear_points()
	debug_line.add_point(point)
	debug_line.add_point(point + Vector2(0.1, 0.1))
	
	if point_two is Vector2:
		debug_line.add_point(point_two)
