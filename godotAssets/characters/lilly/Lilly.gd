class_name Lilly
extends Node2D
## Lilly — lead vocalist. Cute on stage, wrong at night.
## Poses: idle / walk / jump. Call set_possessed(true) to turn her.

signal possession_changed(is_possessed: bool)

const FACE_OFFSET := {
	&"idle": Vector2.ZERO,
	&"walk": Vector2.ZERO,
	&"jump": Vector2(0, -240),
}

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var face: Node2D = $Face
@onready var eyes: Node2D = $Face/Eyes
@onready var wide_smile: Line2D = $Face/WideSmile

var possessed := false
var _possession := 0.0
var _time := 0.0
var _twitch_cooldown := 0.0

func _ready() -> void:
	sprite.material = sprite.material.duplicate() # each Lilly owns her own shader state
	_apply_possession(0.0)
	set_pose(&"idle")

func set_pose(pose: StringName) -> void:
	if not sprite.sprite_frames.has_animation(pose):
		push_warning("Lilly has no pose '%s'" % pose)
		return
	sprite.play(pose)
	face.position = FACE_OFFSET.get(pose, Vector2.ZERO)

func set_possessed(on: bool, duration := 1.4) -> void:
	if on == possessed:
		return
	possessed = on
	var tw := create_tween().set_trans(Tween.TRANS_SINE)
	tw.tween_method(_apply_possession, _possession, 1.0 if on else 0.0, duration)
	possession_changed.emit(on)

func _apply_possession(v: float) -> void:
	_possession = v
	(sprite.material as ShaderMaterial).set_shader_parameter(&"possession", v)
	eyes.modulate.a = v
	wide_smile.modulate.a = clampf(v * 1.3 - 0.3, 0.0, 1.0)

func _process(delta: float) -> void:
	_time += delta
	# Breathing. When possessed she stops breathing.
	var breath := sin(_time * 2.2) * 0.012 * (1.0 - _possession)
	sprite.scale = Vector2(1.0 - breath * 0.5, 1.0 + breath)

	# Eyes pulse.
	for eye: Node2D in eyes.get_children():
		eye.scale = Vector2.ONE * (1.0 + 0.15 * sin(_time * 6.0))

	# Random head twitches while possessed.
	_twitch_cooldown -= delta
	if possessed and _twitch_cooldown <= 0.0 and randf() < 0.02:
		_twitch_cooldown = randf_range(0.6, 2.5)
		var angle := deg_to_rad(randf_range(-6.0, 6.0))
		var tw := create_tween()
		tw.tween_property(self, "rotation", angle, 0.04)
		tw.tween_interval(randf_range(0.1, 0.5))
		tw.tween_property(self, "rotation", 0.0, 0.08)
