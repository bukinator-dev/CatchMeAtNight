class_name OfficeBuilder
extends Node3D
## Builds the night-security office and the corridor behind its left door.
##
## Layout (metres, origin = floor centre, -Z = toward the desk):
##   room       x -3..3, z -2.5..2.5, ceiling 2.8
##   desk       against the front wall (z -2.5), monitors in the middle
##   left wall  doorway (z -1.15..-0.05) -> dark corridor heading to -X
##   right wall Lilly poster, mirror, vent, water cooler, fridge
##   back wall  lockers, heater, couch with blanket, back vent
##
## Gameplay hooks are exposed as member variables (monitor, phone, shutter, ...).

const W := 6.0
const D := 5.0
const H := 2.8
const DOOR_Z0 := -1.15
const DOOR_Z1 := -0.05
const DOOR_H := 2.15

# --- hooks used by the game director
var monitor: Interactable
var monitor_screen: MeshInstance3D
var monitor_focus: Transform3D
var phone: Interactable
var handset: Node3D
var chair: Interactable
var seat_position := Vector3(0, 0, -1.02)
var seat_yaw := 0.0
var lamp: Interactable
var door_button: Interactable
var shutter: Node3D
var shutter_down := false
var door_light: MeshInstance3D
var ceiling_light: OmniLight3D
var ceiling_tube: MeshInstance3D
var back_light: OmniLight3D
var back_tube: MeshInstance3D
var corridor_light: OmniLight3D
var lamp_light: SpotLight3D
var lamp_bulb: MeshInstance3D
var lamp_on := true
var clock_hour: Node3D
var clock_minute: Node3D
var fan_blades: Node3D
var lilly_in_corridor: Sprite3D
var mirror: Node3D
var terminal_label: Label3D
var microwave_label: Label3D
var environment: Environment

# --- materials
var _wall: StandardMaterial3D
var _wall_dark: StandardMaterial3D
var _wainscot: StandardMaterial3D
var _trim: StandardMaterial3D
var _wood: StandardMaterial3D
var _floor: StandardMaterial3D
var _ceiling: StandardMaterial3D
var _metal: StandardMaterial3D
var _beige_plastic: StandardMaterial3D
var _black_plastic: StandardMaterial3D
var _paper: StandardMaterial3D


func build() -> void:
	_make_materials()
	_build_environment()
	_build_shell()
	_build_corridor()
	_build_desk()
	_build_monitors()
	_build_desk_props()
	_build_chair()
	_build_front_wall_decor()
	_build_right_wall()
	_build_back_wall()
	_build_door_controls()
	_build_lights()


func _make_materials() -> void:
	var paint := TexGen.paint()
	_wall = MeshKit.textured(paint, 1.0, Color(0.62, 0.55, 0.45))
	_wall_dark = MeshKit.textured(paint, 1.0, Color(0.36, 0.33, 0.3))
	_wainscot = MeshKit.textured(paint, 2.0, Color(0.2, 0.3, 0.27), 0.7)
	_trim = MeshKit.textured(TexGen.wood(), 2.0, Color(0.7, 0.55, 0.45), 0.6)
	_wood = MeshKit.textured(TexGen.wood(), 1.2, Color(1.0, 0.85, 0.7), 0.55)
	_floor = MeshKit.textured(TexGen.checker_floor(), 1.0, Color.WHITE, 0.45)
	_ceiling = MeshKit.textured(TexGen.ceiling_tiles(), 1.0 / 0.6, Color(0.85, 0.85, 0.82))
	_metal = MeshKit.mat(Color(0.42, 0.45, 0.44), 0.45, 0.6)
	_beige_plastic = MeshKit.mat(Color(0.66, 0.63, 0.55), 0.6)
	_black_plastic = MeshKit.mat(Color(0.07, 0.07, 0.08), 0.5)
	_paper = MeshKit.mat(Color(0.92, 0.9, 0.84), 0.95)


func _build_environment() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.0, 0.0, 0.01)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.25, 0.27, 0.4)
	environment.ambient_light_energy = 0.3
	environment.tonemap_mode = Environment.TONE_MAPPER_ACES
	environment.tonemap_exposure = 1.05
	environment.glow_enabled = true
	environment.glow_intensity = 0.7
	environment.glow_bloom = 0.04
	environment.glow_hdr_threshold = 0.85
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.03, 0.03, 0.05)
	environment.fog_density = 0.035
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 0.92
	var we := WorldEnvironment.new()
	we.environment = environment
	add_child(we)


# ------------------------------------------------------------------ shell

func _build_shell() -> void:
	var hw := W * 0.5
	var hd := D * 0.5
	MeshKit.box(self, Vector3(W + 0.4, 0.2, D + 0.4), Vector3(0, -0.1, 0), _floor, Vector3.ZERO, true)
	MeshKit.box(self, Vector3(W + 0.4, 0.2, D + 0.4), Vector3(0, H + 0.1, 0), _ceiling, Vector3.ZERO, true)
	# front / back / right walls
	MeshKit.box(self, Vector3(W + 0.4, H, 0.2), Vector3(0, H * 0.5, -hd - 0.1), _wall, Vector3.ZERO, true)
	MeshKit.box(self, Vector3(W + 0.4, H, 0.2), Vector3(0, H * 0.5, hd + 0.1), _wall, Vector3.ZERO, true)
	MeshKit.box(self, Vector3(0.2, H, D + 0.4), Vector3(hw + 0.1, H * 0.5, 0), _wall, Vector3.ZERO, true)
	# left wall, split around the doorway
	var a_len := DOOR_Z0 - (-hd - 0.1)
	MeshKit.box(self, Vector3(0.2, H, a_len), Vector3(-hw - 0.1, H * 0.5, (-hd - 0.1 + DOOR_Z0) * 0.5), _wall, Vector3.ZERO, true)
	var b_len := (hd + 0.1) - DOOR_Z1
	MeshKit.box(self, Vector3(0.2, H, b_len), Vector3(-hw - 0.1, H * 0.5, (DOOR_Z1 + hd + 0.1) * 0.5), _wall, Vector3.ZERO, true)
	MeshKit.box(self, Vector3(0.2, H - DOOR_H, DOOR_Z1 - DOOR_Z0), Vector3(-hw - 0.1, (H + DOOR_H) * 0.5, (DOOR_Z0 + DOOR_Z1) * 0.5), _wall, Vector3.ZERO, true)

	# wainscot panels, chair rail and skirting on each wall face
	_wainscot_run(Vector3(0, 0, -hd), Vector3(1, 0, 0), W, Vector3(0, 0, 1))
	_wainscot_run(Vector3(0, 0, hd), Vector3(1, 0, 0), W, Vector3(0, 0, -1))
	_wainscot_run(Vector3(hw, 0, 0), Vector3(0, 0, 1), D, Vector3(-1, 0, 0))
	_wainscot_run(Vector3(-hw, 0, (-hd + DOOR_Z0) * 0.5), Vector3(0, 0, 1), DOOR_Z0 + hd, Vector3(1, 0, 0))
	_wainscot_run(Vector3(-hw, 0, (DOOR_Z1 + hd) * 0.5), Vector3(0, 0, 1), hd - DOOR_Z1, Vector3(1, 0, 0))

	# crown moulding
	for z in [-hd + 0.03, hd - 0.03]:
		MeshKit.box(self, Vector3(W, 0.08, 0.06), Vector3(0, H - 0.04, z), _trim)
	for x in [-hw + 0.03, hw - 0.03]:
		MeshKit.box(self, Vector3(0.06, 0.08, D), Vector3(x, H - 0.04, 0), _trim)

	# door casing on the office side
	var cx := -hw + 0.03
	MeshKit.box(self, Vector3(0.06, DOOR_H + 0.06, 0.09), Vector3(cx, (DOOR_H + 0.06) * 0.5, DOOR_Z0 - 0.045), _trim)
	MeshKit.box(self, Vector3(0.06, DOOR_H + 0.06, 0.09), Vector3(cx, (DOOR_H + 0.06) * 0.5, DOOR_Z1 + 0.045), _trim)
	MeshKit.box(self, Vector3(0.06, 0.09, DOOR_Z1 - DOOR_Z0 + 0.18), Vector3(cx, DOOR_H + 0.045, (DOOR_Z0 + DOOR_Z1) * 0.5), _trim)
	# hazard stripe on the threshold
	MeshKit.box(self, Vector3(0.2, 0.012, DOOR_Z1 - DOOR_Z0), Vector3(-hw - 0.1, 0.006, (DOOR_Z0 + DOOR_Z1) * 0.5), MeshKit.mat(Color(0.75, 0.6, 0.1), 0.6))


