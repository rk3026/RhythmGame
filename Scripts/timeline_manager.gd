extends Node

signal song_completed

@export var timeline_controller_path: NodePath
@export var note_spawner_path: NodePath
@export var note_pool_path: NodePath
@export var score_manager_path: NodePath
@export var timeline_ui_path: NodePath

var midi_track_manager: Node = null
var audio_player: AudioStreamPlayer = null
var is_midi_song: bool = false
var chart_offset: float = 0.0

var timeline_controller: Node = null
var note_spawner: Node = null
var note_pool: Node = null
var score_manager: Node = null
var timeline_ui: Panel = null
var completion_emitted: bool = false

func _ready():
	timeline_controller = get_node_or_null(timeline_controller_path)
	note_spawner = get_node_or_null(note_spawner_path)
	note_pool = get_node_or_null(note_pool_path)
	score_manager = get_node_or_null(score_manager_path)
	timeline_ui = get_node_or_null(timeline_ui_path)
	if timeline_ui:
		timeline_ui.connect("scrub_requested", Callable(self, "_on_scrub_requested"))
		timeline_ui.connect("toggle_direction_requested", Callable(self, "_on_toggle_direction_requested"))
	set_process(true)
	set_process_unhandled_input(true)

func set_audio_context(audio_player_ref: AudioStreamPlayer, midi_manager_ref: Node, is_midi: bool, chart_offset_value: float):
	audio_player = audio_player_ref
	midi_track_manager = midi_manager_ref
	is_midi_song = is_midi
	chart_offset = chart_offset_value

func begin(song_start_time: float):
	if not note_spawner:
		push_error("TimelineManager missing NoteSpawner reference")
		return
	if not timeline_controller:
		push_error("TimelineManager missing TimelineController reference")
		return
	note_spawner.song_start_time = song_start_time
	note_spawner.start_spawning()
	timeline_controller.ctx = {
		"note_spawner": note_spawner,
		"note_pool": note_pool,
		"score_manager": score_manager,
		"get_time": Callable(timeline_controller, "get_time"),
		"song_start_time": note_spawner.song_start_time
	}
	var spawn_cmds = note_spawner.build_spawn_commands()
	var last_time = 0.0
	for data in note_spawner.spawn_data:
		last_time = max(last_time, data.hit_time)
	last_time += 5.0
	timeline_controller.setup(timeline_controller.ctx, spawn_cmds, last_time)
	note_spawner.attach_timeline(timeline_controller)
	timeline_controller.active = true
	completion_emitted = false

func _process(_delta):
	if not timeline_controller or not timeline_controller.active:
		return
	_keep_audio_synced()
	if _is_song_complete() and not completion_emitted:
		completion_emitted = true
		emit_signal("song_completed")
	_update_ui()

func _unhandled_input(event):
	if not timeline_controller:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_BRACKETLEFT:
				_scrub(-2.0)
				return
			KEY_BRACKETRIGHT:
				_scrub(2.0)
				return
			KEY_BACKSLASH:
				_toggle_direction()
				return

func _on_scrub_requested(amount: float):
	_scrub(amount)

func _on_toggle_direction_requested():
	_toggle_direction()

func _scrub(amount: float):
	if not timeline_controller:
		return
	timeline_controller.step_scrub(amount)
	_sync_audio_to_timeline(true)

func _toggle_direction():
	if not timeline_controller:
		return
	var new_dir = -1 if timeline_controller.direction == 1 else 1
	timeline_controller.set_direction(new_dir)
	if new_dir == -1:
		if is_midi_song and _has_midi_manager():
			midi_track_manager.pause()
		elif _has_audio_player():
			audio_player.stream_paused = true
	else:
		if is_midi_song and _has_midi_manager():
			_sync_audio_to_timeline(false)
		elif _has_audio_player():
			audio_player.stream_paused = false
			_sync_audio_to_timeline(false)

func _keep_audio_synced():
	if timeline_controller.direction != 1:
		return
	if is_midi_song and _has_midi_manager() and midi_track_manager.is_playing:
		var desired = _timeline_to_audio_time(timeline_controller.current_time)
		var diff = abs(midi_track_manager.get_playback_position() - desired)
		if diff > 0.050:
			midi_track_manager.seek(desired)
	elif _has_audio_player() and audio_player.playing and not audio_player.stream_paused:
		var desired_audio = _timeline_to_audio_time(timeline_controller.current_time)
		var diff_audio = abs(audio_player.get_playback_position() - desired_audio)
		if diff_audio > 0.050:
			audio_player.seek(desired_audio)

func _is_song_complete() -> bool:
	if not timeline_controller or not note_spawner:
		return false
	var spawner_done = timeline_controller.executed_count >= timeline_controller.command_log.size()
	var no_active = note_spawner.active_notes.is_empty()
	var audio_done = false
	if is_midi_song and _has_midi_manager():
		audio_done = not midi_track_manager.is_playing
	elif _has_audio_player():
		audio_done = not audio_player.playing
	else:
		audio_done = true
	var timeline_done = timeline_controller.current_time >= timeline_controller.song_end_time
	return spawner_done and no_active and (audio_done or timeline_done)

func _update_ui():
	if not timeline_ui or not timeline_controller:
		return
	var has_audio = (is_midi_song and _has_midi_manager()) or _has_audio_player()
	var audio_pos = 0.0
	if is_midi_song and _has_midi_manager():
		audio_pos = midi_track_manager.get_playback_position()
	elif _has_audio_player():
		audio_pos = audio_player.get_playback_position()
	timeline_ui.update_display(
		timeline_controller.current_time,
		timeline_controller.direction,
		timeline_controller.executed_count,
		timeline_controller.command_log.size(),
		has_audio,
		audio_pos
	)

func _sync_audio_to_timeline(force_seek: bool):
	if not timeline_controller or timeline_controller.direction == -1:
		return
	var desired = _timeline_to_audio_time(timeline_controller.current_time)
	if is_midi_song and _has_midi_manager():
		var diff = abs(midi_track_manager.get_playback_position() - desired)
		if force_seek or diff > 0.010:
			midi_track_manager.seek(desired)
		if not midi_track_manager.is_playing:
			midi_track_manager.resume()
	elif _has_audio_player():
		var length = 0.0
		if audio_player.stream and audio_player.stream.has_method("get_length"):
			length = audio_player.stream.get_length()
		if length > 0.0:
			desired = clamp(desired, 0.0, length - 0.01)
		var diff_audio = abs(audio_player.get_playback_position() - desired)
		if force_seek or diff_audio > 0.010:
			audio_player.seek(desired)
		if not audio_player.playing:
			audio_player.play()

func _timeline_to_audio_time(timeline_time: float) -> float:
	if chart_offset < 0.0:
		return max(0.0, timeline_time - chart_offset)
	return max(0.0, timeline_time)

func _has_audio_player() -> bool:
	return audio_player != null and is_instance_valid(audio_player)

func _has_midi_manager() -> bool:
	return midi_track_manager != null and is_instance_valid(midi_track_manager)
