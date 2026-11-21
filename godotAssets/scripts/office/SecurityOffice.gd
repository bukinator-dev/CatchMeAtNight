extends Node3D
## Night 1 in the security office.
##
## Flow: title card -> click to clock in -> the phone rings (briefing) ->
## check the cameras -> survive until 6 AM while Lilly wanders toward your door.
## Night 1 can't kill you yet. It teaches the door, the cameras and the singing.
##
## Preview without playing (renders one frame to a PNG and quits):
##   godot --path . -- --screenshot=res://screenshots/office.png --view=desk|cams|door|room|right

const SECONDS_PER_HOUR := 60.0  # one in-game hour per real minute -> a 6-minute night
const PHONE_LINES := [
	["Hello? Hey, hi! You picked up. Great. Welcome to your first night.", 4.5],
	["I'm the day manager. I won't be here. Nobody's here. That's... kind of the point of the job.", 5.0],
	["So. The girls. Lilly, Mariam, Diana. Our little singing trio. The kids love them.", 5.0],
	["After closing they're supposed to stay on stage. Supposed to.", 4.0],
	["The monitor on your desk shows every camera. Look at it, press E. Number keys switch cams.", 5.5],
	["If you hear singing, that's Lilly. It means she's close. Hit the red button by the door.", 5.5],
	["Oh, and don't stare at the mirror. Diana doesn't like being... looked at.", 4.5],
	["Coffee's fresh, the couch is comfy, and it's only six hours. You'll be fine.", 4.5],
	["The last guy was fine. Mostly. Okay. Bye!", 3.5],
]

# Lilly's route (in-game minutes spent at each stop before moving on)
const LILLY_ROUTE := ["stage", "leftHall", "leftHallNear", "office"]
const LILLY_WAIT := {"stage": 55.0, "leftHall": 35.0, "leftHallNear": 20.0}
const CORRIDOR_FAR_X := -8.4
const CORRIDOR_NEAR_X := -4.2

@onready var office: OfficeBuilder = $Office
@onready var player: Player = $Player
@onready var hud: HUD = $HUD
@onready var cams: CameraSystem = $CameraSystem
@onready var feed_viewport: SubViewport = $FeedViewport
@onready var feed: SecurityFeed = $FeedViewport/Feed
@onready var hum: Synth = $Audio/Hum
@onready var ring: Synth = $Audio/Ring
@onready var static_sfx: Synth = $Audio/Static
@onready var song: Synth = $Audio/Song

var minutes := 0.0
var running := false
var won := false

var phone_state := "waiting"  # waiting, ringing, talking, done, missed
var _phone_timer := 4.0
var _ring_t := 0.0
var _handset_rest: Vector3
var cams_seen := false

var lilly := "stage"
var _lilly_wait := 55.0
var _lilly_door_closed_time := 0.0
var _lilly_visit := false

var _flicker_cooldown := 5.0
var _flicker_left := 0.0
var _back_cooldown := 3.0
var _back_left := 0.0
var _blackout := 0.0
var _microwave_t := 0.0


func _ready() -> void:
	office.build()
	var tex := feed_viewport.get_texture()
	office.set_monitor_texture(tex)
	cams.setup(feed, tex)
	_handset_rest = office.handset.position

	player.global_position = office.seat_position
	player.set_look(office.seat_yaw, -0.08)
	player.target_changed.connect(_on_target_changed)
	player.seated_changed.connect(func(is_seated: bool) -> void: office.chair.enabled = not is_seated)

	office.monitor.used.connect(_open_cams)
	office.phone.used.connect(_answer_phone)
	office.chair.used.connect(func() -> void: player.sit_at(office.seat_position, office.seat_yaw))
	office.lamp.used.connect(func() -> void: office.set_lamp(not office.lamp_on))
	office.door_button.used.connect(_toggle_door)
	cams.close_requested.connect(_close_cams)
	cams.camera_switched.connect(func(_i: int) -> void: static_sfx.burst(0.22))
	hud.intro_clicked.connect(_begin)

	ring.active = false
	song.level = 0.0
	static_sfx.level = 0.0
	_update_clock()
	_check_screenshot_args()


func _begin() -> void:
	if running or won:
		return
	running = true
	hud.hide_intro()
	player.controls_enabled = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.set_objective("Settle in. It's going to be a long night.")


# ------------------------------------------------------------------- loop

func _process(delta: float) -> void:
	_update_lights(delta)
	_microwave_t += delta
	office.microwave_label.visible = fmod(_microwave_t, 1.0) < 0.6  # forever blinking 12:00
	if not running:
		return
	minutes += delta * 60.0 / SECONDS_PER_HOUR
	_update_clock()
	_update_phone(delta)
	_update_lilly(delta)
	if minutes >= 360.0:
		_win()