## A run of lower-wall panelling. `center` on the wall face, `along` = run direction, `normal` points into the room.
func _wainscot_run(center: Vector3, along: Vector3, length: float, normal: Vector3) -> void:
	var size_along := along * length
	var thick := normal.abs() * 0.03
	var size := size_along.abs() + thick
	MeshKit.box(self, Vector3(size.x, 1.0, size.z) + Vector3(0, 0, 0), center + normal * 0.015 + Vector3(0, 0.5, 0), _wainscot)
	var rail := size_along.abs() + normal.abs() * 0.05
	MeshKit.box(self, Vector3(rail.x, 0.06, rail.z), center + normal * 0.025 + Vector3(0, 1.02, 0), _trim)
	MeshKit.box(self, Vector3(rail.x, 0.12, rail.z), center + normal * 0.025 + Vector3(0, 0.06, 0), _black_plastic)


func _build_corridor() -> void:
	var x0 := -W * 0.5 - 0.2
	var length := 5.8
	var cx := x0 - length * 0.5
	var z0 := -1.7
	var z1 := 0.5
	var cz := (z0 + z1) * 0.5
	var width := z1 - z0
	var c := Node3D.new()
	c.name = "Corridor"
	add_child(c)
	MeshKit.box(c, Vector3(length, 0.2, width), Vector3(cx, -0.1, cz), _floor, Vector3.ZERO, true)
	MeshKit.box(c, Vector3(length, 0.2, width), Vector3(cx, H + 0.1, cz), _ceiling, Vector3.ZERO, true)
	MeshKit.box(c, Vector3(length, H, 0.2), Vector3(cx, H * 0.5, z0 - 0.1), _wall_dark, Vector3.ZERO, true)
	MeshKit.box(c, Vector3(length, H, 0.2), Vector3(cx, H * 0.5, z1 + 0.1), _wall_dark, Vector3.ZERO, true)
	MeshKit.box(c, Vector3(0.2, H, width + 0.4), Vector3(x0 - length - 0.1, H * 0.5, cz), _wall_dark, Vector3.ZERO, true)
	var stripe := MeshKit.mat(Color(0.25, 0.08, 0.08), 0.8)
	MeshKit.box(c, Vector3(length, 0.9, 0.02), Vector3(cx, 0.45, z0 + 0.01), stripe)
	MeshKit.box(c, Vector3(length, 0.9, 0.02), Vector3(cx, 0.45, z1 - 0.01), stripe)

	# storage door on the side wall
	MeshKit.box(c, Vector3(0.9, 2.05, 0.05), Vector3(-7.0, 1.025, z0 + 0.03), MeshKit.mat(Color(0.3, 0.2, 0.13), 0.7))
	MeshKit.sphere(c, 0.03, Vector3(-6.65, 1.0, z0 + 0.07), _metal)
	MeshKit.label(c, "STORAGE", Vector3(-7.0, 1.7, z0 + 0.06), 64, Color(0.85, 0.8, 0.7), Vector3.ZERO, 0.002)

	# a poster of the trio on the other wall
	var candy: Texture2D = load("res://assets/characters/lilly/lily-candy.png")
	MeshKit.box(c, Vector3(0.62, 0.72, 0.02), Vector3(-5.2, 1.5, z1 - 0.012), _black_plastic)
	MeshKit.sprite(c, candy, 0.56, Vector3(-5.2, 1.5, z1 - 0.025), Vector3(0, 180, 0))

	# exit sign at the far end
	var end_x := x0 - length + 0.02
	MeshKit.box(c, Vector3(0.06, 0.2, 0.5), Vector3(end_x + 0.03, 2.35, cz), MeshKit.glow(Color(0.9, 0.08, 0.06), 3.0))
	MeshKit.label(c, "EXIT", Vector3(end_x + 0.065, 2.35, cz), 96, Color(1, 0.85, 0.8), Vector3(0, 90, 0), 0.0016)
	var exit_light := MeshKit.light_omni(c, Vector3(end_x + 0.5, 2.1, cz), Color(1, 0.15, 0.1), 0.9, 3.5)
	exit_light.name = "ExitLight"

	# one tired ceiling light halfway down
	MeshKit.box(c, Vector3(0.9, 0.05, 0.25), Vector3(-6.2, H - 0.03, cz), _metal)
	MeshKit.box(c, Vector3(0.85, 0.02, 0.2), Vector3(-6.2, H - 0.065, cz), MeshKit.glow(Color(0.7, 0.75, 0.7), 0.6))
	corridor_light = MeshKit.light_omni(c, Vector3(-6.2, 2.4, cz), Color(0.75, 0.85, 0.8), 0.35, 3.5)

	# Lilly, standing at the end of the hall (hidden until she gets here)
	var poses: Texture2D = load("res://assets/characters/lilly/lily-poses-clean.png")
	lilly_in_corridor = Sprite3D.new()
	lilly_in_corridor.texture = poses
	lilly_in_corridor.region_enabled = true
	lilly_in_corridor.region_rect = Rect2(20, 280, 520, 1203)
	lilly_in_corridor.pixel_size = 1.45 / 1203.0
	lilly_in_corridor.position = Vector3(-7.9, 0.725, cz + 0.15)
	lilly_in_corridor.rotation_degrees = Vector3(0, 90, 0)
	lilly_in_corridor.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	lilly_in_corridor.modulate = Color(0.85, 0.75, 0.75)
	lilly_in_corridor.visible = false
	c.add_child(lilly_in_corridor)


# ------------------------------------------------------------------- desk

