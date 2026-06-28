class_name Scaffold
extends RigidBody3D

signal tilt_changed(angle: float)
signal tilt_warning(angle: float)
signal tilt_danger(angle: float)
signal tilt_catastrophe(angle: float)
signal tilt_safe()

@export_group("Dimensions")
@export var half_width: float = 4.0
@export var half_depth: float = 1.0

@export_group("Cable Physics")
@export var cable_length: float = 8.0
@export var cable_stiffness: float = 200.0
@export var cable_damping: float = 15.0
@export var angular_damping: float = 2.0

@export_group("Weight and Tilt")
@export var scaffold_mass: float = 100.0
@export var tilt_sensitivity: float = 0.3
@export var slide_friction_threshold: float = 25.0

@export_group("Tilt Thresholds (degrees)")
@export var warning_angle: float = 10.0
@export var danger_angle: float = 25.0
@export var catastrophe_angle: float = 40.0

var _tilt_angle: float = 0.0
var _tilt_state: StringName = &"SAFE"
var _anchor_positions: Array[Vector3] = []
var _corner_offsets: Array[Vector3] = []

func _ready() -> void:
	add_to_group("scaffold")
	add_to_group("wind_affected")
	mass = scaffold_mass
	angular_damp = angular_damping
	_corner_offsets = [
		Vector3(-half_width, 0.0, -half_depth),
		Vector3( half_width, 0.0, -half_depth),
		Vector3(-half_width, 0.0,  half_depth),
		Vector3( half_width, 0.0,  half_depth),
	]
	_setup_anchors()

func _setup_anchors() -> void:
	_anchor_positions.clear()
	for offset in _corner_offsets:
		var world_corner := global_position + offset
		_anchor_positions.append(world_corner + Vector3(0.0, cable_length, 0.0))

func apply_wind(force: Vector3) -> void:
	apply_central_force(force)

func _physics_process(_delta: float) -> void:
	_apply_cable_forces()
	_apply_weight_torque()
	_update_tilt()

func _apply_cable_forces() -> void:
	for i in _corner_offsets.size():
		var corner_local := _corner_offsets[i]
		var corner_world := global_position + global_basis * corner_local
		var to_anchor := _anchor_positions[i] - corner_world
		var distance := to_anchor.length()
		if distance < 0.001:
			continue
		var direction := to_anchor / distance
		var excess := distance - cable_length
		var spring_f := direction * excess * cable_stiffness
		var vel_along := linear_velocity.dot(direction)
		spring_f -= direction * vel_along * cable_damping
		apply_force(spring_f, corner_local)

func _apply_weight_torque() -> void:
	var net_torque := Vector3.ZERO
	for node in get_tree().get_nodes_in_group("weighted"):
		if not node.has_method("get_weight_data"):
			continue
		var data: Dictionary = node.get_weight_data()
		if data.is_empty():
			continue
		var world_pos: Vector3 = data.get("position", Vector3.ZERO)
		var node_mass: float = data.get("mass", 0.0)
		var dx := world_pos.x - global_position.x
		var dz := world_pos.z - global_position.z
		net_torque += Vector3(dz * node_mass * 9.8, 0.0, -dx * node_mass * 9.8)
	apply_torque(net_torque * tilt_sensitivity)

func _update_tilt() -> void:
	var up := global_basis.y
	_tilt_angle = rad_to_deg(acos(clampf(up.dot(Vector3.UP), -1.0, 1.0)))
	var prev_state := _tilt_state
	if _tilt_angle >= catastrophe_angle:
		_tilt_state = &"CATASTROPHE"
		if prev_state != _tilt_state:
			tilt_catastrophe.emit(_tilt_angle)
	elif _tilt_angle >= danger_angle:
		_tilt_state = &"DANGER"
		if prev_state != _tilt_state:
			tilt_danger.emit(_tilt_angle)
	elif _tilt_angle >= warning_angle:
		_tilt_state = &"WARNING"
		if prev_state != _tilt_state:
			tilt_warning.emit(_tilt_angle)
	else:
		_tilt_state = &"SAFE"
		if prev_state != &"SAFE":
			tilt_safe.emit()
	tilt_changed.emit(_tilt_angle)

func get_tilt_angle() -> float:
	return _tilt_angle

func get_tilt_state() -> StringName:
	return _tilt_state

func get_state() -> Dictionary:
	return {
		"position": global_position,
		"rotation": global_rotation,
		"linear_velocity": linear_velocity,
		"angular_velocity": angular_velocity,
		"tilt_angle": _tilt_angle,
		"tilt_state": str(_tilt_state),
	}
