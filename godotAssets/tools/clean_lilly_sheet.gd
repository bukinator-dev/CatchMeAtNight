# One-off: strip the guide marks (ground dashes + speed lines) from the pose sheet.
# Run: godot --headless --path . --script res://tools/clean_lilly_sheet.gd
extends SceneTree

func _init() -> void:
	var img := Image.load_from_file(ProjectSettings.globalize_path("res://assets/characters/lilly/lily-poses.png"))
	img.convert(Image.FORMAT_RGBA8)
	var clear := Color(0, 0, 0, 0)
	img.fill_rect(Rect2i(490, 1295, 125, 100), clear)          # speed lines between idle & walk
	img.fill_rect(Rect2i(0, 1483, img.get_width(), 80), clear)  # dashed ground + jump shadow
	img.fill_rect(Rect2i(1170, 1460, 300, 23), clear)           # top of the jump shadow ellipse
	img.save_png(ProjectSettings.globalize_path("res://assets/characters/lilly/lily-poses-clean.png"))
	print("cleaned sheet saved")
	quit()