func _build_desk() -> void:
	MeshKit.box(self, Vector3(3.0, 0.05, 0.8), Vector3(0, 0.745, -2.1), _wood, Vector3.ZERO, true)
	MeshKit.box(self, Vector3(3.02, 0.02, 0.82), Vector3(0, 0.72, -2.1), _trim)
	for x in [-1.2, 1.2]:
		MeshKit.box(self, Vector3(0.5, 0.72, 0.74), Vector3(x, 0.36, -2.12), _wood, Vector3.ZERO, true)
		for i in 3:
			var y := 0.13 + i * 0.22
			MeshKit.box(self, Vector3(0.46, 0.19, 0.02), Vector3(x, y, -1.745), _trim)
			MeshKit.box(self, Vector3(0.12, 0.02, 0.025), Vector3(x, y + 0.04, -1.725), _metal)
	MeshKit.box(self, Vector3(1.9, 0.5, 0.02), Vector3(0, 0.47, -2.45), _wood)
	# trash bin with crumpled paper
	var bin := MeshKit.mat(Color(0.2, 0.22, 0.24), 0.6, 0.3)
	MeshKit.cyl(self, 0.14, 0.12, 0.32, Vector3(0.7, 0.16, -2.2), bin)
	for p in [Vector3(0.68, 0.33, -2.18), Vector3(0.74, 0.34, -2.24), Vector3(0.66, 0.36, -2.25)]:
		MeshKit.sphere(self, 0.045, p, _paper, Vector3(1, 0.8, 1.1))


func _build_crt(parent: Node3D, body: Vector3, screen: Vector2) -> MeshInstance3D:
	MeshKit.cyl(parent, 0.11, 0.13, 0.03, Vector3(0, 0.015, 0), _beige_plastic)
	MeshKit.box(parent, Vector3(0.12, 0.05, 0.12), Vector3(0, 0.05, 0), _beige_plastic)
	var y := 0.075 + body.y * 0.5
	MeshKit.box(parent, body, Vector3(0, y, 0.05), _beige_plastic)
	MeshKit.box(parent, Vector3(body.x * 0.78, body.y * 0.8, body.z * 0.85), Vector3(0, y - 0.01, 0.05 - body.z * 0.8), _beige_plastic)
	# dark bezel recess around the glass
	MeshKit.box(parent, Vector3(screen.x + 0.03, screen.y + 0.03, 0.01), Vector3(0, y + 0.015, 0.05 + body.z * 0.5), _black_plastic)
	var glass := MeshKit.quad(parent, screen, Vector3(0, y + 0.015, 0.05 + body.z * 0.5 + 0.006), MeshKit.mat(Color.BLACK))
	MeshKit.box(parent, Vector3(0.012, 0.012, 0.004), Vector3(body.x * 0.4, y - body.y * 0.42, 0.05 + body.z * 0.5 + 0.002), MeshKit.glow(Color(0.2, 1.0, 0.3), 3.0))
	return glass


func _build_monitors() -> void:
	# main camera monitor
	var main := Node3D.new()
	main.position = Vector3(0, 0.77, -2.15)
	add_child(main)
	monitor_screen = _build_crt(main, Vector3(0.58, 0.47, 0.32), Vector2(0.47, 0.355))
	MeshKit.label(main, "VIGIL-9", Vector3(0, 0.1, 0.212), 28, Color(0.3, 0.28, 0.25), Vector3.ZERO, 0.001)
	var screen_world := monitor_screen.global_position
	monitor_focus = Transform3D(Basis(), screen_world + Vector3(0, 0, 0.36))
	monitor = Interactable.create(self, "Watch the cameras", Vector3(0.6, 0.5, 0.36), Vector3(0, 1.08, -2.08))
	# sticky notes on the bezel
	var note := MeshKit.mat(Color(0.95, 0.85, 0.3), 0.9)
	MeshKit.box(main, Vector3(0.07, 0.07, 0.002), Vector3(0.24, 0.48, 0.213), note, Vector3(0, 0, 6))
	MeshKit.label(main, "CAM 2 =\nL. HALL", Vector3(0.24, 0.48, 0.2145), 16, Color(0.15, 0.1, 0.4), Vector3(0, 0, 6), 0.001)
	MeshKit.box(main, Vector3(0.07, 0.07, 0.002), Vector3(-0.25, 0.08, 0.213), MeshKit.mat(Color(0.95, 0.5, 0.6), 0.9), Vector3(0, 0, -4))
	MeshKit.label(main, "don't let\nher sing", Vector3(-0.25, 0.08, 0.2145), 15, Color(0.3, 0.05, 0.1), Vector3(0, 0, -4), 0.001)

	# left: status terminal
	var left := Node3D.new()
	left.position = Vector3(-0.66, 0.77, -2.12)
	left.rotation_degrees = Vector3(0, 22, 0)
	add_child(left)
	var term := _build_crt(left, Vector3(0.44, 0.36, 0.28), Vector2(0.35, 0.26))
	term.material_override = MeshKit.glow(Color(0.02, 0.07, 0.04), 1.0)
	terminal_label = MeshKit.label(left, "", term.position + Vector3(0, 0, 0.002), 24, Color(0.4, 1.0, 0.55), Vector3.ZERO, 0.00055)
	terminal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	set_terminal(true, 100)

	# right: a camera that's lost signal
	var right := Node3D.new()
	right.position = Vector3(0.66, 0.77, -2.12)
	right.rotation_degrees = Vector3(0, -22, 0)
	add_child(right)
	var noisy := _build_crt(right, Vector3(0.44, 0.36, 0.28), Vector2(0.35, 0.26))
	var sm := ShaderMaterial.new()
	sm.shader = load("res://shaders/crt_noise.gdshader")
	noisy.material_override = sm
	MeshKit.label(right, "NO SIGNAL", noisy.position + Vector3(0, 0, 0.003), 40, Color(1, 1, 1, 0.8), Vector3.ZERO, 0.0007)

	# a soft glow the screens throw onto the desk and the guard
	MeshKit.light_omni(self, Vector3(0, 1.1, -1.6), Color(0.55, 0.75, 0.85), 0.35, 2.2)


func set_terminal(door_open: bool, power: int) -> void:
	if terminal_label == null:
		return
	terminal_label.text = "VIGIL SECURITY v2.3\n----------------\nPOWER ....... %d%%\nL. DOOR ..... %s\nVENTS ....... OK\nCAMS ........ 8/8\n> _" % [power, "OPEN" if door_open else "SEALED"]


func set_monitor_texture(tex: Texture2D) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.25, 1.3, 1.25)
	monitor_screen.material_override = m


