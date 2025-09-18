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
var line_dismiss_particles: PackedScene = load("res://rithmatics/line_dismiss_particles.tscn")

var lines: Array[RithmaticLine] = []
var junctions: Dictionary = {}
var debug_junctions: Array[Line2D] = []

func _ready() -> void:
	drawing.connect("line_finished", _on_drawing_line_finished)

func _on_drawing_line_finished(line: RithmaticLine) -> void:
	var classification := LineClassifier.classify(line.points, max_line_deviation, max_circle_gap, max_circle_deviation, max_sine_deviation)
	line.update_line_props({
		"line_type": classification.type,
		"strength": classification.strength,
		"debug": debug_draw,
		"dismiss_timeout": dismiss_time
	})
	line.connect("dismiss_line", _on_dismiss_line)
	find_junctions(line)
	lines.append(line)

func _on_dismiss_line(line: RithmaticLine) -> void:
	var particles: CPUParticles2D = line_dismiss_particles.instantiate()
	particles.emission_points = line.points
	particles.amount = line.points.size() * 25
	particles.emitting = true
	particles.connect("finished", particles.queue_free)
	add_child(particles)

	remove_junctions(line)
	var index := lines.find(line)
	lines.remove_at(index)
	line.queue_free()

func find_junctions(new_line: RithmaticLine) -> void:
	for line: RithmaticLine in lines:
		var intersections := JunctionManager.find_intersections(new_line.points, line.points, 8)
		for intersection: Vector2 in intersections:
			junctions[intersection] = [new_line, line]

	if debug_draw:
		debug_draw_junctions()

func remove_junctions(removed_line: RithmaticLine) -> void:
	var to_remove: Array[Vector2] = []
	for i: Vector2 in junctions:
		if junctions[i].has(removed_line):
			to_remove.append(i)
	for i in to_remove:
		junctions.erase(i)

	if debug_draw:
		debug_draw_junctions()

func debug_draw_junctions() -> void:
	for junc in debug_junctions:
		junc.queue_free()
	debug_junctions.clear()
	
	for junc: Vector2 in junctions:
		draw_debug(junc, Color.BLUE)

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
