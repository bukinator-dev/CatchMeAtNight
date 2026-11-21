class_name SecurityFeed
extends Control
## Draws the security-camera picture for the active camera into its SubViewport.
## The same picture shows on the desk CRT and in the full-screen camera view.
## Rooms are simple drawings for now; swap _draw_<room>() for real renders later.

signal switched(index: int)

const W := 640.0
const H := 480.0
const CAMS := [
	{"id": "stage", "name": "STAGE"},
	{"id": "leftHall", "name": "L. HALL"},
	{"id": "rightHall", "name": "R. HALL"},
	{"id": "backstage", "name": "BACKSTAGE"},
	{"id": "bathroom", "name": "BATHROOM"},
	{"id": "eastHall", "name": "E. HALL"},
	{"id": "backVent", "name": "BACK VENT"},
	{"id": "showFloor", "name": "SHOW FLOOR"},
]
const LILLY_REGION := Rect2(20, 280, 520, 1203)

var current := 0
## Where Lilly is: "stage", "leftHall", "leftHallNear" or "office" (outside the door, off camera).
var lilly_at := "stage"
var clock_text := "12:00 AM"

var _lilly_tex: Texture2D
var _static: ColorRect
var _static_mat: ShaderMaterial
var _name_label: Label
var _time_label: Label
var _rec_label: Label
var _t := 0.0
var _far := Rect2(250, 172, 140, 108)


func _ready() -> void:
	size = Vector2(W, H)
	_lilly_tex = load("res://assets/characters/lilly/lily-poses-clean.png")
	_static = ColorRect.new()
	_static.size = Vector2(W, H)
	_static.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_static_mat = ShaderMaterial.new()
	_static_mat.shader = load("res://shaders/feed_static.gdshader")
	_static.material = _static_mat
	add_child(_static)
	_name_label = _make_label(Vector2(18, 12), 26)
	_rec_label = _make_label(Vector2(W - 110, 12), 26)
	_rec_label.text = "● REC"
	_rec_label.add_theme_color_override("font_color", Color(1, 0.25, 0.2))
	_time_label = _make_label(Vector2(18, H - 44), 22)
	switch_to(0, false)


func _make_label(pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", Color(0.92, 0.95, 0.9))
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	add_child(l)
	return l


func switch_to(index: int, with_static := true) -> void:
	current = clampi(index, 0, CAMS.size() - 1)
	var cam: Dictionary = CAMS[current]
	_name_label.text = "CAM %d  %s" % [current + 1, cam["name"]]
	if with_static:
		glitch(0.35)
	queue_redraw()
	switched.emit(current)


func glitch(duration := 0.35) -> void:
	_static_mat.set_shader_parameter("static_amount", 1.0)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _static_mat.set_shader_parameter("static_amount", v), 1.0, 0.12, duration)


func current_id() -> String:
	return CAMS[current]["id"]


func set_lilly(location: String) -> void:
	lilly_at = location
	queue_redraw()


func _process(delta: float) -> void:
	_t += delta
	_rec_label.visible = fmod(_t, 1.2) < 0.75
	_time_label.text = "%s   NOV 15" % clock_text


# ---------------------------------------------------------------- drawing

func _draw() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.02, 0.02, 0.03))
	match current_id():
		"stage": _draw_stage()
		"leftHall": _draw_left_hall()
		"rightHall": _draw_right_hall()
		"backstage": _draw_backstage()
		"bathroom": _draw_bathroom()
		"eastHall": _draw_east_hall()
		"backVent": _draw_vent()
		"showFloor": _draw_show_floor()


## Point on a corridor surface. f = depth (0 near .. 1 far), v = height (0 floor .. 1 ceiling).
func _wall_pt(side: int, f: float, v: float) -> Vector2:
	var near_x := 0.0 if side < 0 else W
	var far_x := _far.position.x if side < 0 else _far.end.x
	var near := Vector2(near_x, lerpf(H, 0.0, v))
	var far := Vector2(far_x, lerpf(_far.end.y, _far.position.y, v))
	return near.lerp(far, f)