func _build_desk_props() -> void:
	var top := 0.77
	# keyboard
	MeshKit.box(self, Vector3(0.46, 0.03, 0.16), Vector3(0, top + 0.015, -1.86), _beige_plastic, Vector3(4, 0, 0))
	var keycap := MeshKit.mat(Color(0.8, 0.78, 0.7), 0.6)
	for row in 4:
		for col in 13:
			MeshKit.box(self, Vector3(0.027, 0.012, 0.027), Vector3(-0.198 + col * 0.033, top + 0.036 + row * 0.0023, -1.81 - row * 0.033), keycap, Vector3(4, 0, 0))
	MeshKit.box(self, Vector3(0.2, 0.012, 0.027), Vector3(0, top + 0.033, -1.778), keycap, Vector3(4, 0, 0))
	# mouse on a pad
	MeshKit.box(self, Vector3(0.24, 0.004, 0.2), Vector3(0.36, top + 0.002, -1.86), MeshKit.mat(Color(0.1, 0.12, 0.25), 0.9))
	MeshKit.sphere(self, 0.035, Vector3(0.36, top + 0.018, -1.86), _beige_plastic, Vector3(0.9, 0.5, 1.4))

	# coffee mug with steam
	var mug := MeshKit.mat(Color(0.55, 0.1, 0.1), 0.35)
	var mug_pos := Vector3(0.62, top, -1.95)
	MeshKit.cyl(self, 0.042, 0.04, 0.1, mug_pos + Vector3(0, 0.05, 0), mug)
	MeshKit.cyl(self, 0.038, 0.038, 0.004, mug_pos + Vector3(0, 0.088, 0), MeshKit.mat(Color(0.18, 0.09, 0.04), 0.1))
	MeshKit.torus(self, 0.018, 0.03, mug_pos + Vector3(0.045, 0.05, 0), mug, Vector3(90, 0, 0))
	MeshKit.label(self, "#1 GUARD", mug_pos + Vector3(0, 0.05, 0.043), 14, Color(0.95, 0.9, 0.8), Vector3.ZERO, 0.001)
	_add_steam(mug_pos + Vector3(0, 0.1, 0))

	# old desk phone
	var phone_pos := Vector3(-0.58, top, -1.98)
	var phone_mat := MeshKit.mat(Color(0.45, 0.07, 0.07), 0.35)
	MeshKit.box(self, Vector3(0.2, 0.06, 0.17), phone_pos + Vector3(0, 0.03, 0), phone_mat, Vector3(-6, 15, 0))
	MeshKit.box(self, Vector3(0.09, 0.005, 0.07), phone_pos + Vector3(0.02, 0.065, 0.03), MeshKit.mat(Color(0.85, 0.82, 0.75)), Vector3(-6, 15, 0))
	handset = Node3D.new()
	handset.position = phone_pos + Vector3(0, 0.085, -0.03)
	handset.rotation_degrees = Vector3(0, 15, 0)
	add_child(handset)
	MeshKit.capsule(handset, 0.022, 0.2, Vector3.ZERO, phone_mat, Vector3(0, 0, 90))
	MeshKit.sphere(handset, 0.035, Vector3(-0.09, -0.01, 0), phone_mat, Vector3(1, 0.7, 1))
	MeshKit.sphere(handset, 0.035, Vector3(0.09, -0.01, 0), phone_mat, Vector3(1, 0.7, 1))
	phone = Interactable.create(self, "Answer the phone", Vector3(0.26, 0.15, 0.22), phone_pos + Vector3(0, 0.07, 0))
	phone.enabled = false

	# desk lamp (warm, the cosiest thing in the room)
	var lamp_root := Node3D.new()
	lamp_root.position = Vector3(-1.08, top, -2.2)
	lamp_root.rotation_degrees = Vector3(0, 35, 0)
	add_child(lamp_root)
	var lamp_mat := MeshKit.mat(Color(0.08, 0.25, 0.16), 0.35, 0.4)
	MeshKit.cyl(lamp_root, 0.08, 0.1, 0.03, Vector3(0, 0.015, 0), lamp_mat)
	MeshKit.box(lamp_root, Vector3(0.022, 0.4, 0.022), Vector3(0, 0.2, 0.05), _metal, Vector3(-15, 0, 0))
	MeshKit.box(lamp_root, Vector3(0.022, 0.33, 0.022), Vector3(0, 0.43, 0.22), _metal, Vector3(65, 0, 0))
	MeshKit.cyl(lamp_root, 0.035, 0.11, 0.14, Vector3(0, 0.44, 0.38), lamp_mat, Vector3(35, 0, 0))
	lamp_bulb = MeshKit.sphere(lamp_root, 0.03, Vector3(0, 0.4, 0.41), MeshKit.glow(Color(1.0, 0.8, 0.5), 6.0))
	lamp = Interactable.create(self, "Switch the lamp off", Vector3(0.3, 0.6, 0.4), Vector3(-1.0, top + 0.3, -2.05))

	# radio
	var radio := MeshKit.mat(Color(0.35, 0.2, 0.12), 0.5)
	MeshKit.box(self, Vector3(0.32, 0.16, 0.12), Vector3(1.12, top + 0.08, -2.3), radio)
	MeshKit.box(self, Vector3(0.12, 0.11, 0.005), Vector3(1.04, top + 0.08, -2.237), MeshKit.mat(Color(0.12, 0.1, 0.08), 0.9))
	MeshKit.box(self, Vector3(0.13, 0.05, 0.005), Vector3(1.2, top + 0.11, -2.237), MeshKit.glow(Color(1.0, 0.6, 0.2), 1.2))
	MeshKit.label(self, "98.3 FM", Vector3(1.2, top + 0.11, -2.233), 24, Color(0.3, 0.12, 0.02), Vector3.ZERO, 0.001)
	MeshKit.cyl(self, 0.004, 0.004, 0.35, Vector3(1.24, top + 0.32, -2.32), _metal, Vector3(0, 0, -20))

	# desk fan, slowly turning
	var fan := Node3D.new()
	fan.position = Vector3(1.38, top, -1.98)
	fan.rotation_degrees = Vector3(0, -35, 0)
	add_child(fan)
	var fan_mat := MeshKit.mat(Color(0.75, 0.78, 0.8), 0.4, 0.5)
	MeshKit.cyl(fan, 0.08, 0.1, 0.03, Vector3(0, 0.015, 0), fan_mat)
	MeshKit.cyl(fan, 0.012, 0.012, 0.2, Vector3(0, 0.12, 0), fan_mat)
	MeshKit.sphere(fan, 0.045, Vector3(0, 0.24, -0.04), fan_mat, Vector3(1, 1, 1.3))
	MeshKit.torus(fan, 0.12, 0.13, Vector3(0, 0.24, 0.02), fan_mat, Vector3(90, 0, 0))
	fan_blades = Node3D.new()
	fan_blades.position = Vector3(0, 0.24, 0.02)
	fan.add_child(fan_blades)
	for i in 4:
		MeshKit.box(fan_blades, Vector3(0.05, 0.11, 0.004), Vector3(0, 0.06, 0).rotated(Vector3.BACK, i * TAU / 4.0), MeshKit.mat(Color(0.6, 0.65, 0.7), 0.4), Vector3(0, 12, rad_to_deg(i * TAU / 4.0)))

	# notebook, pen, soda can, flashlight
	MeshKit.box(self, Vector3(0.2, 0.012, 0.27), Vector3(0.95, top + 0.006, -1.88), _paper, Vector3(0, 12, 0))
	MeshKit.box(self, Vector3(0.205, 0.004, 0.275), Vector3(0.95, top + 0.001, -1.88), MeshKit.mat(Color(0.5, 0.1, 0.1)), Vector3(0, 12, 0))
	MeshKit.label(self, "night log\n12:00 - all quiet\n12:40 - heard humming?\n1:15 - ", Vector3(0.95, top + 0.0125, -1.88), 14, Color(0.15, 0.15, 0.4), Vector3(-90, 12, 0), 0.001)
	MeshKit.cyl(self, 0.004, 0.004, 0.14, Vector3(1.05, top + 0.016, -1.86), MeshKit.mat(Color(0.1, 0.2, 0.6)), Vector3(0, 30, 90))
	MeshKit.cyl(self, 0.033, 0.033, 0.12, Vector3(-0.85, top + 0.06, -1.86), MeshKit.mat(Color(0.1, 0.5, 0.2), 0.3, 0.6))
	MeshKit.cyl(self, 0.022, 0.025, 0.2, Vector3(0.82, top + 0.025, -2.32), _black_plastic, Vector3(0, 70, 90))


