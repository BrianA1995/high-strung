class_name FloorProgressSystem
extends Node

signal floor_completed(clean_percent: float)

@export var completion_threshold: float = 0.8

var _completed: bool = false

func get_clean_percent() -> float:
	var windows := get_tree().get_nodes_in_group("cleanable")
	if windows.is_empty():
		return 0.0
	var total := 0.0
	for w in windows:
		if w.has_method("get_cleanliness"):
			total += w.get_cleanliness()
	return total / float(windows.size())

func check_completion() -> void:
	if _completed:
		return
	if get_clean_percent() >= completion_threshold:
		_completed = true
		floor_completed.emit(get_clean_percent())

func reset() -> void:
	_completed = false
