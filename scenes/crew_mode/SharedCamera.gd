extends Camera3D

@export var base_height: float = 4.0
@export var base_distance: float = 5.5
@export var min_zoom: float = 1.0
@export var max_zoom: float = 2.0
@export var zoom_padding: float = 2.0
@export var lerp_speed: float = 3.5

func _process(delta: float) -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return

	# Centroid of players who aren't respawning
	var centroid := Vector3.ZERO
	var count := 0
	for p in players:
		if p.has_method("get_state") and p.get_state() == &"RESPAWNING":
			continue
		centroid += p.global_position
		count += 1
	if count == 0:
		return
	centroid /= float(count)

	# Spread-based zoom
	var max_spread := 0.0
	for p in players:
		max_spread = maxf(max_spread, centroid.distance_to(p.global_position))
	var zoom := clampf(1.0 + (max_spread + zoom_padding) / 7.0, min_zoom, max_zoom)

	var target_pos := centroid + Vector3(0.0, base_height * zoom, base_distance * zoom)
	global_position = global_position.lerp(target_pos, lerp_speed * delta)
	look_at(centroid + Vector3(0.0, 0.5, -1.2), Vector3.UP)