func _add_steam(pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = 14
	p.lifetime = 2.6
	p.preprocess = 2.0
	p.direction = Vector3.UP
	p.spread = 12.0
	p.gravity = Vector3(0.01, 0.04, 0)
	p.initial_velocity_min = 0.03
	p.initial_velocity_max = 0.06
	p.scale_amount_min = 0.6
	p.scale_amount_max = 1.4
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = curve
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 0.0))
	ramp.set_color(1, Color(1, 1, 1, 0.0))
	ramp.add_point(0.25, Color(1, 1, 1, 0.12))
	p.color_ramp = ramp
	var q := QuadMesh.new()
	q.size = Vector2(0.05, 0.05)
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	m.vertex_color_use_as_albedo = true
	m.albedo_texture = _soft_dot()
	q.material = m
	p.mesh = q
	add_child(p)


func _soft_dot() -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	t.width = 32
	t.height = 32
	return t


func _build_chair() -> void:
	var root := Node3D.new()
	root.position = Vector3(0, 0, -0.98)
	add_child(root)
	var fabric := MeshKit.mat(Color(0.12, 0.13, 0.16), 0.95)
	for i in 5:
		var a := i * TAU / 5.0
		var dir := Vector3(sin(a), 0, cos(a))
		MeshKit.box(root, Vector3(0.04, 0.03, 0.3), dir * 0.15 + Vector3(0, 0.07, 0), _black_plastic, Vector3(0, rad_to_deg(a), 0))
		MeshKit.sphere(root, 0.025, dir * 0.3 + Vector3(0, 0.025, 0), _black_plastic)
	MeshKit.cyl(root, 0.025, 0.03, 0.35, Vector3(0, 0.25, 0), _metal)
	MeshKit.box(root, Vector3(0.5, 0.08, 0.48), Vector3(0, 0.47, 0), fabric)
	MeshKit.box(root, Vector3(0.46, 0.55, 0.07), Vector3(0, 0.85, 0.26), fabric, Vector3(-8, 0, 0))
	MeshKit.box(root, Vector3(0.05, 0.05, 0.3), Vector3(-0.27, 0.66, 0.02), _black_plastic)
	MeshKit.box(root, Vector3(0.05, 0.05, 0.3), Vector3(0.27, 0.66, 0.02), _black_plastic)
	chair = Interactable.create(root, "Sit down", Vector3(0.6, 1.0, 0.6), Vector3(0, 0.5, 0))
	chair.enabled = false


# ---------------------------------------------------------------- walls

func _build_front_wall_decor() -> void:
	var z := -D * 0.5 + 0.015
	# cork board with notes
	MeshKit.box(self, Vector3(1.3, 0.85, 0.03), Vector3(-0.45, 1.65, z), _trim)
	MeshKit.box(self, Vector3(1.22, 0.77, 0.01), Vector3(-0.45, 1.65, z + 0.02), MeshKit.textured(TexGen.cork(), 4.0))
	var pin := MeshKit.mat(Color(0.8, 0.1, 0.1), 0.3)
	var zf := z + 0.027
	_note(Vector3(-0.85, 1.72, zf), Vector2(0.3, 0.36), _paper, "NIGHT SHIFT RULES\n\n1. Stay in the office\n2. Check every camera\n3. Door stays shut\n   when you hear her\n4. Don't stare\n   at the mirror", 15, -2, pin)
	_note(Vector3(-0.42, 1.82, zf), Vector2(0.17, 0.15), MeshKit.mat(Color(0.95, 0.85, 0.3)), "she sings\nbefore\nshe comes", 18, 4, pin)
	_note(Vector3(-0.38, 1.5, zf), Vector2(0.15, 0.12), MeshKit.mat(Color(0.95, 0.5, 0.65)), "VENTS!!", 26, -6, pin)
	_note(Vector3(-0.05, 1.68, zf), Vector2(0.22, 0.3), _paper, "MISSING\n\nR. HALE\nnight guard\nlast seen 3:12 AM", 17, 3, pin)
	# polaroid of the girls
	MeshKit.box(self, Vector3(0.19, 0.22, 0.004), Vector3(-0.6, 1.39, zf), _paper, Vector3(0, 0, -5))
	var play: Texture2D = load("res://assets/characters/lilly/lily-playground.png")
	MeshKit.sprite(self, play, 0.16, Vector3(-0.6, 1.405, zf + 0.004), Vector3(0, 0, -5))

	# wall clock (hands driven by the night timer)
	var clock := Node3D.new()
	clock.position = Vector3(1.0, 2.18, z + 0.02)
	add_child(clock)
	MeshKit.cyl(clock, 0.17, 0.17, 0.03, Vector3.ZERO, MeshKit.mat(Color(0.95, 0.93, 0.88), 0.5), Vector3(90, 0, 0))
	MeshKit.torus(clock, 0.165, 0.185, Vector3(0, 0, 0.005), _black_plastic, Vector3(90, 0, 0))
	for i in 12:
		var a := i * TAU / 12.0
		var tick := Vector3(sin(a), cos(a), 0) * 0.14
		MeshKit.box(clock, Vector3(0.008, 0.025 if i % 3 == 0 else 0.012, 0.003), tick + Vector3(0, 0, 0.017), _black_plastic, Vector3(0, 0, -rad_to_deg(a)))
	clock_hour = Node3D.new()
	clock_hour.position = Vector3(0, 0, 0.02)
	clock.add_child(clock_hour)
	MeshKit.box(clock_hour, Vector3(0.014, 0.085, 0.004), Vector3(0, 0.035, 0), _black_plastic)
	clock_minute = Node3D.new()
	clock_minute.position = Vector3(0, 0, 0.024)
	clock.add_child(clock_minute)
	MeshKit.box(clock_minute, Vector3(0.009, 0.125, 0.004), Vector3(0, 0.055, 0), _black_plastic)
	MeshKit.cyl(clock, 0.01, 0.01, 0.01, Vector3(0, 0, 0.028), pin, Vector3(90, 0, 0))

	# calendar
	MeshKit.box(self, Vector3(0.36, 0.5, 0.005), Vector3(2.0, 1.6, z + 0.003), _paper)
	MeshKit.box(self, Vector3(0.36, 0.12, 0.006), Vector3(2.0, 1.79, z + 0.004), MeshKit.mat(Color(0.6, 0.12, 0.12)))
	MeshKit.label(self, "NOVEMBER", Vector3(2.0, 1.79, z + 0.008), 32, Color(1, 0.95, 0.9), Vector3.ZERO, 0.001)
	MeshKit.label(self, "x  x  x  x  x  x  x\nx  x  x  x  x  x  x\n15 16 17 18 19 20 21\n22 23 24 25 26 27 28\n29 30", Vector3(2.0, 1.55, z + 0.008), 20, Color(0.15, 0.15, 0.15), Vector3.ZERO, 0.0011)

	# employee of the month, face scratched out
	MeshKit.box(self, Vector3(0.34, 0.42, 0.03), Vector3(-2.15, 1.7, z + 0.01), MeshKit.mat(Color(0.7, 0.55, 0.2), 0.4, 0.5))
	MeshKit.box(self, Vector3(0.28, 0.3, 0.005), Vector3(-2.15, 1.72, z + 0.027), MeshKit.mat(Color(0.35, 0.33, 0.32)))
	MeshKit.label(self, "X", Vector3(-2.15, 1.75, z + 0.031), 120, Color(0.15, 0.02, 0.02), Vector3.ZERO, 0.0012)
	MeshKit.label(self, "EMPLOYEE OF THE MONTH", Vector3(-2.15, 1.53, z + 0.031), 14, Color(0.1, 0.08, 0.05), Vector3.ZERO, 0.001)

	# filing cabinet with a pizza box on top
	var cab := MeshKit.mat(Color(0.33, 0.38, 0.35), 0.5, 0.4)
	MeshKit.box(self, Vector3(0.5, 1.3, 0.6), Vector3(-2.6, 0.65, -2.16), cab, Vector3.ZERO, true)
	for i in 4:
		var y := 0.17 + i * 0.315
		MeshKit.box(self, Vector3(0.44, 0.28, 0.01), Vector3(-2.6, y, -1.855), cab)
		MeshKit.box(self, Vector3(0.14, 0.025, 0.03), Vector3(-2.6, y + 0.06, -1.84), _metal)
	MeshKit.box(self, Vector3(0.42, 0.05, 0.42), Vector3(-2.6, 1.325, -2.12), MeshKit.mat(Color(0.75, 0.62, 0.42)), Vector3(0, 8, 0))
	MeshKit.label(self, "PIZZA", Vector3(-2.6, 1.351, -2.12), 48, Color(0.75, 0.12, 0.1), Vector3(-90, 8, 0), 0.0015)

	# a tall plant in the corner
	_plant(Vector3(2.62, 0, -2.15), 1.0)


