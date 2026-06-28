class_name PlayerModel
extends Node3D

# Swap target — replace the mesh/skeleton inside this scene while
# keeping this interface. Any replacement must implement these methods.

func play_animation(_anim_name: String) -> void:
	pass

func set_tool_visible(_tool_name: String, _visible: bool) -> void:
	pass

func get_hand_marker() -> Marker3D:
	return null

func get_head_marker() -> Marker3D:
	return null
