class_name WindSystem
extends Node

signal gust_started(direction: Vector3, force_magnitude: float)
signal gust_ended()

@export var wind_force_range: Vector2 = Vector2(30.0, 150.0)
@export var gust_interval_range: Vector2 = Vector2(8.0, 20.0)
@export var gust_duration_range: Vector2 = Vector2(1.0, 3.0)
@export var total_floors: int = 10

var current_floor: int = 0

var _gust_active: bool = false
var _gust_timer: float = 0.0
var _gust_duration: float = 0.0
var _current_force: Vector3 = Vector3.ZERO
var _next_interval: float = 0.0

func _ready() -> void:
	_next_interval = randf_range(gust_interval_range.x, gust_interval_range.y)

func _physics_process(delta: float) -> void:
	_gust_timer += delta
	if _gust_active:
		if _gust_timer >= _gust_duration:
			_end_gust()
		else:
			_push_wind_targets()
	elif _gust_timer >= _next_interval:
		_start_gust()

func _start_gust() -> void:
	_gust_active = true
	_gust_timer = 0.0
	_gust_duration = randf_range(gust_duration_range.x, gust_duration_range.y)
	var height_factor := float(current_floor) / float(max(total_floors, 1))
	var force_mag := randf_range(wind_force_range.x, wind_force_range.y) * (0.3 + height_factor * 0.7)
	var angle := randf_range(0.0, TAU)
	_current_force = Vector3(cos(angle), 0.0, sin(angle)) * force_mag
	gust_started.emit(_current_force.normalized(), force_mag)

func _end_gust() -> void:
	_gust_active = false
	_gust_timer = 0.0
	_next_interval = randf_range(gust_interval_range.x, gust_interval_range.y)
	_current_force = Vector3.ZERO
	gust_ended.emit()

func _push_wind_targets() -> void:
	for target in get_tree().get_nodes_in_group("wind_affected"):
		if target.has_method("apply_wind"):
			target.apply_wind(_current_force)

func set_floor(floor_num: int) -> void:
	current_floor = floor_num