func _note(pos: Vector3, size: Vector2, material: Material, text: String, font: int, tilt: float, pin: Material) -> void:
	MeshKit.box(self, Vector3(size.x, size.y, 0.003), pos, material, Vector3(0, 0, tilt))
	var l := MeshKit.label(self, text, pos + Vector3(0, 0, 0.003), font, Color(0.12, 0.1, 0.1), Vector3(0, 0, tilt), 0.001)
	l.width = size.x * 1000.0 - 16.0
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	MeshKit.sphere(self, 0.008, pos + Vector3(0, size.y * 0.42, 0.006), pin)


func _plant(pos: Vector3, s: float) -> void:
	var pot := MeshKit.mat(Color(0.6, 0.3, 0.18), 0.9)
	MeshKit.cyl(self, 0.2 * s, 0.15 * s, 0.38 * s, pos + Vector3(0, 0.19 * s, 0), pot)
	MeshKit.cyl(self, 0.19 * s, 0.19 * s, 0.01, pos + Vector3(0, 0.37 * s, 0), MeshKit.mat(Color(0.15, 0.1, 0.06)))
	var leaf := MeshKit.mat(Color(0.12, 0.32, 0.14), 0.6)
	var leaf2 := MeshKit.mat(Color(0.18, 0.42, 0.18), 0.6)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 100.0)
	for i in 11:
		var a := i * 2.4
		var lean := rng.randf_range(0.15, 0.4)
		var h := rng.randf_range(0.55, 1.1) * s
		var dir := Vector3(sin(a) * lean, 1.0, cos(a) * lean).normalized()
		var tip := pos + Vector3(0, 0.37 * s, 0) + dir * h
		MeshKit.cyl(self, 0.006, 0.008, h, pos + Vector3(0, 0.37 * s, 0) + dir * h * 0.5, leaf, Vector3(rad_to_deg(atan2(dir.z, dir.y)), 0, -rad_to_deg(atan2(dir.x, dir.y))))
		MeshKit.sphere(self, 0.13 * s, tip, leaf if i % 2 == 0 else leaf2, Vector3(1.0, 0.25, 1.6))


func _build_right_wall() -> void:
	var x := W * 0.5 - 0.015
	# the trio's poster: Lilly with her flashlight
	var night: Texture2D = load("res://assets/characters/lilly/lily-night.png")
	MeshKit.box(self, Vector3(0.025, 0.92, 0.82), Vector3(x - 0.005, 1.62, -1.25), _black_plastic)
	MeshKit.sprite(self, night, 0.74, Vector3(x - 0.02, 1.62, -1.25), Vector3(0, -90, 0))
	MeshKit.label(self, "THE SWEET TRIO  ·  LIVE EVERY NIGHT", Vector3(x - 0.02, 1.09, -1.25), 30, Color(0.95, 0.75, 0.3), Vector3(0, -90, 0), 0.0012)

	# the mirror. Diana's.
	mirror = Node3D.new()
	mirror.position = Vector3(x - 0.02, 1.55, 0.55)
	mirror.rotation_degrees = Vector3(0, -90, 0)
	add_child(mirror)
	MeshKit.box(mirror, Vector3(0.62, 0.92, 0.04), Vector3.ZERO, MeshKit.mat(Color(0.25, 0.15, 0.08), 0.5))
	MeshKit.box(mirror, Vector3(0.54, 0.84, 0.01), Vector3(0, 0, 0.022), MeshKit.mat(Color(0.32, 0.36, 0.4), 0.12, 0.55))
	MeshKit.box(mirror, Vector3(0.002, 0.3, 0.002), Vector3(0.12, 0.2, 0.028), MeshKit.mat(Color(0.8, 0.8, 0.8), 0.2), Vector3(0, 0, 30))

	# right vent (Mariam's way in)
	_vent(Vector3(x, 0.32, 1.45), Vector3(0, -90, 0), Vector2(0.62, 0.4))

	# water cooler
	MeshKit.box(self, Vector3(0.32, 0.95, 0.32), Vector3(2.72, 0.475, -0.2), MeshKit.mat(Color(0.88, 0.88, 0.86), 0.5), Vector3.ZERO, true)
	var water := MeshKit.mat(Color(0.4, 0.6, 0.85, 0.55), 0.1)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	MeshKit.cyl(self, 0.13, 0.13, 0.4, Vector3(2.72, 1.15, -0.2), water)
	MeshKit.box(self, Vector3(0.04, 0.03, 0.03), Vector3(2.6, 0.75, -0.2), MeshKit.mat(Color(0.2, 0.4, 0.9)))
	MeshKit.box(self, Vector3(0.04, 0.03, 0.03), Vector3(2.6, 0.75, -0.12), MeshKit.mat(Color(0.9, 0.2, 0.2)))

	# mini fridge + microwave
	MeshKit.box(self, Vector3(0.55, 0.85, 0.55), Vector3(2.68, 0.425, 2.12), MeshKit.mat(Color(0.82, 0.82, 0.8), 0.35), Vector3.ZERO, true)
	MeshKit.box(self, Vector3(0.02, 0.3, 0.03), Vector3(2.39, 0.62, 2.3), _metal)
	MeshKit.box(self, Vector3(0.5, 0.28, 0.4), Vector3(2.7, 0.99, 2.12), _black_plastic)
	MeshKit.box(self, Vector3(0.005, 0.2, 0.26), Vector3(2.448, 0.99, 2.06), MeshKit.mat(Color(0.05, 0.06, 0.06), 0.1, 0.5))
	microwave_label = MeshKit.label(self, "12:00", Vector3(2.446, 1.04, 2.27), 32, Color(0.3, 1.0, 0.5), Vector3(0, -90, 0), 0.0012)
	# a "cosy" sign someone left
	MeshKit.label(self, "HOME SWEET HOME", Vector3(x - 0.01, 2.25, 0.55), 40, Color(0.9, 0.8, 0.6), Vector3(0, -90, 0), 0.0015)


