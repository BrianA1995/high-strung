extends CanvasLayer

@onready var _tilt_label: Label    = $VBox/TiltLabel
@onready var _state_label: Label   = $VBox/StateLabel
@onready var _debug_label: Label   = $VBox/DebugLabel
@onready var _tilt_bar: ProgressBar = $VBox/TiltBar

var _clean_label: Label       = null
var _clean_bar: ProgressBar   = null
var _soap_labels: Array       = []
var _win_panel: ColorRect     = null
var _win_label: Label         = null

func _ready() -> void:
	var vbox: VBoxContainer = $VBox

	_clean_label = Label.new()
	_clean_label.text = "Clean: 0%"
	vbox.add_child(_clean_label)

	_clean_bar = ProgressBar.new()
	_clean_bar.max_value = 1.0
	_clean_bar.value = 0.0
	_clean_bar.custom_minimum_size = Vector2(160, 16)
	vbox.add_child(_clean_bar)

	const SOAP_COLORS := [Color.DODGER_BLUE, Color.TOMATO, Color(0.2, 0.8, 0.2), Color(1.0, 0.85, 0.1)]
	for i in 4:
		var lbl := Label.new()
		lbl.text = "P%d Soap: ||||||||" % i
		lbl.modulate = SOAP_COLORS[i]
		vbox.add_child(lbl)
		_soap_labels.append(lbl)

	_win_panel = ColorRect.new()
	_win_panel.color = Color(0.0, 0.0, 0.0, 0.75)
	_win_panel.set_anchors_preset(Control.PRESET_CENTER)
	_win_panel.custom_minimum_size = Vector2(400, 140)
	_win_panel.offset_left   = -200
	_win_panel.offset_right  =  200
	_win_panel.offset_top    = -70
	_win_panel.offset_bottom =  70
	_win_panel.visible = false
	add_child(_win_panel)

	_win_label = Label.new()
	_win_label.text = "FLOOR COMPLETE!"
	_win_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_win_label.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	_win_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win_panel.add_child(_win_label)

func update_tilt(angle: float, state: StringName) -> void:
	if _tilt_label:
		_tilt_label.text = "Tilt: %.1f°" % angle
	if _tilt_bar:
		_tilt_bar.value = angle
	if _state_label:
		_state_label.text = str(state)
		match state:
			&"SAFE":        _state_label.modulate = Color.GREEN
			&"WARNING":     _state_label.modulate = Color.YELLOW
			&"DANGER":      _state_label.modulate = Color(1.0, 0.5, 0.0)
			&"CATASTROPHE": _state_label.modulate = Color.RED

func set_clean_progress(value: float) -> void:
	if _clean_label:
		_clean_label.text = "Clean: %.0f%%" % (value * 100.0)
	if _clean_bar:
		_clean_bar.value = value

func update_soap(player_index: int, soap: float) -> void:
	if player_index >= _soap_labels.size():
		return
	var filled := roundi(soap * 8.0)
	var bar := "|".repeat(filled) + ".".repeat(8 - filled)
	_soap_labels[player_index].text = "P%d Soap: %s" % [player_index, bar]

func show_win(clean_percent: float) -> void:
	if _win_panel:
		_win_panel.visible = true
	if _win_label:
		_win_label.text = "FLOOR COMPLETE!\n%.0f%% clean" % (clean_percent * 100.0)

func set_debug(text: String) -> void:
	if _debug_label:
		_debug_label.text = text