## Point on the floor (v=0) or ceiling (v=1). u = across (0 left .. 1 right).
func _flat_pt(u: float, f: float, v: float) -> Vector2:
	var near := Vector2(lerpf(0.0, W, u), lerpf(H, 0.0, v))
	var far := Vector2(lerpf(_far.position.x, _far.end.x, u), lerpf(_far.end.y, _far.position.y, v))
	return near.lerp(far, f)


func _poly(points: Array, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)


func _corridor(wall: Color, floor_c: Color, ceil_c: Color, far := Rect2(250, 172, 140, 108)) -> void:
	_far = far
	var tl := _far.position
	var top_r := Vector2(_far.end.x, _far.position.y)
	var bl := Vector2(_far.position.x, _far.end.y)
	var br := _far.end
	_poly([Vector2(0, 0), Vector2(W, 0), top_r, tl], ceil_c)
	_poly([Vector2(0, H), bl, br, Vector2(W, H)], floor_c)
	_poly([Vector2(0, 0), tl, bl, Vector2(0, H)], wall)
	_poly([Vector2(W, 0), Vector2(W, H), br, top_r], wall.darkened(0.18))
	draw_rect(_far, wall.darkened(0.6))
	# checker floor lines
	for i in range(1, 8):
		var u := i / 8.0
		draw_line(_flat_pt(u, 0.0, 0.0), _flat_pt(u, 1.0, 0.0), floor_c.darkened(0.35), 1.0)
	for f in [0.3, 0.52, 0.67, 0.78, 0.86, 0.92]:
		draw_line(_flat_pt(0, f, 0), _flat_pt(1, f, 0), floor_c.darkened(0.35), 1.0)
	# wainscot line on both walls
	for side in [-1, 1]:
		draw_line(_wall_pt(side, 0.0, 0.38), _wall_pt(side, 1.0, 0.38), wall.darkened(0.4), 2.0)


func _door(side: int, f0: float, f1: float, color: Color, open := false) -> void:
	var pts := [_wall_pt(side, f0, 0.0), _wall_pt(side, f1, 0.0), _wall_pt(side, f1, 0.74), _wall_pt(side, f0, 0.74)]
	_poly(pts, Color(0.01, 0.01, 0.02) if open else color)
	draw_polyline(PackedVector2Array(pts + [pts[0]]), color.darkened(0.5), 2.0)


func _ceiling_light(f0: float, f1: float, on := true) -> void:
	var pts := [_flat_pt(0.4, f0, 1.0), _flat_pt(0.6, f0, 1.0), _flat_pt(0.6, f1, 1.0), _flat_pt(0.4, f1, 1.0)]
	_poly(pts, Color(0.85, 0.9, 0.8) if on else Color(0.2, 0.2, 0.2))
	if on:
		var c: Vector2 = (pts[0] + pts[2]) * 0.5
		for r in [90.0, 60.0, 35.0]:
			draw_circle(c + Vector2(0, 30), r, Color(0.8, 0.85, 0.7, 0.05))


func _poster(side: int, f0: float, f1: float, color: Color) -> void:
	_poly([_wall_pt(side, f0, 0.45), _wall_pt(side, f1, 0.45), _wall_pt(side, f1, 0.7), _wall_pt(side, f0, 0.7)], color)


func _lilly(feet: Vector2, height: float, tint := Color(0.85, 0.8, 0.8)) -> void:
	var w := height * LILLY_REGION.size.x / LILLY_REGION.size.y
	draw_texture_rect_region(_lilly_tex, Rect2(feet.x - w * 0.5, feet.y - height, w, height), LILLY_REGION, tint)


