class_name TexGen
extends RefCounted
## Procedural textures so the room has surface detail without any image assets.

@warning_ignore_start("integer_division")
static func _finish(img: Image) -> ImageTexture:
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)


static func _jitter(c: Color, rng: RandomNumberGenerator, amount: float) -> Color:
	var j := rng.randf_range(-amount, amount)
	return Color(clampf(c.r + j, 0, 1), clampf(c.g + j, 0, 1), clampf(c.b + j, 0, 1))


## Old checkered linoleum: 2x2 tiles per texture, grout lines and scuffs.
static func checker_floor() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var a := Color(0.74, 0.70, 0.60)
	var b := Color(0.20, 0.26, 0.27)
	for y in s:
		for x in s:
			var tile := ((x / 64) + (y / 64)) % 2
			var c := a if tile == 0 else b
			if x % 64 == 0 or y % 64 == 0:
				c = c.darkened(0.35)
			img.set_pixel(x, y, _jitter(c, rng, 0.035))
	# scuff marks
	for i in 40:
		var cx := rng.randi_range(0, s - 1)
		var cy := rng.randi_range(0, s - 1)
		for k in rng.randi_range(3, 9):
			var px := (cx + k) % s
			img.set_pixel(px, cy, img.get_pixel(px, cy).darkened(0.25))
	return _finish(img)


## Fine noise for painted plaster, tinted by the material.
static func paint() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var v := 0.9 + rng.randf_range(-0.06, 0.06) + 0.03 * sin(float(y) * 0.4)
			img.set_pixel(x, y, Color(v, v, v))
	return _finish(img)


## Acoustic ceiling tiles with speckles and a grid.
static func ceiling_tiles() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var v := 0.78 + rng.randf_range(-0.04, 0.04)
			if rng.randf() < 0.06:
				v -= 0.25
			if x < 3 or y < 3:
				v = 0.45
			img.set_pixel(x, y, Color(v, v, v * 0.97))
	# one water stain, for character
	for y in range(70, 110):
		for x in range(60, 105):
			var d := Vector2(x - 82, y - 90).length()
			if d < 20:
				var p := img.get_pixel(x, y)
				img.set_pixel(x, y, p.lerp(Color(0.55, 0.45, 0.3), 0.35 * (1.0 - d / 20.0)))
	return _finish(img)


## Wood grain for desks, frames and shelves.
static func wood() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var s := 128
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	var base := Color(0.40, 0.25, 0.15)
	for y in s:
		var plank_shift := float((y / 32) * 17)
		for x in s:
			var grain := sin((float(x) + plank_shift) * 0.25 + sin(float(y) * 0.05) * 3.0) * 0.5 + 0.5
			var c := base.lerp(base.darkened(0.3), grain * 0.6)
			if y % 32 == 0:
				c = c.darkened(0.45)
			img.set_pixel(x, y, _jitter(c, rng, 0.02))
	return _finish(img)


## Cork board.
static func cork() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var c := Color(0.62, 0.45, 0.28)
			if rng.randf() < 0.25:
				c = c.darkened(rng.randf_range(0.1, 0.35))
			img.set_pixel(x, y, c)
	return _finish(img)


## Tartan for the couch blanket.
static func plaid() -> ImageTexture:
	var s := 64
	var img := Image.create(s, s, false, Image.FORMAT_RGB8)
	for y in s:
		for x in s:
			var c := Color(0.45, 0.09, 0.10)
			if (x / 8) % 4 == 0:
				c = c.lerp(Color(0.12, 0.22, 0.15), 0.6)
			if (y / 8) % 4 == 0:
				c = c.lerp(Color(0.12, 0.22, 0.15), 0.6)
			if x % 16 == 3 or y % 16 == 3:
				c = c.lerp(Color(0.9, 0.75, 0.3), 0.5)
			img.set_pixel(x, y, c)
	return _finish(img)


## Persian-style rug: whole picture on one quad.
static func rug() -> ImageTexture:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var w := 192
	var h := 136
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	var field := Color(0.42, 0.08, 0.09)
	var border := Color(0.12, 0.13, 0.25)
	var gold := Color(0.78, 0.58, 0.25)
	for y in h:
		for x in w:
			var edge := mini(mini(x, w - 1 - x), mini(y, h - 1 - y))
			var c := field
			if edge < 14:
				c = border
				if (x + y) % 10 < 3:
					c = gold.darkened(0.2)
			elif edge < 17:
				c = gold
			else:
				var u := float(x - w / 2) / float(w / 2)
				var v := float(y - h / 2) / float(h / 2)
				var diamond := absf(u) * 1.4 + absf(v)
				if absf(diamond - 0.55) < 0.05 or absf(diamond - 0.3) < 0.04:
					c = gold
				elif diamond < 0.18:
					c = border
			img.set_pixel(x, y, _jitter(c, rng, 0.03))
	return _finish(img)
