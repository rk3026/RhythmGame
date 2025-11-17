class_name MidiTrackManager
extends Node

## MidiTrackManager - Manages multiple synchronized audio tracks for MIDI songs
## Handles play, pause, seek, and volume control for multiple AudioStreamPlayers

signal playback_finished

# Track information structure
class AudioTrackInfo:
	var file_path: String
	var track_type: TrackType
	var volume_multiplier: float = 1.0
	
	func _init(p_file_path: String = "", p_track_type: TrackType = TrackType.SONG, p_volume: float = 1.0):
		file_path = p_file_path
		track_type = p_track_type
		volume_multiplier = p_volume

enum TrackType {
	DRUMS,
	BASS,
	GUITAR,
	VOCALS,
	KEYS,
	BACKING,  # Background/crowd
	SONG      # Full mix
}

# Dictionary of track_name -> AudioStreamPlayer
var audio_tracks: Dictionary = {}
# Dictionary of track_name -> AudioTrackInfo
var track_info: Dictionary = {}

var is_playing: bool = false
var stream_paused: bool = false
var master_position: float = 0.0
var sync_threshold: float = 0.050  # 50ms tolerance for drift correction

func _ready():
	pass

## Load multiple audio tracks from file paths
## @param tracks: Array of AudioTrackInfo objects
func load_tracks(tracks: Array) -> bool:
	clear_tracks()
	
	for track in tracks:
		if not track is AudioTrackInfo:
			push_error("MidiTrackManager: Invalid track info")
			continue
		
		if not FileAccess.file_exists(track.file_path):
			push_warning("MidiTrackManager: Track file not found: " + track.file_path)
			continue
		
		var stream = load(track.file_path)
		if not stream:
			push_warning("MidiTrackManager: Failed to load track: " + track.file_path)
			continue
		
		var player = AudioStreamPlayer.new()
		player.stream = stream
		player.bus = _get_bus_for_track_type(track.track_type)
		player.volume_db = linear_to_db(track.volume_multiplier)
		player.name = track.file_path.get_file().get_basename()
		
		add_child(player)
		
		var track_name = track.file_path.get_file()
		audio_tracks[track_name] = player
		track_info[track_name] = track
		
		# Connect finished signal from first track to detect song end
		if audio_tracks.size() == 1:
			player.connect("finished", Callable(self, "_on_track_finished"))
	
	if audio_tracks.is_empty():
		push_error("MidiTrackManager: No tracks loaded successfully")
		return false
	
	print("MidiTrackManager: Loaded %d tracks" % audio_tracks.size())
	return true

## Start playback of all tracks
## @param offset: Start position in seconds (for chart offset)
func play(offset: float = 0.0):
	if audio_tracks.is_empty():
		push_error("MidiTrackManager: No tracks loaded")
		return
	
	master_position = offset
	
	# Start all tracks synchronized
	for track_name in audio_tracks:
		var player = audio_tracks[track_name]
		if offset < 0:
			# Negative offset: audio starts earlier
			player.play(-offset)
		else:
			# Positive offset: notes start earlier, audio starts at 0
			player.play()
	
	is_playing = true
	stream_paused = false
	print("MidiTrackManager: Started playback at offset %.3f" % offset)

## Pause all tracks
func pause():
	if not is_playing:
		return
	
	stream_paused = true
	for track_name in audio_tracks:
		var player = audio_tracks[track_name]
		player.stream_paused = true
	
	print("MidiTrackManager: Paused playback")

## Resume all tracks
func resume():
	if not is_playing or not stream_paused:
		return
	
	stream_paused = false
	
	# Resume all tracks at current master position
	for track_name in audio_tracks:
		var player = audio_tracks[track_name]
		player.stream_paused = false
	
	# Sync all tracks to master position
	_sync_all_tracks()
	
	print("MidiTrackManager: Resumed playback")

## Stop all tracks
func stop():
	for track_name in audio_tracks:
		var player = audio_tracks[track_name]
		player.stop()
	
	is_playing = false
	stream_paused = false
	master_position = 0.0
	print("MidiTrackManager: Stopped playback")

