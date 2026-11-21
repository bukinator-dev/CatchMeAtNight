extends Node2D
## Character viewer for Lilly.
## 1 / 2 / 3 = idle / walk / jump    SPACE = night falls (possession)

@onready var lilly: Lilly = $Lilly
@onready var spotlight: PointLight2D = $Spotlight
@onready var darkness: CanvasModulate = $Darkness
@onready var title: Label = $UI/Title

const DAY_DARK := Color(0.55, 0.5, 0.6)
const NIGHT_DARK := Color(0.12, 0.08, 0.12)

var _shot_path := ""

func _ready() -> void:
	lilly.possession_changed.connect(_on_possession_changed)
	# Headless-friendly preview: godot --path . -- --screenshot=res://screenshots/x.png [--possessed] [--pose=walk]
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			_shot_path = arg.get_slice("=", 1)
		elif arg == "--possessed":
			lilly.set_possessed(true, 0.01)
		elif arg.begins_with("--pose="):
			lilly.set_pose(StringName(arg.get_slice("=", 1)))
	if _shot_path != "":
		await get_tree().create_timer(1.0).timeout
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_shot_path.get_base_dir()))
		get_viewport().get_texture().get_image().save_png(_shot_path)
		get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_1: lilly.set_pose(&"idle")
		KEY_2: lilly.set_pose(&"walk")
		KEY_3: lilly.set_pose(&"jump")
		KEY_SPACE: lilly.set_possessed(not lilly.possessed)

func _on_possession_changed(on: bool) -> void:
	var tw := create_tween().set_parallel()
	tw.tween_property(darkness, "color", NIGHT_DARK if on else DAY_DARK, 1.4)
	tw.tween_property(spotlight, "color", Color(1, 0.35, 0.3) if on else Color(1, 0.92, 0.75), 1.4)
	title.text = "LILLY  —  3:00 AM" if on else "LILLY  —  lead vocalist"

func _process(_delta: float) -> void:
	# Dying bulb: the spotlight stutters once she turns.
	if lilly.possessed:
		spotlight.energy = 0.15 if randf() < 0.06 else randf_range(1.1, 1.4)
	else:
		spotlight.energy = 1.3
