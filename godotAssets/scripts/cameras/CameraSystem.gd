class_name CameraSystem
extends CanvasLayer
## Full-screen camera view, shown after the player "leans into" the desk monitor.
## Number keys 1-8 or the map buttons switch cameras.
## ESC, S, right click or the LOWER button go back to the office.

signal close_requested
signal camera_switched(index: int)

## Map layout: camera index -> box on the map (panel coordinates).
const MAP_ROOMS := {
	0: Rect2(120, 14, 92, 34),   # stage
	3: Rect2(226, 14, 92, 34),   # backstage
	4: Rect2(14, 14, 92, 34),    # bathroom
	5: Rect2(14, 66, 92, 34),    # east hall
	7: Rect2(120, 66, 92, 34),   # show floor
	6: Rect2(226, 66, 92, 34),   # back vent
	1: Rect2(40, 128, 92, 34),   # left hall
	2: Rect2(200, 128, 92, 34),  # right hall
}
const OFFICE_RECT := Rect2(120, 186, 92, 34)
const LINKS := [[0, 1], [0, 2], [0, 3], [3, 6], [0, 4], [4, 5], [5, 7], [0, 7]]

var is_open := false

var _feed: SecurityFeed
var _root: Control
var _screen: TextureRect
var _map: Control
var _buttons := {}


func setup(feed: SecurityFeed, feed_texture: Texture2D) -> void:
	_feed = feed
	layer = 10
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.visible = false
	_root.modulate.a = 0.0
	add_child(_root)

	var bg := ColorRect.new()
	bg.color = Color.BLACK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(bg)

	_screen = TextureRect.new()
	_screen.texture = feed_texture
	_screen.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_screen.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_screen)

	_build_map()

	var hint := Label.new()
	hint.text = "1-8  switch camera        ESC / S / right click  lower monitor"
	hint.add_theme_font_size_override("font_size", 16)
	hint.add_theme_color_override("font_color", Color(0.75, 0.8, 0.75, 0.8))
	hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint.offset_top = -34
	hint.offset_left = -300
	hint.offset_right = 300
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(hint)

	var lower := _flat_button("▼  LOWER", Color(0.12, 0.12, 0.12, 0.85))
	lower.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	lower.offset_left = -80
	lower.offset_right = 80
	lower.offset_top = 14
	lower.offset_bottom = 48
	lower.pressed.connect(func() -> void: close_requested.emit())
	_root.add_child(lower)

	_feed.switched.connect(_on_switched)
	_on_switched(_feed.current)


func _build_map() -> void:
	_map = Control.new()
	_map.custom_minimum_size = Vector2(332, 234)
	_map.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	_map.offset_left = -352
	_map.offset_top = -280
	_map.offset_right = -20
	_map.offset_bottom = -46
	_map.draw.connect(_draw_map)
	_root.add_child(_map)
	for idx in MAP_ROOMS:
		var r: Rect2 = MAP_ROOMS[idx]
		var b := _flat_button("CAM %d" % (idx + 1), Color(0.1, 0.16, 0.12, 0.9))
		b.position = r.position
		b.size = r.size
		b.pressed.connect(_select.bind(idx))
		_map.add_child(b)
		_buttons[idx] = b
	var you := Label.new()
	you.text = "YOU"
	you.position = OFFICE_RECT.position
	you.size = OFFICE_RECT.size
	you.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	you.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	you.add_theme_color_override("font_color", Color(1, 0.85, 0.4))
	_map.add_child(you)


func _flat_button(text: String, color: Color) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 15)
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = color.lightened(0.15) if state == "hover" else color
		sb.border_color = Color(0.4, 0.6, 0.45, 0.8)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(3)
		b.add_theme_stylebox_override(state, sb)
	return b


func _draw_map() -> void:
	_map.draw_rect(Rect2(Vector2.ZERO, _map.size), Color(0.02, 0.05, 0.03, 0.75))
	_map.draw_rect(Rect2(Vector2.ZERO, _map.size), Color(0.3, 0.5, 0.35, 0.8), false, 1.0)
	var line := Color(0.35, 0.55, 0.4, 0.7)
	for link in LINKS:
		var a: Rect2 = MAP_ROOMS[link[0]]
		var b: Rect2 = MAP_ROOMS[link[1]]
		_map.draw_line(a.get_center(), b.get_center(), line, 2.0)
	for idx in [1, 2, 6]:
		var r: Rect2 = MAP_ROOMS[idx]
		_map.draw_line(r.get_center(), OFFICE_RECT.get_center(), line, 2.0)
	_map.draw_rect(OFFICE_RECT, Color(0.25, 0.2, 0.05, 0.9))
	_map.draw_rect(OFFICE_RECT, Color(1, 0.85, 0.4), false, 1.5)


func _select(idx: int) -> void:
	if idx != _feed.current:
		_feed.switch_to(idx)


func _on_switched(idx: int) -> void:
	for k in _buttons:
		var b: Button = _buttons[k]
		b.modulate = Color(0.6, 1.6, 0.8) if k == idx else Color.WHITE
	camera_switched.emit(idx)


func open() -> void:
	is_open = true
	_root.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_feed.glitch(0.5)
	create_tween().tween_property(_root, "modulate:a", 1.0, 0.18)


func close() -> void:
	is_open = false
	var tw := create_tween()
	tw.tween_property(_root, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func() -> void: _root.visible = false)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input(event: InputEvent) -> void:
	if not is_open:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key: int = event.physical_keycode
		if key in [KEY_ESCAPE, KEY_S, KEY_E, KEY_DOWN]:
			close_requested.emit()
			get_viewport().set_input_as_handled()
		elif key >= KEY_1 and key <= KEY_8:
			_select(key - KEY_1)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		close_requested.emit()
		get_viewport().set_input_as_handled()
