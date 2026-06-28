class_name WindowPane
extends Area3D

signal window_cleaned()
signal cleanliness_changed(value: float)

@export var cleanliness: float = 0.0
@export var clean_rate: float = 0.3
@export var clean_threshold: float = 0.9
@export var window_size: Vector2 = Vector2(1.0, 0.8)

var _material: StandardMaterial3D = null

const DIRTY_COLOR := Color(0.25, 0.22, 0.18)
const CLEAN_COLOR := Color(0.50, 0.70, 0.90)

func _ready() -> void:
	add_to_group("cleanable")
	_create_mesh()
	_create_collision()

func _create_mesh() -> void:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(window_size.x, window_size.y, 0.04)
	mesh_inst.mesh = box
	_material = StandardMaterial3D.new()
	_material.albedo_color = DIRTY_COLOR
	mesh_inst.material_override = _material
	add_child(mesh_inst)

func _create_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(window_size.x, window_size.y, 0.25)
	col.shape = shape
	add_child(col)

func scrub_frame(delta: float) -> void:
	if cleanliness >= clean_threshold:
		return
	cleanliness = minf(cleanliness + clean_rate * delta, 1.0)
	if _material:
		_material.albedo_color = DIRTY_COLOR.lerp(CLEAN_COLOR, cleanliness)
	cleanliness_changed.emit(cleanliness)
	if cleanliness >= clean_threshold:
		window_cleaned.emit()

func is_clean() -> bool:
	return cleanliness >= clean_threshold

func get_cleanliness() -> float:
	return cleanliness
