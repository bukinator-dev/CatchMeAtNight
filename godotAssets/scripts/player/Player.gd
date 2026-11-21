class_name Player
extends CharacterBody3D
## First-person night guard.
## Starts seated at the desk. Mouse looks, WASD stands up and walks,
## E / left click uses whatever the centre dot is on.

signal target_changed(target: Interactable)
signal seated_changed(is_seated: bool)

const WALK_SPEED := 2.4
const ACCEL := 14.0
const GRAVITY := 9.8
const SEATED_HEAD := 1.14
const STANDING_HEAD := 1.62

@export var mouse_sensitivity := 0.0022

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var ray: RayCast3D = $Head/Camera3D/Ray
@onready var hands: FPHands = $Head/Camera3D/Hands

var seated := true
var controls_enabled := false  # off until the player clicks past the intro
var focused := false           # camera flown into a monitor
var current_target: Interactable

var _yaw := 0.0
var _pitch := 0.0
var _bob_phase := 0.0
var _focus_return: Transform3D
var _transitioning := false


func _ready() -> void:
	head.position.y = SEATED_HEAD
	_yaw = rotation.y
	ray.add_exception(self)


func set_look(yaw: float, pitch := 0.0) -> void:
	_yaw = yaw
	_pitch = pitch


func get_yaw() -> float:
	return _yaw


func _set_yaw(v: float) -> void:
	_yaw = v


func sit_at(pos: Vector3, facing_yaw: float) -> void:
	if _transitioning:
		return
	_transitioning = true
	seated = true
	velocity = Vector3.ZERO
	var target_yaw := _yaw + wrapf(facing_yaw - _yaw, -PI, PI)
	var tw := create_tween().set_parallel().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(self, "global_position", pos, 0.6)
	tw.tween_property(head, "position:y", SEATED_HEAD, 0.6)
	tw.tween_method(_set_yaw, _yaw, target_yaw, 0.6)
	tw.tween_property(self, "_pitch", -0.08, 0.6)
	await tw.finished
	_transitioning = false
	seated_changed.emit(true)


func stand_up() -> void:
	if _transitioning:
		return
	_transitioning = true
	seated = false
	var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(head, "position:y", STANDING_HEAD, 0.45)
	await tw.finished
	_transitioning = false
	seated_changed.emit(false)


## Fly the camera to a fixed pose (e.g. in front of a monitor screen).
func focus_on(target: Transform3D, duration := 0.6) -> void:
	focused = true
	_set_target(null)
	_focus_return = camera.transform
	hands.lower(duration * 0.6)
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(camera, "global_transform", target, duration)
	await tw.finished


func unfocus(duration := 0.45) -> void:
	var tw := create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(camera, "transform", _focus_return, duration)
	await tw.finished
	hands.raise()
	focused = false


func _unhandled_input(event: InputEvent) -> void:
	if not controls_enabled or focused:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = event.relative
		_yaw -= rel.x * mouse_sensitivity
		_pitch = clampf(_pitch - rel.y * mouse_sensitivity, -1.35, 1.35)
		hands.add_sway(rel)
	elif event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_use_target()
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_E:
				_use_target()
			KEY_T:
				hands.check_watch()
			KEY_ESCAPE:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _use_target() -> void:
	if current_target and current_target.enabled:
		hands.reach()
		current_target.interact()


func _process(_delta: float) -> void:
	rotation.y = _yaw
	head.rotation.x = _pitch


func _physics_process(delta: float) -> void:
	if not controls_enabled or focused:
		hands.walk_amount = 0.0
		return
	var input := Vector2(
		_axis(KEY_D, KEY_RIGHT) - _axis(KEY_A, KEY_LEFT),
		_axis(KEY_S, KEY_DOWN) - _axis(KEY_W, KEY_UP))
	if seated:
		if input.length() > 0.1 and not _transitioning:
			stand_up()
	elif not _transitioning:
		var dir := (transform.basis * Vector3(input.x, 0.0, input.y)).normalized()
		var target := dir * WALK_SPEED
		velocity.x = move_toward(velocity.x, target.x, ACCEL * delta)
		velocity.z = move_toward(velocity.z, target.z, ACCEL * delta)
		velocity.y = 0.0 if is_on_floor() else velocity.y - GRAVITY * delta
		move_and_slide()
		var speed := Vector2(velocity.x, velocity.z).length() / WALK_SPEED
		hands.walk_amount = speed
		if speed > 0.05:
			_bob_phase += delta * 8.0 * speed
		head.position.y = STANDING_HEAD + absf(sin(_bob_phase)) * 0.035 * speed
	_update_target()


func _axis(a: Key, b: Key) -> float:
	return 1.0 if Input.is_physical_key_pressed(a) or Input.is_physical_key_pressed(b) else 0.0


func _update_target() -> void:
	var hit := ray.get_collider()
	var it: Interactable = hit as Interactable
	if it and not it.enabled:
		it = null
	_set_target(it)


func _set_target(it: Interactable) -> void:
	if it != current_target:
		current_target = it
		target_changed.emit(it)
