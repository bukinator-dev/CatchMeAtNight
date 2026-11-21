class_name Synth
extends AudioStreamPlayer
## Placeholder audio generated in code until real recordings exist.
## HUM: fluorescent mains hum + room tone (always on)
## RING: old desk-phone bell
## STATIC: camera static; `level` = constant hiss, burst() = loud crackle
## SING: Lilly's music-box lullaby, volume set by `level` (distance)

enum Voice { HUM, RING, STATIC, SING }

const RATE := 22050.0
const MELODY := [0, 3, 7, 3, 5, 3, 0, -2, 0, 3, 7, 10, 8, 7, 5, 3, 5, 2, -2, 0]
const NOTE_LEN := 0.42

@export var voice := Voice.HUM
@export var active := true
@export var level := 1.0

var _playback: AudioStreamGeneratorPlayback
var _t := 0.0
var _brown := 0.0
var _burst := 0.0
var _lp := 0.0
var _phase := 0.0


func _ready() -> void:
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = RATE
	gen.buffer_length = 0.12
	stream = gen
	play()
	_playback = get_stream_playback()


func burst(seconds := 0.3) -> void:
	_burst = maxf(_burst, seconds)


func restart() -> void:
	_t = 0.0


func _silent() -> bool:
	match voice:
		Voice.RING:
			return not active
		Voice.STATIC:
			return _burst <= 0.0 and level <= 0.001
		Voice.SING:
			return not active or level <= 0.001
	return not active


func _process(_delta: float) -> void:
	if _playback == null:
		return
	var frames := _playback.get_frames_available()
	if frames <= 0:
		return
	if _silent():
		var zeros := PackedVector2Array()
		zeros.resize(frames)
		_playback.push_buffer(zeros)
		_t += frames / RATE
		_burst = maxf(_burst - frames / RATE, 0.0)
		return
	var buf := PackedVector2Array()
	buf.resize(frames)
	var dt := 1.0 / RATE
	for i in frames:
		var s := _sample()
		buf[i] = Vector2(s, s)
		_t += dt
	_playback.push_buffer(buf)


func _sample() -> float:
	match voice:
		Voice.HUM:
			_brown = clampf(_brown + randf_range(-1.0, 1.0) * 0.02, -1.0, 1.0) * 0.996
			var hum := sin(TAU * 60.0 * _t) * 0.5 + sin(TAU * 120.0 * _t) * 0.3 + sin(TAU * 180.0 * _t) * 0.12
			return (hum * 0.05 + _brown * 0.35) * level
		Voice.RING:
			var cycle := fmod(_t, 4.0)
			if cycle > 1.6:
				return 0.0
			var bell := (sin(TAU * 440.0 * _t) + sin(TAU * 480.0 * _t)) * 0.5
			var clapper := 1.0 if sin(TAU * 18.0 * _t) > 0.0 else 0.35
			return bell * clapper * 0.22 * level
		Voice.STATIC:
			var amp := level * 0.06
			if _burst > 0.0:
				amp = maxf(amp, minf(_burst * 3.0, 1.0) * 0.35)
				_burst -= 1.0 / RATE
			var n := randf_range(-1.0, 1.0)
			_lp = lerpf(_lp, n, 0.5)
			return _lp * amp
		Voice.SING:
			var idx := int(_t / NOTE_LEN)
			var note: int = MELODY[idx % MELODY.size()]
			var local := fmod(_t, NOTE_LEN) / NOTE_LEN
			var vibrato := sin(TAU * 5.5 * _t) * 0.006
			var freq := 440.0 * pow(2.0, float(note) / 12.0) * (1.0 + vibrato)
			# Slowly drifting pitch: a music box that is winding down.
			freq *= 1.0 - 0.015 * sin(_t * 0.37)
			_phase = fmod(_phase + freq / RATE, 1.0)
			var tone := sin(TAU * _phase) * 0.7 + sin(TAU * _phase * 2.0) * 0.2 + sin(TAU * _phase * 3.01) * 0.1
			var env := minf(local * 12.0, 1.0) * exp(-local * 2.2)
			return tone * env * 0.25 * level
	return 0.0
