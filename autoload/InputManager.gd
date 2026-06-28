extends Node

signal player_joined(player_index: int, device_id: int)
signal player_left(player_index: int)

var player_devices: Dictionary = {}
var max_players: int = 4

func _ready() -> void:
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func register_device(device_id: int) -> int:
	for idx: int in player_devices:
		if player_devices[idx] == device_id:
			return idx
	var index := player_devices.size()
	if index >= max_players:
		return -1
	player_devices[index] = device_id
	player_joined.emit(index, device_id)
	return index

func unregister_player(player_index: int) -> void:
	if player_index in player_devices:
		player_devices.erase(player_index)
		player_left.emit(player_index)

func get_device_for_player(player_index: int) -> int:
	return player_devices.get(player_index, -1)

func get_player_count() -> int:
	return player_devices.size()

func _on_joy_connection_changed(device: int, connected: bool) -> void:
	if not connected:
		for idx: int in player_devices:
			if player_devices[idx] == device:
				unregister_player(idx)
				return
