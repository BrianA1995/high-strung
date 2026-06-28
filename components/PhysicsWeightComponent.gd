class_name PhysicsWeightComponent
extends Node

@export var mass: float = 80.0
@export var only_when_grounded: bool = true

func _ready() -> void:
	add_to_group("weighted")

func get_weight_data() -> Dictionary:
	var parent := get_parent()
	if only_when_grounded:
		if parent.has_method("is_on_floor") and not parent.is_on_floor():
			return {}
	return {
		"position": parent.global_position,
		"mass": mass,
	}