## Simple placeholder silhouette until Mariam / Diana have art.
func _girl(feet: Vector2, height: float, hair: Color, dress: Color, long_hair: bool) -> void:
	var s := height / 200.0
	var skin := Color(0.82, 0.7, 0.62)
	draw_rect(Rect2(feet.x - 14 * s, feet.y - 60 * s, 8 * s, 60 * s), skin.darkened(0.2))
	draw_rect(Rect2(feet.x + 6 * s, feet.y - 60 * s, 8 * s, 60 * s), skin.darkened(0.2))
	_poly([feet + Vector2(-40, -55) * s, feet + Vector2(40, -55) * s, feet + Vector2(18, -125) * s, feet + Vector2(-18, -125) * s], dress)
	draw_rect(Rect2(feet.x - 18 * s, feet.y - 140 * s, 36 * s, 18 * s), dress.darkened(0.2))
	if long_hair:
		draw_rect(Rect2(feet.x - 30 * s, feet.y - 190 * s, 60 * s, 85 * s), hair.darkened(0.15))
	draw_circle(feet + Vector2(0, -165) * s, 26 * s, skin)
	draw_circle(feet + Vector2(0, -180) * s, 28 * s, hair)
	if not long_hair:
		draw_rect(Rect2(feet.x - 30 * s, feet.y - 182 * s, 60 * s, 30 * s), hair)
	# eyes: two small pale dots that catch the camera IR
	draw_circle(feet + Vector2(-9, -163) * s, 3.2 * s, Color(0.95, 0.95, 0.9))
	draw_circle(feet + Vector2(9, -163) * s, 3.2 * s, Color(0.95, 0.95, 0.9))


func _draw_stage() -> void:
	# back curtain with folds
	draw_rect(Rect2(0, 0, W, 330), Color(0.32, 0.04, 0.07))
	for i in 16:
		var x := i * 40.0
		draw_rect(Rect2(x, 0, 14, 330), Color(0.22, 0.02, 0.05))
	draw_rect(Rect2(0, 0, W, 40), Color(0.45, 0.06, 0.1))
	for i in 8:
		draw_circle(Vector2(i * 90 + 30, 40), 26, Color(0.45, 0.06, 0.1))
	# stage floor
	_poly([Vector2(0, 330), Vector2(W, 330), Vector2(W, H), Vector2(0, H)], Color(0.28, 0.17, 0.1))
	for i in 10:
		draw_line(Vector2(i * 70 - 40, H), Vector2(160 + i * 35, 330), Color(0.18, 0.1, 0.06), 2)
	draw_rect(Rect2(0, 440, W, 40), Color(0.12, 0.07, 0.05))
	# spotlights
	for x in [150.0, 320.0, 490.0]:
		_poly([Vector2(x - 20, 0), Vector2(x + 20, 0), Vector2(x + 85, 400), Vector2(x - 85, 400)], Color(1, 0.9, 0.6, 0.06))
		draw_circle(Vector2(x, 395), 70, Color(1, 0.9, 0.6, 0.05))
	# mic stands
	for x in [150.0, 320.0, 490.0]:
		draw_line(Vector2(x + 40, 410), Vector2(x + 40, 255), Color(0.15, 0.15, 0.15), 3)
		draw_circle(Vector2(x + 40, 252), 6, Color(0.25, 0.25, 0.25))
	_girl(Vector2(150, 410), 215, Color(0.12, 0.08, 0.06), Color(0.1, 0.45, 0.45), true)   # Mariam
	_girl(Vector2(490, 410), 215, Color(0.88, 0.85, 0.72), Color(0.35, 0.22, 0.5), false)  # Diana
	if lilly_at == "stage":
		_lilly(Vector2(320, 418), 245)
	else:
		# empty spot, her mic stand knocked over
		draw_line(Vector2(360, 410), Vector2(420, 395), Color(0.15, 0.15, 0.15), 3)


