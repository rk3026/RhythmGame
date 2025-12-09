extends Node
class_name EditorPlaybackController

signal playback_state_changed(is_playing: bool)
signal time_changed(current_time: float)

@onready var timeline_controller: TimelineController = $TimelineController
@onready var audio_player: AudioStreamPlayer = $AudioPlayer

var playback_speed: float = 1.0
var song_length: float = 0.0
var is_playing: bool = false
var _manual_time: float = 0.0
var _last_reported_time: float = -1.0

func _ready():
	set_process(true)
	timeline_controller.active = false
	audio_player.finished.connect(_on_audio_finished)

func configure(commands: Array = [], ctx: Dictionary = {}):
	# Reuse the existing TimelineController so commands stay compatible with gameplay.
	timeline_controller.setup(ctx, commands, song_length)
	timeline_controller.active = false
	timeline_controller.scrub_to(0.0)
	_manual_time = 0.0
	_emit_time(true)

func set_audio_stream(stream: AudioStream):
	if audio_player.playing:
		audio_player.stop()
	audio_player.stream = stream
	if stream and stream.has_method("get_length"):
		set_song_length(stream.get_length())
	else:
		set_song_length(song_length)

func set_song_length(length: float):
	song_length = max(length, 0.0)
	timeline_controller.song_end_time = song_length
	if timeline_controller.current_time > song_length:
		seek(song_length)

func set_playback_speed(speed: float):
	playback_speed = clamp(speed, 0.05, 3.0)
	audio_player.pitch_scale = playback_speed

func play(start_time: float = -1.0):
	if start_time >= 0.0:
		seek(start_time)
	if audio_player.stream:
		audio_player.pitch_scale = playback_speed
		audio_player.play(timeline_controller.current_time)
	else:
		_manual_time = timeline_controller.current_time
	is_playing = true
	emit_signal("playback_state_changed", true)

func pause():
	if not is_playing:
		return
	if audio_player.playing:
		audio_player.stop()
	_manual_time = timeline_controller.current_time
	is_playing = false
	emit_signal("playback_state_changed", false)

func stop():
	if audio_player.playing:
		audio_player.stop()
	is_playing = false
	seek(0.0)
	emit_signal("playback_state_changed", false)

func seek(time_value: float):
	var clamped = clamp(time_value, 0.0, song_length)
	if is_playing and audio_player.stream:
		audio_player.stop()
		audio_player.play(clamped)
		audio_player.pitch_scale = playback_speed
	elif not audio_player.stream:
		_manual_time = clamped
	timeline_controller.scrub_to(clamped)
	_emit_time(true)

func get_current_time() -> float:
	# If playing, return the actual audio position for most accurate time
	if is_playing and audio_player.stream and audio_player.playing:
		return audio_player.get_playback_position()
	return timeline_controller.current_time

func _process(delta: float):
	var new_time = timeline_controller.current_time
	if is_playing:
		if audio_player.stream and audio_player.playing:
			new_time = audio_player.get_playback_position()
		else:
			_manual_time += delta * playback_speed
			new_time = _manual_time
		if new_time >= song_length:
			_on_audio_finished()
			return
		timeline_controller.scrub_to(new_time)
	_emit_time()

func _emit_time(force: bool = false):
	var current_time = timeline_controller.current_time
	if force or not is_equal_approx(current_time, _last_reported_time):
		_last_reported_time = current_time
		emit_signal("time_changed", current_time)

func _on_audio_finished():
	if audio_player.playing:
		audio_player.stop()
	is_playing = false
	timeline_controller.scrub_to(song_length)
	_emit_time(true)
	emit_signal("playback_state_changed", false)
