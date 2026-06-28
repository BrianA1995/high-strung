extends Node3D

@onready var _scaffold: RigidBody3D = $Scaffold
@onready var _hud: CanvasLayer = $HUD
@onready var _spawn_point: Marker3D = $SpawnPoint

var _floor_progress = null
var _floor_done: bool = false

func _ready() -> void:
	_scaffold.tilt_changed.connect(_on_tilt_changed)
	_floor_progress = load("res://systems/FloorProgressSystem.gd").new()
	add_child(_floor_progress)
	_floor_progress.floor_completed.connect(_on_floor_completed)
	_setup_players()
	_setup_building()

func _setup_players() -> void:
	var players := get_tree().get_nodes_in_group("players")
	for p in players:
		if not p.has_method("set_respawn_position"):
			continue
		var offset := Vector3(0.0, 0.0, (p.player_index - 0.5) * 0.8)
		var spawn_pos: Vector3 = _spawn_point.global_position + offset
		p.set_respawn_position(spawn_pos)
		p.global_position = spawn_pos

func _setup_building() -> void:
	# Building wall — static backdrop the windows sit on
	var wall := StaticBody3D.new()
	wall.name = "BuildingWall"
	add_child(wall)
	wall.global_position = Vector3(0.0, 0.7, -2.65)

	var wall_col := CollisionShape3D.new()
	var wall_shape := BoxShape3D.new()
	wall_shape.size = Vector3(8.0, 6.0, 0.3)
	wall_col.shape = wall_shape
	wall.add_child(wall_col)

	var wall_mesh := MeshInstance3D.new()
	var wall_box := BoxMesh.new()
	wall_box.size = Vector3(8.0, 6.0, 0.3)
	wall_mesh.mesh = wall_box
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.78, 0.75, 0.70)
	wall_mesh.material_override = wall_mat
	wall.add_child(wall_mesh)

	# 6 windows: 2 rows x 3 cols centred on the wall
	var WinClass = load("res://scenes/windows/WindowPane.gd")
	var cols := 3
	var rows := 2
	var spacing_x := 2.2
	var spacing_y := 1.5
	var grid_origin := Vector3(-spacing_x, -0.35, -2.5)

	for row in rows:
		for col in cols:
			var win = WinClass.new()
			win.name = "Window_R%d_C%d" % [row, col]
			add_child(win)
			win.global_position = grid_origin + Vector3(col * spacing_x, row * spacing_y, 0.0)
			win.window_cleaned.connect(_on_window_cleaned)

	# Soap bucket sitting on the scaffold platform
	var BucketClass = load("res://entities/tools/SoapBucket.gd")
	var bucket = BucketClass.new()
	bucket.name = "SoapBucket"

	var bucket_col := CollisionShape3D.new()
	var bucket_shape := CylinderShape3D.new()
	bucket_shape.height = 0.4
	bucket_shape.radius = 0.15
	bucket_col.shape = bucket_shape
	bucket.add_child(bucket_col)

	var bucket_mesh := MeshInstance3D.new()
	var bucket_cyl := CylinderMesh.new()
	bucket_cyl.height = 0.4
	bucket_cyl.top_radius = 0.15
	bucket_cyl.bottom_radius = 0.15
	bucket_mesh.mesh = bucket_cyl
	var bucket_mat := StandardMaterial3D.new()
	bucket_mat.albedo_color = Color(0.2, 0.5, 0.9)
	bucket_mesh.material_override = bucket_mat
	bucket.add_child(bucket_mesh)

	add_child(bucket)
	bucket.global_position = Vector3(0.0, 0.6, 0.3)

func _on_window_cleaned() -> void:
	if _floor_progress == null:
		return
	_floor_progress.check_completion()
	var pct: float = _floor_progress.get_clean_percent()
	if is_instance_valid(_hud):
		_hud.set_clean_progress(pct)

func _on_floor_completed(clean_percent: float) -> void:
	_floor_done = true
	if is_instance_valid(_hud):
		_hud.show_win(clean_percent)

func _on_tilt_changed(angle: float) -> void:
	if not is_instance_valid(_hud):
		return
	_hud.update_tilt(angle, _scaffold.get_tilt_state())

func _process(_delta: float) -> void:
	if not is_instance_valid(_hud) or not is_instance_valid(_scaffold):
		return
	var players := get_tree().get_nodes_in_group("players")
	var pstates := ""
	for p in players:
		pstates += "P%d:%s " % [p.player_index, str(p.get_state())]
		if p.has_method("get_soap"):
			_hud.update_soap(p.player_index, p.get_soap())
	if _floor_progress != null and not _floor_done:
		_hud.set_clean_progress(_floor_progress.get_clean_percent())
	_hud.set_debug("Y:%.2f %s" % [_scaffold.global_position.y, pstates])