func _draw_left_hall() -> void:
	_corridor(Color(0.33, 0.3, 0.26), Color(0.3, 0.29, 0.25), Color(0.2, 0.2, 0.2))
	_door(-1, 0.2, 0.45, Color(0.32, 0.2, 0.12))
	_door(1, 0.55, 0.72, Color(0.32, 0.2, 0.12))
	_poster(1, 0.15, 0.35, Color(0.6, 0.15, 0.2))
	_ceiling_light(0.25, 0.4)
	_ceiling_light(0.7, 0.8, false)
	# the office door at the end, with its little sign
	draw_rect(Rect2(292, 196, 56, 84), Color(0.15, 0.15, 0.17))
	draw_rect(Rect2(300, 186, 40, 8), Color(0.6, 0.6, 0.55))
	if lilly_at == "leftHall":
		_lilly(Vector2(312, 300), 120, Color(0.75, 0.7, 0.7))
	elif lilly_at == "leftHallNear":
		_lilly(Vector2(250, 520), 420, Color(0.8, 0.72, 0.72))


func _draw_right_hall() -> void:
	_corridor(Color(0.28, 0.3, 0.32), Color(0.27, 0.27, 0.26), Color(0.18, 0.18, 0.2), Rect2(300, 180, 120, 95))
	_door(-1, 0.4, 0.6, Color(0.25, 0.25, 0.3))
	_ceiling_light(0.2, 0.32)
	_ceiling_light(0.6, 0.7)
	# vent grate low on the right wall
	var g := [_wall_pt(1, 0.3, 0.05), _wall_pt(1, 0.45, 0.05), _wall_pt(1, 0.45, 0.2), _wall_pt(1, 0.3, 0.2)]
	_poly(g, Color(0.12, 0.12, 0.13))
	for i in 5:
		var v := 0.07 + i * 0.03
		draw_line(_wall_pt(1, 0.3, v), _wall_pt(1, 0.45, v), Color(0.35, 0.35, 0.36), 2)


func _draw_backstage() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.16, 0.14, 0.15))
	_poly([Vector2(0, 340), Vector2(W, 340), Vector2(W, H), Vector2(0, H)], Color(0.2, 0.18, 0.16))
	# vanity mirror with bulbs
	draw_rect(Rect2(60, 90, 200, 150), Color(0.35, 0.33, 0.3))
	draw_rect(Rect2(75, 105, 170, 120), Color(0.08, 0.09, 0.11))
	for i in 6:
		draw_circle(Vector2(75 + i * 34, 96), 7, Color(1, 0.9, 0.6) if i != 3 else Color(0.3, 0.3, 0.3))
	draw_rect(Rect2(50, 240, 220, 100), Color(0.3, 0.2, 0.14))
	# costume rack
	draw_line(Vector2(340, 120), Vector2(600, 120), Color(0.5, 0.5, 0.5), 4)
	var colors := [Color(0.6, 0.1, 0.15), Color(0.1, 0.4, 0.4), Color(0.35, 0.2, 0.5), Color(0.6, 0.1, 0.15)]
	for i in 4:
		var x := 360.0 + i * 60.0
		_poly([Vector2(x, 125), Vector2(x + 40, 125), Vector2(x + 52, 300), Vector2(x - 12, 300)], colors[i])
	# boxes
	draw_rect(Rect2(420, 330, 120, 90), Color(0.42, 0.32, 0.2))
	draw_rect(Rect2(470, 270, 80, 60), Color(0.38, 0.28, 0.18))
	# a spare head on the shelf. Don't think about it.
	draw_circle(Vector2(160, 200), 22, Color(0.75, 0.65, 0.58))
	draw_circle(Vector2(152, 196), 2.5, Color.BLACK)
	draw_circle(Vector2(168, 196), 2.5, Color.BLACK)