func _vent(pos: Vector3, rot: Vector3, size: Vector2) -> void:
	var v := Node3D.new()
	v.position = pos
	v.rotation_degrees = rot
	add_child(v)
	MeshKit.box(v, Vector3(size.x, size.y, 0.03), Vector3.ZERO, MeshKit.mat(Color(0.5, 0.52, 0.52), 0.5, 0.5))
	MeshKit.box(v, Vector3(size.x - 0.06, size.y - 0.06, 0.01), Vector3(0, 0, 0.012), MeshKit.mat(Color(0.01, 0.01, 0.01)))
	var slats := int(size.y / 0.05)
	for i in slats:
		var y := -size.y * 0.5 + 0.045 + i * 0.05
		if y > size.y * 0.5 - 0.04:
			break
		MeshKit.box(v, Vector3(size.x - 0.06, 0.012, 0.02), Vector3(0, y, 0.02), MeshKit.mat(Color(0.55, 0.57, 0.57), 0.5, 0.5), Vector3(-30, 0, 0))
	for sx in [-1, 1]:
		for sy in [-1, 1]:
			MeshKit.sphere(v, 0.008, Vector3(sx * (size.x * 0.5 - 0.02), sy * (size.y * 0.5 - 0.02), 0.018), _metal)


func _build_back_wall() -> void:
	var z := D * 0.5
	# lockers
	var locker := MeshKit.mat(Color(0.22, 0.3, 0.4), 0.5, 0.5)
	var names := ["R. HALE", "", "YOU"]
	for i in 3:
		var lx := -2.65 + i * 0.46
		MeshKit.box(self, Vector3(0.44, 1.85, 0.45), Vector3(lx, 0.925, z - 0.23), locker, Vector3.ZERO, true)
		MeshKit.box(self, Vector3(0.4, 1.78, 0.01), Vector3(lx, 0.94, z - 0.46), locker)
		for s in 4:
			MeshKit.box(self, Vector3(0.22, 0.012, 0.005), Vector3(lx, 1.62 + s * 0.035, z - 0.468), _black_plastic)
		MeshKit.box(self, Vector3(0.03, 0.12, 0.03), Vector3(lx + 0.14, 1.0, z - 0.475), _metal)
		if names[i] != "":
			MeshKit.box(self, Vector3(0.14, 0.05, 0.003), Vector3(lx, 1.45, z - 0.467), _paper)
			MeshKit.label(self, names[i], Vector3(lx, 1.45, z - 0.4695), 22, Color(0.1, 0.1, 0.1), Vector3(0, 180, 0), 0.001)
	# a jacket hanging on the coat hook by the door
	var rack := Vector3(-2.75, 0, 0.9)
	MeshKit.cyl(self, 0.02, 0.02, 1.75, rack + Vector3(0, 0.875, 0), _wood)
	MeshKit.cyl(self, 0.2, 0.22, 0.03, rack + Vector3(0, 0.015, 0), _wood)
	MeshKit.box(self, Vector3(0.32, 0.6, 0.12), rack + Vector3(0, 1.28, 0.08), MeshKit.mat(Color(0.12, 0.15, 0.26), 0.95), Vector3(0, -80, 0))
	MeshKit.label(self, "SECURITY", rack + Vector3(0.065, 1.42, 0.08), 28, Color(0.95, 0.8, 0.2), Vector3(0, 100, 0), 0.0012)
	MeshKit.cyl(self, 0.11, 0.12, 0.08, rack + Vector3(0, 1.8, 0), MeshKit.mat(Color(0.08, 0.09, 0.14), 0.9))

	# radiator heater with a warm glow
	var heater := MeshKit.mat(Color(0.85, 0.82, 0.74), 0.5, 0.2)
	for i in 7:
		MeshKit.box(self, Vector3(0.05, 0.55, 0.16), Vector3(-0.85 + i * 0.07, 0.38, z - 0.15), heater)
	MeshKit.box(self, Vector3(0.5, 0.04, 0.12), Vector3(-0.64, 0.08, z - 0.15), heater)
	MeshKit.box(self, Vector3(0.03, 0.03, 0.01), Vector3(-0.38, 0.6, z - 0.23), MeshKit.glow(Color(1, 0.2, 0.05), 4.0))
	MeshKit.light_omni(self, Vector3(-0.62, 0.5, z - 0.5), Color(1.0, 0.5, 0.2), 0.45, 2.4)

	# couch with blanket and pillow
	var fabric := MeshKit.mat(Color(0.45, 0.25, 0.17), 0.95)
	var fabric_light := MeshKit.mat(Color(0.52, 0.31, 0.21), 0.95)
	var cx := 1.05
	MeshKit.box(self, Vector3(1.8, 0.4, 0.78), Vector3(cx, 0.22, z - 0.42), fabric, Vector3.ZERO, true)
	MeshKit.box(self, Vector3(0.84, 0.13, 0.62), Vector3(cx - 0.43, 0.48, z - 0.47), fabric_light)
	MeshKit.box(self, Vector3(0.84, 0.13, 0.62), Vector3(cx + 0.43, 0.48, z - 0.47), fabric_light)
	MeshKit.box(self, Vector3(1.8, 0.52, 0.2), Vector3(cx, 0.68, z - 0.12), fabric, Vector3(-6, 0, 0))
	MeshKit.box(self, Vector3(0.16, 0.6, 0.78), Vector3(cx - 0.92, 0.32, z - 0.42), fabric)
	MeshKit.box(self, Vector3(0.16, 0.6, 0.78), Vector3(cx + 0.92, 0.32, z - 0.42), fabric)
	MeshKit.box(self, Vector3(0.4, 0.32, 0.12), Vector3(cx - 0.6, 0.68, z - 0.3), MeshKit.mat(Color(0.85, 0.65, 0.2), 0.95), Vector3(-15, 18, 10))
	var plaid := MeshKit.textured(TexGen.plaid(), 3.0)
	MeshKit.box(self, Vector3(0.7, 0.03, 0.66), Vector3(cx + 0.45, 0.56, z - 0.45), plaid, Vector3(0, 0, 4))
	MeshKit.box(self, Vector3(0.03, 0.42, 0.66), Vector3(cx + 0.81, 0.38, z - 0.45), plaid)
	# back vent, up high
	_vent(Vector3(-0.1, 2.35, z - 0.015), Vector3(0, 180, 0), Vector2(0.55, 0.3))

	# rug in the middle of the room
	var rug_mat := MeshKit.picture(TexGen.rug())
	MeshKit.quad(self, Vector2(2.6, 1.85), Vector3(0.2, 0.004, 0.75), rug_mat, Vector3(-90, 0, 0))
	# a small side table with a cassette player by the couch
	MeshKit.box(self, Vector3(0.4, 0.5, 0.4), Vector3(-0.15, 0.25, z - 0.5), _wood, Vector3.ZERO, true)
	MeshKit.box(self, Vector3(0.22, 0.07, 0.13), Vector3(-0.15, 0.535, z - 0.5), _black_plastic, Vector3(0, 20, 0))
	_plant(Vector3(-0.15, 0.5, z - 0.5), 0.35)
	_build_cosy_lights()


