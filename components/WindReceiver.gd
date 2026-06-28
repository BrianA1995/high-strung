class_name WindReceiver
extends Node

@export var wind_multiplier: float = 1.0

func _ready() -> void:
	add_to_group("wind_affected")

func apply_wind(force: Vector3) -> void:
	var parent := get_parent()
	if parent is RigidBody3D:
		(parent as RigidBody3D).apply_central_force(force * wind_multiplier)