func _clock_parts() -> Array:
	var h := int(minutes / 60.0)
	var m := int(fmod(minutes, 60.0))
	return [12 if h == 0 else h, m]


func _update_clock() -> void:
	var p := _clock_parts()
	var text := "%d:%02d AM" % [p[0], p[1]]
	hud.set_clock(text)
	feed.clock_text = text
	office.set_clock(minutes)
	player.hands.set_time_text("%d:%02d" % [p[0], p[1]])


# ------------------------------------------------------------------ phone

func _update_phone(delta: float) -> void:
	match phone_state:
		"waiting":
			_phone_timer -= delta
			if _phone_timer <= 0.0:
				phone_state = "ringing"
				_phone_timer = 30.0
				_ring_t = 0.0
				ring.restart()
				ring.active = true
				office.phone.enabled = true
				hud.set_objective("The phone is ringing.")
		"ringing":
			_ring_t += delta
			_phone_timer -= delta
			var rattling := fmod(_ring_t, 4.0) < 1.6
			office.handset.position = _handset_rest + (Vector3(randf_range(-1, 1), randf_range(0, 1), randf_range(-1, 1)) * 0.004 if rattling else Vector3.ZERO)
			if _phone_timer <= 0.0:
				phone_state = "missed"
				ring.active = false
				office.phone.enabled = false
				office.handset.position = _handset_rest
				hud.set_objective("Check the cameras: look at the monitor and press E.")


func _answer_phone() -> void:
	if phone_state != "ringing":
		return
	phone_state = "talking"
	ring.active = false
	office.phone.enabled = false
	office.handset.position = _handset_rest
	var lift := create_tween().set_trans(Tween.TRANS_SINE)
	lift.tween_property(office.handset, "position", _handset_rest + Vector3(0.05, 0.12, 0.08), 0.35)
	hud.set_objective("")
	for line in PHONE_LINES:
		hud.show_subtitle(line[0], line[1])
		await get_tree().create_timer(line[1] + 0.25).timeout
		if won:
			return
	create_tween().tween_property(office.handset, "position", _handset_rest, 0.3)
	phone_state = "done"
	if not cams_seen:
		hud.set_objective("Check the cameras: look at the monitor and press E.")
	else:
		hud.set_objective("Survive until 6 AM. Keep an eye on Lilly.")


# ---------------------------------------------------------------- cameras

func _open_cams() -> void:
	if cams.is_open or player.focused:
		return
	await player.focus_on(office.monitor_focus, 0.55)
	hud.set_dot_visible(false)
	cams.open()
	static_sfx.level = 1.0
	static_sfx.burst(0.4)
	if not cams_seen:
		cams_seen = true
		if phone_state in ["done", "missed"]:
			hud.set_objective("Survive until 6 AM. Keep an eye on Lilly.")


func _close_cams() -> void:
	if not cams.is_open:
		return
	cams.close()
	static_sfx.level = 0.0
	await player.unfocus(0.4)
	hud.set_dot_visible(true)


func _watching(cam_ids: Array) -> bool:
	return cams.is_open and feed.current_id() in cam_ids


# ------------------------------------------------------------------- door

func _toggle_door() -> void:
	office.set_shutter(not office.shutter_down)
	office.set_terminal(not office.shutter_down, 100)
	static_sfx.burst(0.12)


# ------------------------------------------------------------------ Lilly

func _set_lilly(state: String) -> void:
	lilly = state
	feed.set_lilly(state)
	office.lilly_in_corridor.visible = state == "office"
	if state == "office":
		office.lilly_in_corridor.position.x = CORRIDOR_FAR_X
	_lilly_wait = LILLY_WAIT.get(state, 0.0)
	_lilly_door_closed_time = 0.0


func _update_lilly(delta: float) -> void:
	var game_delta := delta * 60.0 / SECONDS_PER_HOUR
	# She only moves when nobody is watching the camera she's on.
	if lilly != "office":
		_lilly_wait -= game_delta
		if _lilly_wait <= 0.0:
			if _watching([_lilly_cam(lilly)]):
				_lilly_wait = 3.0
			else:
				var next: String = LILLY_ROUTE[LILLY_ROUTE.find(lilly) + 1]
				_set_lilly(next)
				if _watching([_lilly_cam(next)]):
					feed.glitch(0.6)
					static_sfx.burst(0.4)
	else:
		_update_lilly_in_corridor(delta)

	var target_song := {"stage": 0.0, "leftHall": 0.12, "leftHallNear": 0.35, "office": 0.75}.get(lilly, 0.0) as float
	if office.shutter_down:
		target_song *= 0.4
	if _lilly_visit:
		target_song = 0.0
	song.level = move_toward(song.level, target_song, delta * 0.3)


