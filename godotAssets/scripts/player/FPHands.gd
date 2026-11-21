class_name FPHands
extends Node3D
## The guard's two hands at the bottom of the view, built from primitives.
## They breathe, sway with the mouse, bob while walking, and the right hand
## reaches out when you use something. The left wrist wears a glowing watch.

const SKIN := Color(0.58, 0.40, 0.30)
const SLEEVE := Color(0.11, 0.14, 0.24)
const CUFF := Color(0.06, 0.07, 0.11)

var left_arm: Node3D
var right_arm: Node3D
var watch_label: Label3D
var walk_amount := 0.0  # 0..1, set by the player

var _rest_left: Transform3D
var _rest_right: Transform3D
var _sway := Vector2.ZERO
var _sway_target := Vector2.ZERO
var _t := 0.0
var _walk_phase := 0.0
var _lowered := 0.0


func _ready() -> void:
	right_arm = _build_arm(1)
	left_arm = _build_arm(-1)
	right_arm.position = Vector3(0.24, -0.29, -0.42)
	right_arm.rotation_degrees = Vector3(4, 18, -24)
	left_arm.position = Vector3(-0.24, -0.29, -0.42)
	left_arm.rotation_degrees = Vector3(4, -18, 24)
	_rest_left = left_arm.transform
	_rest_right = right_arm.transform
	_build_watch()


func _build_arm(side: int) -> Node3D:
	var arm := Node3D.new()
	add_child(arm)
	var skin := MeshKit.mat(SKIN, 0.75)
	var sleeve := MeshKit.mat(SLEEVE, 0.95)
	# Jacket sleeve runs back toward the camera from the wrist.
	MeshKit.cyl(arm, 0.044, 0.052, 0.42, Vector3(0, 0, 0.26), sleeve, Vector3(90, 0, 0))
	MeshKit.cyl(arm, 0.047, 0.047, 0.035, Vector3(0, 0, 0.055), MeshKit.mat(CUFF, 0.9), Vector3(90, 0, 0))
	# Wrist and palm (palm down).
	MeshKit.cyl(arm, 0.029, 0.033, 0.07, Vector3(0, 0, 0.0), skin, Vector3(90, 0, 0))
	MeshKit.box(arm, Vector3(0.08, 0.028, 0.09), Vector3(0, 0, -0.065), skin)
	MeshKit.capsule(arm, 0.015, 0.08, Vector3(0, 0.004, -0.107), skin, Vector3(0, 0, 90))  # knuckles
	# Fingers, index on the thumb side, gently curled.
	var lengths := [0.064, 0.072, 0.068, 0.054]
	for i in 4:
		var finger := Node3D.new()
		finger.position = Vector3((-0.03 + i * 0.02) * side, -0.002, -0.11)
		finger.rotation_degrees = Vector3(-48.0 - i * 6.0, (1.5 - i) * 3.0 * side, 0)
		arm.add_child(finger)
		var length: float = lengths[i]
		MeshKit.capsule(finger, 0.0098, length, Vector3(0, 0, -length * 0.45), skin, Vector3(90, 0, 0))
	var thumb := Node3D.new()
	thumb.position = Vector3(-0.044 * side, -0.006, -0.045)
	thumb.rotation_degrees = Vector3(-30, 30 * side, 0)
	arm.add_child(thumb)
	MeshKit.capsule(thumb, 0.012, 0.06, Vector3(0, 0, -0.028), skin, Vector3(90, 0, 0))
	return arm


func _build_watch() -> void:
	var band := MeshKit.mat(Color(0.05, 0.05, 0.06), 0.6)
	MeshKit.cyl(left_arm, 0.036, 0.036, 0.022, Vector3(0, 0, 0.012), band, Vector3(90, 0, 0))
	MeshKit.box(left_arm, Vector3(0.034, 0.012, 0.03), Vector3(0, 0.034, 0.012), band)
	MeshKit.box(left_arm, Vector3(0.028, 0.002, 0.022), Vector3(0, 0.0405, 0.012), MeshKit.glow(Color(0.1, 0.35, 0.2), 0.6))
	watch_label = MeshKit.label(left_arm, "12:00", Vector3(0, 0.0418, 0.012), 48, Color(0.55, 1.0, 0.7), Vector3(-90, 0, 0), 0.00042)


func set_time_text(text: String) -> void:
	if watch_label:
		watch_label.text = text


func add_sway(mouse_delta: Vector2) -> void:
	_sway_target = (_sway_target + mouse_delta).limit_length(60.0)


func lower(duration := 0.3) -> void:
	create_tween().tween_property(self, "_lowered", 1.0, duration)


func raise(duration := 0.35) -> void:
	create_tween().tween_property(self, "_lowered", 0.0, duration)


## Right hand pushes forward, like pressing a button.
func reach() -> void:
	var out := _rest_right.translated_local(Vector3(-0.03, 0.04, -0.14))
	var tw := create_tween().set_trans(Tween.TRANS_QUAD)
	tw.tween_property(right_arm, "transform", out, 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(right_arm, "transform", _rest_right, 0.25).set_ease(Tween.EASE_IN_OUT)


## Left hand turns up to check the watch.
func check_watch() -> void:
	var look := _rest_left.translated_local(Vector3(0.06, 0.09, 0.02)).rotated_local(Vector3.FORWARD, deg_to_rad(-35)).rotated_local(Vector3.RIGHT, deg_to_rad(20))
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(left_arm, "transform", look, 0.3)
	tw.tween_interval(1.4)
	tw.tween_property(left_arm, "transform", _rest_left, 0.35)


func _process(delta: float) -> void:
	_t += delta
	_sway_target = _sway_target.lerp(Vector2.ZERO, minf(delta * 7.0, 1.0))
	_sway = _sway.lerp(_sway_target, minf(delta * 9.0, 1.0))
	if walk_amount > 0.01:
		_walk_phase += delta * 7.5
	var breathe := sin(_t * 1.7) * 0.0035
	var bob_y := absf(sin(_walk_phase)) * 0.012 * walk_amount
	var bob_x := sin(_walk_phase) * 0.008 * walk_amount
	position = Vector3(
		-_sway.x * 0.0005 + bob_x,
		_sway.y * 0.0005 + breathe - bob_y - _lowered * 0.45,
		0.0)
	rotation = Vector3(_sway.y * 0.0012, -_sway.x * 0.0012, 0.0)
	visible = _lowered < 0.99
