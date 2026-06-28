class_name Player
extends CharacterBody3D

@export var player_index: int = 0
@export var device_id: int = -1
@export var move_speed: float = 4.5
@export var acceleration: float = 14.0
@export var player_color: Color = Color.DODGER_BLUE

const GRAVITY: float = 20.0
const FALL_DEATH_Y: float = -15.0
const RESPAWN_DELAY: float = 1.5
const PLAYER_MASS: float = 80.0
const REACH_DISTANCE: float = 3.0
const SOAP_CAPACITY: float = 1.0
const SOAP_DRAIN_RATE: float = 0.12
const SOAP_REFILL_RATE: float = 0.5

var _state: StringName = &"IDLE"
var _respawn_position: Vector3 = Vector3.ZERO
var _is_respawning: bool = false
var _respawn_timer: float = 0.0
var _soap: float = SOAP_CAPACITY
var _nearest_window: Node = null

@onready var _body_mesh: MeshInstance3D = $Body

func _ready() -> void:
	add_to_group("players")
	add_to_group("weighted")
	_respawn_position = global_position
	if _body_mesh:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = player_color
		_body_mesh.material_override = mat

func _physics_process(delta: float) -> void:
	if _is_respawning:
		_respawn_timer -= delta
		if _respawn_timer <= 0.0:
			_complete_respawn()
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	var input_dir := _get_input_vector()
	if input_dir.length_squared() > 0.01:
		var direction := Vector3(input_dir.x, 0.0, input_dir.y).normalized()
		velocity.x = move_toward(velocity.x, direction.x * move_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
		velocity.z = move_toward(velocity.z, 0.0, acceleration * delta)

	move_and_slide()

	if global_position.y < FALL_DEATH_Y:
		_start_respawn()
		return

	_nearest_window = _find_nearest_cleanable()
	_auto_refill_soap(delta)
	_try_scrub(delta)
	_update_state()

func _get_input_vector() -> Vector2:
	var prefix := "p%d_" % player_index
	var left  := prefix + "left"
	var right := prefix + "right"
	var fwd   := prefix + "forward"
	var back  := prefix + "back"
	if InputMap.has_action(left):
		return Input.get_vector(left, right, fwd, back)
	return Vector2.ZERO

func _auto_refill_soap(delta: float) -> void:
	if _soap >= SOAP_CAPACITY:
		return
	for src in get_tree().get_nodes_in_group("soap_source"):
		if global_position.distance_to(src.global_position) < 1.5:
			_soap = minf(_soap + SOAP_REFILL_RATE * delta, SOAP_CAPACITY)
			break

func _try_scrub(delta: float) -> void:
	var interact := "p%d_interact" % player_index
	if not (InputMap.has_action(interact) and Input.is_action_pressed(interact)):
		return
	if _nearest_window != null and _soap > 0.0:
		_nearest_window.call("scrub_frame", delta)
		_soap = maxf(_soap - SOAP_DRAIN_RATE * delta, 0.0)

func _find_nearest_cleanable() -> Node:
	var best: Node = null
	var best_dist := REACH_DISTANCE
	for w in get_tree().get_nodes_in_group("cleanable"):
		if not w.has_method("scrub_frame"):
			continue
		if w.has_method("is_clean") and w.call("is_clean"):
			continue
		var d := global_position.distance_to(w.global_position)
		if d < best_dist:
			best_dist = d
			best = w
	return best

func _update_state() -> void:
	if _is_respawning:
		_state = &"RESPAWNING"
		return
	if not is_on_floor():
		_state = &"FALLING"
		return
	var interact := "p%d_interact" % player_index
	if InputMap.has_action(interact) and Input.is_action_pressed(interact):
		_state = &"SCRUBBING" if (_nearest_window != null and _soap > 0.0) else &"REACHING"
		return
	if Vector2(velocity.x, velocity.z).length() > 0.2:
		_state = &"WALKING"
	else:
		_state = &"IDLE"

func _start_respawn() -> void:
	_is_respawning = true
	_respawn_timer = RESPAWN_DELAY
	_state = &"RESPAWNING"
	velocity = Vector3.ZERO
	var pos := global_position
	pos.y = -200.0
	global_position = pos

func _complete_respawn() -> void:
	_is_respawning = false
	global_position = _respawn_position
	velocity = Vector3.ZERO
	_state = &"IDLE"

func set_respawn_position(pos: Vector3) -> void:
	_respawn_position = pos

func get_state() -> StringName:
	return _state

func get_soap() -> float:
	return _soap

func get_weight_data() -> Dictionary:
	if _is_respawning or not is_on_floor():
		return {}
	return {
		"position": global_position,
		"mass": PLAYER_MASS,
	}