func _lilly_cam(state: String) -> String:
	return "stage" if state == "stage" else "leftHall"


func _update_lilly_in_corridor(delta: float) -> void:
	if _lilly_visit:
		return
	var sprite := office.lilly_in_corridor
	if office.shutter_down:
		_lilly_door_closed_time += delta
		if _lilly_door_closed_time > 6.0:
			# She gives up and goes back to the stage.
			_set_lilly("stage")
			_lilly_wait = 70.0
			hud.show_subtitle("(The singing fades back down the hall.)", 3.5)
		return
	# She creeps closer, but only while you're not looking at her.
	var to_her := (sprite.global_position + Vector3(0, 0.6, 0)) - player.camera.global_position
	var looking := not player.focused and (-player.camera.global_transform.basis.z).dot(to_her.normalized()) > 0.93
	if not looking:
		sprite.position.x = move_toward(sprite.position.x, CORRIDOR_NEAR_X, delta * 0.12)
	if sprite.position.x >= CORRIDOR_NEAR_X - 0.01:
		_lilly_visits()


func _lilly_visits() -> void:
	# Night 1 mercy: lights die, something passes the door, and she's gone.
	_lilly_visit = true
	_blackout = 1.6
	static_sfx.burst(0.8)
	if cams.is_open:
		feed.glitch(1.2)
	await get_tree().create_timer(0.9).timeout
	_set_lilly("stage")
	_lilly_wait = 80.0
	await get_tree().create_timer(1.0).timeout
	_lilly_visit = false
	hud.show_subtitle("(Something brushed past the doorway. Next time, close the door.)", 4.5)


# ----------------------------------------------------------------- lights

func _update_lights(delta: float) -> void:
	if _blackout > 0.0:
		_blackout -= delta
		office.set_ceiling_level(0.0)
		office.set_back_level(0.0)
		office.lamp_light.visible = false
		office.corridor_light.light_energy = 0.0
		if _blackout <= 0.0:
			office.set_lamp(office.lamp_on)
		return
	# main tube: steady, with an occasional stutter
	_flicker_cooldown -= delta
	if _flicker_cooldown <= 0.0:
		_flicker_cooldown = randf_range(6.0, 16.0)
		_flicker_left = randf_range(0.15, 0.5)
	if _flicker_left > 0.0:
		_flicker_left -= delta
		office.set_ceiling_level(0.2 if randf() < 0.5 else 1.0)
	else:
		office.set_ceiling_level(1.0)
	# back tube: dead, sputters back to life now and then
	_back_cooldown -= delta
	if _back_cooldown <= 0.0:
		_back_cooldown = randf_range(5.0, 12.0)
		_back_left = randf_range(0.3, 1.0)
	if _back_left > 0.0:
		_back_left -= delta
		office.set_back_level(1.0 if randf() < 0.35 else 0.0)
	else:
		office.set_back_level(0.0)
	office.corridor_light.light_energy = 0.04 if randf() < 0.04 else 0.35


# ------------------------------------------------------------------- misc

func _on_target_changed(target: Interactable) -> void:
	hud.set_prompt(target.prompt if target else "")


func _win() -> void:
	won = true
	running = false
	if cams.is_open:
		_close_cams()
	ring.active = false
	song.level = 0.0
	player.controls_enabled = false
	hud.set_prompt("")
	hud.set_objective("")
	hud.set_clock("6:00 AM")
	hud.show_end("6:00 AM", "You survived Night 1.")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _check_screenshot_args() -> void:
	var path := ""
	var view := "desk"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--screenshot="):
			path = arg.get_slice("=", 1)
		elif arg.begins_with("--view="):
			view = arg.get_slice("=", 1)
	if path == "":
		return
	_take_screenshot(path, view)


func _take_screenshot(path: String, view: String) -> void:
	running = true
	player.controls_enabled = true
	hud.skip_intro()
	match view:
		"cams":
			_open_cams()
		"door":
			player.set_look(deg_to_rad(84), -0.03)
			_set_lilly("office")
			office.lilly_in_corridor.position.x = -6.6
		"room":
			player.seated = false
			player.head.position.y = Player.STANDING_HEAD
			player.global_position = Vector3(-0.3, 0, -1.6)
			player.set_look(PI + 0.15, -0.18)
		"right":
			player.set_look(deg_to_rad(-75), -0.02)
	await get_tree().create_timer(1.6).timeout
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