func _build_cosy_lights() -> void:
	# floor lamp by the couch
	var base := Vector3(2.25, 0, 1.75)
	var brass := MeshKit.mat(Color(0.55, 0.42, 0.2), 0.35, 0.8)
	MeshKit.cyl(self, 0.14, 0.17, 0.03, base + Vector3(0, 0.015, 0), brass)
	MeshKit.cyl(self, 0.014, 0.014, 1.45, base + Vector3(0, 0.75, 0), brass)
	var shade := MeshKit.mat(Color(0.95, 0.75, 0.5), 0.9)
	shade.emission_enabled = true
	shade.emission = Color(1.0, 0.6, 0.3)
	shade.emission_energy_multiplier = 0.9
	shade.cull_mode = BaseMaterial3D.CULL_DISABLED
	MeshKit.cyl(self, 0.16, 0.24, 0.3, base + Vector3(0, 1.55, 0), shade)
	MeshKit.light_omni(self, base + Vector3(0, 1.45, 0), Color(1.0, 0.62, 0.32), 1.1, 4.5, true)
	# string lights sagging along the back wall
	var colors := [Color(1, 0.55, 0.2), Color(1, 0.8, 0.4), Color(1, 0.35, 0.3), Color(0.9, 0.7, 1.0)]
	var z := D * 0.5 - 0.06
	for i in 25:
		var t := i / 24.0
		var x := lerpf(-2.85, 2.85, t)
		var sag := absf(sin(t * PI * 4.0)) * 0.16
		MeshKit.sphere(self, 0.016, Vector3(x, 2.6 - sag, z), MeshKit.glow(colors[i % 4], 4.0))
	for x in [-1.8, 0.0, 1.8]:
		MeshKit.light_omni(self, Vector3(x, 2.4, z - 0.4), Color(1.0, 0.6, 0.35), 0.28, 2.6)


# ---------------------------------------------------------- door + lights

func _build_door_controls() -> void:
	var x := -W * 0.5 + 0.02
	var panel_z := -1.55
	MeshKit.box(self, Vector3(0.04, 0.34, 0.22), Vector3(x, 1.3, panel_z), MeshKit.mat(Color(0.3, 0.3, 0.32), 0.5, 0.5))
	MeshKit.cyl(self, 0.05, 0.05, 0.035, Vector3(x + 0.03, 1.26, panel_z), MeshKit.glow(Color(0.8, 0.05, 0.05), 1.5), Vector3(0, 0, 90))
	door_light = MeshKit.box(self, Vector3(0.012, 0.03, 0.03), Vector3(x + 0.025, 1.41, panel_z), MeshKit.glow(Color(0.1, 1.0, 0.2), 3.0))
	MeshKit.label(self, "DOOR", Vector3(x + 0.025, 1.505, panel_z), 32, Color(0.9, 0.9, 0.85), Vector3(0, 90, 0), 0.001)
	door_button = Interactable.create(self, "Close the door", Vector3(0.15, 0.4, 0.3), Vector3(x + 0.05, 1.3, panel_z))

	# heavy steel shutter that drops into the doorway
	shutter = Node3D.new()
	shutter.position = Vector3(-W * 0.5 - 0.1, DOOR_H * 0.5 + DOOR_H, (DOOR_Z0 + DOOR_Z1) * 0.5)
	add_child(shutter)
	var steel := MeshKit.mat(Color(0.35, 0.36, 0.38), 0.4, 0.7)
	MeshKit.box(shutter, Vector3(0.08, DOOR_H, DOOR_Z1 - DOOR_Z0), Vector3.ZERO, steel, Vector3.ZERO, true)
	for i in 12:
		MeshKit.box(shutter, Vector3(0.1, 0.03, DOOR_Z1 - DOOR_Z0), Vector3(0, -DOOR_H * 0.5 + 0.09 + i * 0.18, 0), MeshKit.mat(Color(0.28, 0.29, 0.3), 0.5, 0.7))
	MeshKit.box(shutter, Vector3(0.1, 0.12, DOOR_Z1 - DOOR_Z0), Vector3(0, -DOOR_H * 0.5 + 0.06, 0), MeshKit.mat(Color(0.7, 0.55, 0.1), 0.6))


func set_shutter(down: bool) -> void:
	shutter_down = down
	var target_y := DOOR_H * 0.5 if down else DOOR_H * 1.5
	var tw := create_tween().set_trans(Tween.TRANS_QUAD)
	tw.set_ease(Tween.EASE_IN if down else Tween.EASE_OUT)
	tw.tween_property(shutter, "position:y", target_y, 0.45 if down else 0.8)
	(door_light.material_override as StandardMaterial3D).emission = Color(1.0, 0.1, 0.05) if down else Color(0.1, 1.0, 0.2)
	(door_light.material_override as StandardMaterial3D).albedo_color = Color(1.0, 0.1, 0.05) if down else Color(0.1, 1.0, 0.2)
	door_button.prompt = "Open the door" if down else "Close the door"


func _build_lights() -> void:
	# main fluorescent fixture over the desk
	MeshKit.box(self, Vector3(1.25, 0.07, 0.34), Vector3(0, H - 0.035, -1.3), _metal)
	ceiling_tube = MeshKit.box(self, Vector3(1.18, 0.02, 0.28), Vector3(0, H - 0.08, -1.3), MeshKit.glow(Color(0.85, 0.92, 1.0), 1.6))
	ceiling_light = MeshKit.light_omni(self, Vector3(0, H - 0.35, -1.3), Color(0.78, 0.86, 1.0), 0.55, 6.5, true)
	# second fixture: mostly dead, sputters now and then
	MeshKit.box(self, Vector3(1.25, 0.07, 0.34), Vector3(0, H - 0.035, 1.3), _metal)
	back_tube = MeshKit.box(self, Vector3(1.18, 0.02, 0.28), Vector3(0, H - 0.08, 1.3), MeshKit.glow(Color(0.85, 0.92, 1.0), 0.0))
	back_light = MeshKit.light_omni(self, Vector3(0, H - 0.35, 1.3), Color(0.78, 0.86, 1.0), 0.0, 5.0)

	# desk lamp: warm spot onto the desk + a little fill
	lamp_light = SpotLight3D.new()
	lamp_light.light_color = Color(1.0, 0.72, 0.42)
	lamp_light.light_energy = 2.6
	lamp_light.spot_range = 3.2
	lamp_light.spot_angle = 55.0
	lamp_light.spot_attenuation = 1.2
	lamp_light.shadow_enabled = true
	add_child(lamp_light)
	lamp_light.global_position = lamp_bulb.global_position + Vector3(0, -0.02, 0)
	lamp_light.look_at(Vector3(-0.45, 0.77, -1.75))
	var fill := MeshKit.light_omni(self, lamp_bulb.global_position + Vector3(0, 0.1, 0.15), Color(1.0, 0.7, 0.4), 0.5, 2.5)
	fill.name = "LampFill"


func set_lamp(on: bool) -> void:
	lamp_on = on
	lamp_light.visible = on
	(get_node("LampFill") as Light3D).visible = on
	(lamp_bulb.material_override as StandardMaterial3D).emission_energy_multiplier = 6.0 if on else 0.0
	lamp.prompt = "Switch the lamp off" if on else "Switch the lamp on"


## 0 = off .. 1 = normal brightness.
func set_ceiling_level(v: float) -> void:
	ceiling_light.light_energy = 0.55 * v
	(ceiling_tube.material_override as StandardMaterial3D).emission_energy_multiplier = 1.6 * v


func set_back_level(v: float) -> void:
	back_light.light_energy = 0.45 * v
	(back_tube.material_override as StandardMaterial3D).emission_energy_multiplier = 1.6 * v


func set_clock(minutes: float) -> void:
	var hours := minutes / 60.0
	clock_hour.rotation.z = -TAU * fmod(hours, 12.0) / 12.0
	clock_minute.rotation.z = -TAU * fmod(minutes, 60.0) / 60.0


func _process(delta: float) -> void:
	if fan_blades:
		fan_blades.rotate_z(delta * 11.0)
