class_name MidiAudioLoader
extends RefCounted

## MidiAudioLoader - Scans and loads audio files for MIDI songs
## Detects track types based on file names and returns AudioTrackInfo objects

## Scan a folder for MIDI audio files
## @param folder_path: Path to the song folder
## @return: Array of MidiTrackManager.AudioTrackInfo objects
static func scan_audio_files(folder_path: String) -> Array:
	var MidiTrackManagerClass = load("res://Scripts/Audio/MidiTrackManager.gd")
	var tracks: Array = []
	
	var dir = DirAccess.open(folder_path)
	if not dir:
		push_error("MidiAudioLoader: Failed to open folder: " + folder_path)
		return tracks
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir():
			var extension = file_name.get_extension().to_lower()
			if extension in ["ogg", "mp3", "wav", "opus"]:
				var full_path = folder_path + "/" + file_name
				var track_type = _detect_track_type(file_name)
				var volume = _get_default_volume(track_type)
				
				var track_info = MidiTrackManagerClass.AudioTrackInfo.new(full_path, track_type, volume)
				tracks.append(track_info)
				
				print("MidiAudioLoader: Found track - %s (type: %s)" % [file_name, _track_type_to_string(track_type)])
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort tracks for consistent ordering (drums first, then instruments, then backing)
	tracks.sort_custom(func(a, b): return _get_track_priority(a.track_type) < _get_track_priority(b.track_type))
	
	return tracks

## Detect track type from file name
## Returns integer matching MidiTrackManager.TrackType enum
static func _detect_track_type(file_name: String) -> int:
	var name_lower = file_name.get_basename().to_lower()
	
	# Check for specific track types (using int constants matching enum)
	const DRUMS = 0
	const BASS = 1
	const GUITAR = 2
	const VOCALS = 3
	const KEYS = 4
	const BACKING = 5
	const SONG = 6
	
	if "drum" in name_lower:
		return DRUMS
	elif "bass" in name_lower:
		return BASS
	elif "guitar" in name_lower or "gtr" in name_lower:
		return GUITAR
	elif "vocal" in name_lower or "vox" in name_lower or "voice" in name_lower:
		return VOCALS
	elif "key" in name_lower or "piano" in name_lower or "synth" in name_lower:
		return KEYS
	elif "crowd" in name_lower or "audience" in name_lower or "backing" in name_lower:
		return BACKING
	elif "song" in name_lower or "music" in name_lower or "track" in name_lower or "audio" in name_lower:
		return SONG
	else:
		# Default to SONG type for unknown tracks
		return SONG

## Get default volume multiplier for track type
static func _get_default_volume(track_type: int) -> float:
	const DRUMS = 0
	const BASS = 1
	const GUITAR = 2
	const VOCALS = 3
	const KEYS = 4
	const BACKING = 5
	const SONG = 6
	
	match track_type:
		DRUMS:
			return 1.0
		BASS:
			return 1.0
		GUITAR:
			return 1.0
		VOCALS:
			return 0.9  # Slightly quieter
		KEYS:
			return 0.8
		BACKING:
			return 0.6  # Crowd/backing quieter
		SONG:
			return 1.0
		_:
			return 1.0

## Get priority for sorting (lower = higher priority)
static func _get_track_priority(track_type: int) -> int:
	const DRUMS = 0
	const BASS = 1
	const GUITAR = 2
	const VOCALS = 3
	const KEYS = 4
	const BACKING = 5
	const SONG = 6
	
	match track_type:
		SONG:
			return 0  # Full mix first (if available)
		DRUMS:
			return 1
		BASS:
			return 2
		GUITAR:
			return 3
		KEYS:
			return 4
		VOCALS:
			return 5
		BACKING:
			return 6
		_:
			return 99

## Convert track type enum to string for logging
static func _track_type_to_string(track_type: int) -> String:
	const DRUMS = 0
	const BASS = 1
	const GUITAR = 2
	const VOCALS = 3
	const KEYS = 4
	const BACKING = 5
	const SONG = 6
	
	match track_type:
		DRUMS:
			return "DRUMS"
		BASS:
			return "BASS"
		GUITAR:
			return "GUITAR"
		VOCALS:
			return "VOCALS"
		KEYS:
			return "KEYS"
		BACKING:
			return "BACKING"
		SONG:
			return "SONG"
		_:
			return "UNKNOWN"

## Check if a folder contains MIDI audio files (multiple tracks)
static func has_midi_audio_tracks(folder_path: String) -> bool:
	const SONG = 6
	var tracks = scan_audio_files(folder_path)
	# If we have more than one audio file, or specific instrument files, it's likely a MIDI setup
	if tracks.size() > 1:
		return true
	
	# Check if the single file is a full mix vs instrument track
	if tracks.size() == 1:
		var track_type = tracks[0].track_type
		return track_type != SONG
	
	return false
