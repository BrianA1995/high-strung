extends Control

const PLAYER_COLORS := [
	Color(0.12, 0.56, 1.0),
	Color(1.0,  0.39, 0.28),
	Color(0.2,  0.80, 0.2),
	Color(1.0,  0.85, 0.1),
]

func _ready() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.10)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var panel := VBoxContainer.new()
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 14)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(360, 520)
	panel.offset_left   = -180
	panel.offset_right  =  180
	panel.offset_top    = -260
	panel.offset_bottom =  260
	add_child(panel)

	var title := Label.new()
	title.text = "HIGH STRUNG"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	panel.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "window washing simulator"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.6, 0.6, 0.6)
	subtitle.add_theme_font_size_override("font_size", 16)
	panel.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 28)
	panel.add_child(spacer)

	var prompt := Label.new()
	prompt.text = "HOW MANY PLAYERS?"
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 15)
	prompt.modulate = Color(0.75, 0.75, 0.75)
	panel.add_child(prompt)

	for i in range(1, 5):
		var btn := Button.new()
		btn.text = "%d PLAYER%s" % [i, "S" if i > 1 else " "]
		btn.custom_minimum_size = Vector2(300, 58)
		btn.add_theme_font_size_override("font_size", 24)

		var col: Color = PLAYER_COLORS[i - 1]
		for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			var sty := StyleBoxFlat.new()
			match state_name:
				"hover":    sty.bg_color = col.lightened(0.25)
				"pressed":  sty.bg_color = col.darkened(0.20)
				_:          sty.bg_color = col
			sty.set_corner_radius_all(6)
			btn.add_theme_stylebox_override(state_name, sty)
		btn.add_theme_color_override("font_color",         Color.WHITE)
		btn.add_theme_color_override("font_hover_color",   Color.WHITE)
		btn.add_theme_color_override("font_pressed_color", Color.WHITE)
		btn.pressed.connect(_start_game.bind(i))
		panel.add_child(btn)

	var controls := Label.new()
	controls.text = "P1: WASD+E   P2: Arrows+/   P3: IJKL+U"
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.modulate = Color(0.5, 0.5, 0.5)
	controls.add_theme_font_size_override("font_size", 12)
	panel.add_child(controls)

func _start_game(count: int) -> void:
	GameManager.player_count = count
	get_tree().change_scene_to_file("res://scenes/crew_mode/CrewGame.tscn")
