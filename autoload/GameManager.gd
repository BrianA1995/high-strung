extends Node

signal player_spawned(player: Node, index: int)
signal game_mode_changed(mode: StringName)

enum GameMode { NONE, CREW, SOLO }

var current_mode: GameMode = GameMode.NONE
var active_players: Dictionary = {}
var score: int = 0
var current_floor: int = 0
var player_count: int = 2

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func spawn_player(player_index: int, device_or_peer_id: int) -> Node:
	var player_scene := load("res://entities/player/Player.tscn") as PackedScene
	var player := player_scene.instantiate()
	player.player_index = player_index
	player.device_id = device_or_peer_id
	active_players[player_index] = player
	player_spawned.emit(player, player_index)
	return player

func get_player(index: int) -> Node:
	return active_players.get(index, null)

func clear_players() -> void:
	active_players.clear()