## Seek all tracks to a specific time
## @param time: Position in seconds
func seek(time: float):
	master_position = time
	
	for track_name in audio_tracks:
		var player = audio_tracks[track_name]
		if player.stream and player.stream.has_method("get_length"):
			var length = player.stream.get_length()
			var clamped_time = clamp(time, 0.0, length - 0.01)
			player.seek(clamped_time)
		else:
			player.seek(time)
	
	print("MidiTrackManager: Seeked to %.3f" % time)

## Get current playback position (from first track)
func get_playback_position() -> float:
	if audio_tracks.is_empty():
		return 0.0
	
	# Use first track as reference
	var first_track_name = audio_tracks.keys()[0]
	var player = audio_tracks[first_track_name]
	
	if player.playing:
		return player.get_playback_position()
	else:
		return master_position

## Set volume for a specific track
## @param track_name: Name of the track file (e.g., "bass.ogg")
## @param volume_db: Volume in decibels
func set_track_volume(track_name: String, volume_db: float):
	if not audio_tracks.has(track_name):
		push_warning("MidiTrackManager: Track not found: " + track_name)
		return
	
	var player = audio_tracks[track_name]
	player.volume_db = volume_db

## Enable or disable a specific track
## @param track_name: Name of the track file
## @param enabled: Whether the track should play
func set_track_enabled(track_name: String, enabled: bool):
	if not audio_tracks.has(track_name):
		push_warning("MidiTrackManager: Track not found: " + track_name)
		return
	
	var player = audio_tracks[track_name]
	if enabled:
		player.volume_db = linear_to_db(track_info[track_name].volume_multiplier)
	else:
		player.volume_db = -80.0  # Mute

## Get list of loaded track names
func get_track_names() -> Array:
	return audio_tracks.keys()

## Check if any track is playing
func is_any_playing() -> bool:
	if not is_playing:
		return false
	
	for track_name in audio_tracks:
		var player = audio_tracks[track_name]
		if player.playing:
			return true
	
	return false

## Clear all loaded tracks
func clear_tracks():
	for track_name in audio_tracks:
		var player = audio_tracks[track_name]
		if player.is_connected("finished", Callable(self, "_on_track_finished")):
			player.disconnect("finished", Callable(self, "_on_track_finished"))
		player.queue_free()
	
	audio_tracks.clear()
	track_info.clear()

func _process(_delta):
	if not is_playing or stream_paused:
		return
	
	# Sync check: ensure all tracks are within threshold of master position
	if audio_tracks.size() > 1:
		_check_sync()

func _check_sync():
	var first_track_name = audio_tracks.keys()[0]
	var reference_player = audio_tracks[first_track_name]
	
	if not reference_player.playing:
		return
	
	var reference_pos = reference_player.get_playback_position()
	master_position = reference_pos
	
	# Check other tracks against reference
	for i in range(1, audio_tracks.keys().size()):
		var track_name = audio_tracks.keys()[i]
		var player = audio_tracks[track_name]
		
		if not player.playing:
			continue
		
		var player_pos = player.get_playback_position()
		var drift = abs(player_pos - reference_pos)
		
		# If drift exceeds threshold, resync
		if drift > sync_threshold:
			print("MidiTrackManager: Resyncing track %s (drift: %.3f)" % [track_name, drift])
			player.seek(reference_pos)

func _sync_all_tracks():
	if audio_tracks.is_empty():
		return
	
	var first_track_name = audio_tracks.keys()[0]
	var reference_player = audio_tracks[first_track_name]
	var reference_pos = reference_player.get_playback_position()
	
	for track_name in audio_tracks:
		if track_name == first_track_name:
			continue
		
		var player = audio_tracks[track_name]
		player.seek(reference_pos)

func _get_bus_for_track_type(track_type: TrackType) -> String:
	match track_type:
		TrackType.DRUMS, TrackType.BASS, TrackType.GUITAR, TrackType.VOCALS, TrackType.KEYS, TrackType.SONG:
			return "Music"
		TrackType.BACKING:
			return "SFX"
		_:
			return "Music"

func _on_track_finished():
	print("MidiTrackManager: Track finished")
	emit_signal("playback_finished")
	is_playing = false

func _exit_tree():
	clear_tracks()
