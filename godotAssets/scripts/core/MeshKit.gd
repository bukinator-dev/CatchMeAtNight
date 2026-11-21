class_name MeshKit
extends RefCounted
## Small helpers for building props out of primitive meshes.
## Everything in the office is assembled from these, so it can be swapped
## for real models later without touching gameplay code.

static var _mat_cache := {}


static func mat(color: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [color.to_html(), rough, metal]
	if _mat_cache.has(key):
		return _mat_cache[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	_mat_cache[key] = m
	return m


static func glow(color: Color, energy := 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m


## World-space (triplanar) texture: repeats every 1/scale metres on any box.
static func textured(tex: Texture2D, scale: float, tint := Color.WHITE, rough := 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.roughness = rough
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3.ONE * scale
	return m


## Plain UV-mapped texture (for quads: posters, rugs, papers).
static func picture(tex: Texture2D, unshaded := false, tint := Color.WHITE) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.albedo_color = tint
	m.roughness = 0.9
	if unshaded:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


static func _place(parent: Node, node: Node3D, pos: Vector3, rot_deg: Vector3) -> void:
	node.position = pos
	node.rotation_degrees = rot_deg
	parent.add_child(node)


static func _mesh(parent: Node, mesh: Mesh, pos: Vector3, material: Material, rot_deg: Vector3) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = material
	_place(parent, mi, pos, rot_deg)
	return mi


static func box(parent: Node, size: Vector3, pos: Vector3, material: Material, rot_deg := Vector3.ZERO, collide := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := _mesh(parent, mesh, pos, material, rot_deg)
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = size
		cs.shape = shape
		body.add_child(cs)
		mi.add_child(body)
	return mi


static func cyl(parent: Node, top_r: float, bottom_r: float, height: float, pos: Vector3, material: Material, rot_deg := Vector3.ZERO, segments := 20) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_r
	mesh.bottom_radius = bottom_r
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return _mesh(parent, mesh, pos, material, rot_deg)


static func sphere(parent: Node, radius: float, pos: Vector3, material: Material, scale := Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 16
	mesh.rings = 8
	var mi := _mesh(parent, mesh, pos, material, Vector3.ZERO)
	mi.scale = scale
	return mi


static func capsule(parent: Node, radius: float, height: float, pos: Vector3, material: Material, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(height, radius * 2.0)
	mesh.radial_segments = 12
	mesh.rings = 4
	return _mesh(parent, mesh, pos, material, rot_deg)


static func torus(parent: Node, inner: float, outer: float, pos: Vector3, material: Material, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 24
	mesh.ring_segments = 8
	return _mesh(parent, mesh, pos, material, rot_deg)


## A flat quad facing +Z (rotate it to face elsewhere).
static func quad(parent: Node, size: Vector2, pos: Vector3, material: Material, rot_deg := Vector3.ZERO) -> MeshInstance3D:
	var mesh := QuadMesh.new()
	mesh.size = size
	return _mesh(parent, mesh, pos, material, rot_deg)


static func label(parent: Node, text: String, pos: Vector3, font_size := 32, color := Color.WHITE, rot_deg := Vector3.ZERO, pixel_size := 0.001) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = font_size
	l.modulate = color
	l.outline_size = 0
	l.pixel_size = pixel_size
	l.double_sided = false
	_place(parent, l, pos, rot_deg)
	return l


## Picture on a wall: a Sprite3D sized to `width` metres.
static func sprite(parent: Node, tex: Texture2D, width: float, pos: Vector3, rot_deg := Vector3.ZERO, shaded := true) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = tex
	s.pixel_size = width / float(tex.get_width())
	s.shaded = shaded
	s.double_sided = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISCARD
	_place(parent, s, pos, rot_deg)
	return s


static func light_omni(parent: Node, pos: Vector3, color: Color, energy: float, light_range: float, shadows := false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.light_color = color
	l.light_energy = energy
	l.omni_range = light_range
	l.omni_attenuation = 1.4
	l.shadow_enabled = shadows
	_place(parent, l, pos, Vector3.ZERO)
	return l
