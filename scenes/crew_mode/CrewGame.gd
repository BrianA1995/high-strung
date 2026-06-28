extends Node3D

@onready var _scaffold: RigidBody3D  = $Scaffold
@onready var _hud: CanvasLayer       = $HUD
@onready var _spawn_point: Marker3D  = $SpawnPoint

const PLAYER_COLORS := [
	Color(0.12, 0.56, 1.0),
	Color(1.0,  0.39, 0.28),
	Color(0.2,  0.80, 0.2),
	Color(1.0,  0.85, 0.1),
]

# Spawn offsets from SpawnPoint per player count (symmetric on X to avoid initial tilt)
const SPAWN_OFFSETS := [
	[Vector3( 0.0,  0.0, 0.3)],
	[Vector3(-0.8,  0.0, 0.3), Vector3(0.8,  0.0, 0.3)],
	[Vector3(-1.5,  0.0, 0.3), Vector3(0.0,  0.0, 0.3), Vector3(1.5,  0.0, 0.3)],
	[Vector3(-2.0,  0.0, 0.3), Vector3(-0.7, 0.0, 0.3), Vector3(0.7,  0.0, 0.3), Vector3(2.0, 0.0, 0.3)],
]

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
	var count: int = GameManager.player_count
	var offsets: Array = SPAWN_OFFSETS[clampi(count - 1, 0, 3)]
	var base: Vector3 = _spawn_point.global_position

	# Spawn P1+ dynamically (P0 is already in the scene)
	var player_scene: PackedScene = load("res://entities/player/Player.tscn")
	for i in range(1, count):
		var p: Node = player_scene.instantiate()
		p.player_index = i
		p.player_color = PLAYER_COLORS[i]
		add_child(p)

	# Position every player using the symmetric offset table
	for p in get_tree().get_nodes_in_group("players"):
		var idx: int = p.player_index
		if idx >= offsets.size():
			continue
		var pos: Vector3 = base + (offsets[idx] as Vector3)
		p.set_respawn_position(pos)
		p.global_position = pos

func _setup_building() -> void:
	# Building wall
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

	# 6 windows: 2 rows × 3 cols
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

	# Soap bucket — placed front-center, clear of spawn area
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
	bucket.global_position = Vector3(0.0, 0.6, -0.6)

func _on_window_cleaned() -> void:
	if _floor_progress == null:
		return
	_floor_progress.check_completion()
	if is_instance_valid(_hud):
		_hud.set_clean_progress(_floor_progress.get_clean_percent())

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