func _draw_bathroom() -> void:
	_corridor(Color(0.55, 0.6, 0.58), Color(0.4, 0.42, 0.42), Color(0.3, 0.3, 0.3), Rect2(260, 175, 120, 100))
	# tile grid on walls
	for side in [-1, 1]:
		for k in range(1, 9):
			var v := k / 9.0
			draw_line(_wall_pt(side, 0.0, v), _wall_pt(side, 1.0, v), Color(0.42, 0.47, 0.45), 1)
	# stalls on the right
	for i in 3:
		var f0 := 0.1 + i * 0.25
		_poly([_wall_pt(1, f0, 0.05), _wall_pt(1, f0 + 0.18, 0.05), _wall_pt(1, f0 + 0.18, 0.7), _wall_pt(1, f0, 0.7)], Color(0.35, 0.4, 0.5))
	# mirror and sinks on the left
	_poly([_wall_pt(-1, 0.2, 0.45), _wall_pt(-1, 0.6, 0.45), _wall_pt(-1, 0.6, 0.7), _wall_pt(-1, 0.2, 0.7)], Color(0.15, 0.17, 0.2))
	_ceiling_light(0.4, 0.5)


func _draw_east_hall() -> void:
	_corridor(Color(0.25, 0.25, 0.32), Color(0.24, 0.23, 0.26), Color(0.15, 0.15, 0.18), Rect2(220, 165, 160, 115))
	# windows with moonlight
	for i in 3:
		var f0 := 0.08 + i * 0.28
		var pts := [_wall_pt(-1, f0, 0.4), _wall_pt(-1, f0 + 0.16, 0.4), _wall_pt(-1, f0 + 0.16, 0.8), _wall_pt(-1, f0, 0.8)]
		_poly(pts, Color(0.2, 0.25, 0.4))
		_poly([_flat_pt(0.05, f0, 0), _flat_pt(0.35, f0 + 0.1, 0), _flat_pt(0.35, f0 + 0.22, 0), _flat_pt(0.05, f0 + 0.16, 0)], Color(0.4, 0.45, 0.6, 0.25))
	_door(1, 0.3, 0.5, Color(0.3, 0.22, 0.14))


func _draw_vent() -> void:
	draw_rect(Rect2(0, 0, W, H), Color(0.06, 0.06, 0.07))
	for i in 7:
		var k := i / 7.0
		var r := Rect2(Vector2(W, H) * 0.5 * k * 0.92, Vector2(W, H) * (1.0 - k * 0.92))
		draw_rect(r, Color(0.32, 0.33, 0.35).darkened(k * 0.9), false, 3.0)
	draw_rect(Rect2(300, 222, 40, 36), Color(0, 0, 0))
	# scratch marks on the duct floor
	for i in 4:
		draw_line(Vector2(250 + i * 12, 420), Vector2(280 + i * 12, 370), Color(0.5, 0.5, 0.5, 0.6), 2)


func _draw_show_floor() -> void:
	draw_rect(Rect2(0, 0, W, 200), Color(0.12, 0.1, 0.14))
	_poly([Vector2(0, 200), Vector2(W, 200), Vector2(W, H), Vector2(0, H)], Color(0.22, 0.18, 0.2))
	# the stage, far away
	draw_rect(Rect2(170, 120, 300, 80), Color(0.3, 0.05, 0.08))
	draw_rect(Rect2(150, 195, 340, 14), Color(0.25, 0.15, 0.1))
	# tables with party hats
	for row in 3:
		for col in 4:
			var c := Vector2(90 + col * 155 + row * 20, 260 + row * 70)
			var sx := 55.0 + row * 12.0
			draw_set_transform(c, 0, Vector2(1, 0.35))
			draw_circle(Vector2.ZERO, sx, Color(0.75, 0.75, 0.72))
			draw_set_transform(Vector2.ZERO)
			_poly([c + Vector2(-8, -6), c + Vector2(8, -6), c + Vector2(0, -32)], Color(0.8, 0.3, 0.4) if (row + col) % 2 == 0 else Color(0.3, 0.6, 0.8))
	# streamers
	for i in 6:
		draw_line(Vector2(i * 120, 0), Vector2(i * 120 + 60, 60), Color(0.7, 0.2, 0.3, 0.6), 3)
