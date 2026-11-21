class_name HUD
extends CanvasLayer
## Centre dot, use prompts, night clock, objective, subtitles,
## plus the "clock in" title card and the 6 AM end card.

signal intro_clicked

var _root: Control
var _dot: Control
var _prompt: Label
var _clock: Label
var _night: Label
var _objective: Label
var _subtitle_panel: PanelContainer
var _subtitle: Label
var _fade: ColorRect
var _intro: Control
var _end: Control
var _targeting := false
var _sub_token := 0


func _ready() -> void:
	layer = 5
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_dot = Control.new()
	_dot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dot.draw.connect(_draw_dot)
	_root.add_child(_dot)

	_prompt = _label(18, Control.PRESET_CENTER, Color(1, 1, 1, 0.9))
	_prompt.offset_top = 150
	_prompt.offset_bottom = 180
	_prompt.offset_left = -300
	_prompt.offset_right = 300
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_clock = _label(34, Control.PRESET_TOP_RIGHT, Color(0.95, 0.92, 0.85))
	_clock.offset_left = -220
	_clock.offset_right = -28
	_clock.offset_top = 18
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_night = _label(16, Control.PRESET_TOP_RIGHT, Color(0.85, 0.6, 0.55))
	_night.offset_left = -220
	_night.offset_right = -30
	_night.offset_top = 62
	_night.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_night.text = "NIGHT 1"

	_objective = _label(18, Control.PRESET_TOP_LEFT, Color(0.9, 0.9, 0.85, 0.9))
	_objective.offset_left = 28
	_objective.offset_top = 22
	_objective.offset_right = 700

	_subtitle_panel = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 0, 0, 0.6)
	sb.set_content_margin_all(12)
	sb.set_corner_radius_all(4)
	_subtitle_panel.add_theme_stylebox_override("panel", sb)
	_subtitle_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle_panel.offset_left = -440
	_subtitle_panel.offset_right = 440
	_subtitle_panel.offset_top = -130
	_subtitle_panel.offset_bottom = -60
	_subtitle_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_subtitle_panel.visible = false
	_root.add_child(_subtitle_panel)
	_subtitle = Label.new()
	_subtitle.add_theme_font_size_override("font_size", 21)
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_panel.add_child(_subtitle)

	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade)

	_build_intro()


func _label(font_size: int, preset: Control.LayoutPreset, color: Color) -> Label:
	var l := Label.new()
	l.set_anchors_and_offsets_preset(preset)
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(l)
	return l


func _build_intro() -> void:
	_intro = Control.new()
	_intro.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_intro.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_intro)
	var bg := ColorRect.new()
	bg.color = Color(0.01, 0.0, 0.02, 0.92)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -400
	box.offset_right = 400
	box.offset_top = -150
	box.offset_bottom = 150
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_intro.add_child(box)
	_center_text(box, "CATCH ME AT NIGHT", 64, Color(0.92, 0.85, 0.85))
	_center_text(box, "NIGHT 1   ·   12:00 AM", 22, Color(0.85, 0.35, 0.35))
	_center_text(box, "", 10, Color.WHITE)
	var click := _center_text(box, "click to clock in", 20, Color(0.8, 0.8, 0.8))
	var tw := create_tween().set_loops()
	tw.tween_property(click, "modulate:a", 0.25, 0.9)
	tw.tween_property(click, "modulate:a", 1.0, 0.9)
	_center_text(box, "mouse look · WASD walk · E use · T check watch", 15, Color(0.6, 0.6, 0.6))
	_intro.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			intro_clicked.emit())


func _center_text(parent: Control, text: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _draw_dot() -> void:
	var c := _dot.size * 0.5
	if _targeting:
		_dot.draw_arc(c, 10.0, 0.0, TAU, 32, Color(1, 1, 1, 0.85), 2.0, true)
		_dot.draw_circle(c, 2.5, Color(1, 1, 1, 0.95))
	else:
		_dot.draw_circle(c, 3.0, Color(1, 1, 1, 0.7))


# ------------------------------------------------------------ public API

func hide_intro() -> void:
	var tw := create_tween()
	tw.tween_property(_intro, "modulate:a", 0.0, 0.6)
	tw.tween_callback(_intro.hide)
	fade_from_black(2.5)


func skip_intro() -> void:
	_intro.hide()
	_fade.modulate.a = 0.0


func fade_from_black(duration: float) -> void:
	_fade.modulate.a = 1.0
	create_tween().tween_property(_fade, "modulate:a", 0.0, duration)


func flash_black(duration := 0.12) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "modulate:a", 1.0, duration * 0.3)
	tw.tween_property(_fade, "modulate:a", 0.0, duration)


func set_prompt(text: String) -> void:
	_targeting = text != ""
	_prompt.text = ("[E]  " + text) if _targeting else ""
	_dot.queue_redraw()


func set_dot_visible(on: bool) -> void:
	_dot.visible = on
	_prompt.visible = on


func set_clock(text: String) -> void:
	_clock.text = text


func set_objective(text: String) -> void:
	_objective.text = ("▸ " + text) if text != "" else ""
	_objective.modulate.a = 0.0
	create_tween().tween_property(_objective, "modulate:a", 1.0, 0.6)


func show_subtitle(text: String, seconds: float) -> void:
	_sub_token += 1
	var token := _sub_token
	_subtitle.text = text
	_subtitle_panel.visible = true
	await get_tree().create_timer(seconds).timeout
	if token == _sub_token:
		_subtitle_panel.visible = false


func show_end(title: String, subtitle: String) -> void:
	_end = Control.new()
	_end.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_end.modulate.a = 0.0
	add_child(_end)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.9)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_end.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -400
	box.offset_right = 400
	box.offset_top = -80
	box.offset_bottom = 80
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	_end.add_child(box)
	_center_text(box, title, 72, Color(1, 0.95, 0.8))
	_center_text(box, subtitle, 24, Color(0.85, 0.85, 0.85))
	create_tween().tween_property(_end, "modulate:a", 1.0, 2.0)
