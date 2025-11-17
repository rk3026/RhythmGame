class_name MidiParser
extends ParserInterface

## MidiParser - Parses MIDI files using the working MidiFileParser
## Implements proper Guitar Hero MIDI note mapping

var cached_data = {}
const MidiFileParserClass = preload("res://Scripts/Parsers/midi_file_parser.gd")

# Guitar Hero MIDI note mapping
const MIDI_MAPPING = {
	"Expert": {
		"notes": [96, 97, 98, 99, 100],  # Green, Red, Yellow, Blue, Orange
		"open": 103,
		"hopo_offset": 5,
		"tap_offset": 6
	},
	"Hard": {
		"notes": [84, 85, 86, 87, 88],
		"open": 91,
		"hopo_offset": 5,
		"tap_offset": 6
	},
	"Medium": {
		"notes": [72, 73, 74, 75, 76],
		"open": 79,
		"hopo_offset": 5,
		"tap_offset": 6
	},
	"Easy": {
		"notes": [60, 61, 62, 63, 64],
		"open": 67,
		"hopo_offset": 5,
		"tap_offset": 6
	}
}

const STAR_POWER_NOTE = 116

func load_chart(path: String, _progress_callback: Callable = Callable()) -> Dictionary:
	if cached_data.has(path):
		var cached = cached_data[path]
		if not cached.has("path"):
			cached["path"] = path
		return cached

	print("MidiParser: Loading MIDI file: %s" % path)
	var midi_parser = MidiFileParserClass.load_file(path)
	if not midi_parser or midi_parser.state == MidiFileParserClass.MIDI_PARSER_ERROR:
		push_error("MidiParser: Failed to parse MIDI file: " + path)
		return {}

	var chart_data = _convert_midi_data(midi_parser)

	# Store the path for music stream lookup
	chart_data["path"] = path
	cached_data[path] = chart_data
	return chart_data

func _convert_midi_data(midi_parser) -> Dictionary:
	var tracks_data = []
	var tempo_events = []
	
	for track_idx in range(midi_parser.tracks.size()):
		var track = midi_parser.tracks[track_idx]
		var track_name = ""
		var note_events = []
		var current_tempo_bpm = 120.0
		
		# Scan for track name and note events
		for event in track.events:
			# Check for track name in meta events
			if event is MidiFileParserClass.Meta:
				if event.type == MidiFileParserClass.Meta.Type.TRACK_NAME:
					track_name = event.bytes.get_string_from_utf8()
					print("MidiParser: Track %d name: %s" % [track_idx, track_name])
				elif event.type == MidiFileParserClass.Meta.Type.SET_TEMPO:
					var tempo_us = event.value
					current_tempo_bpm = 60000000.0 / tempo_us
					tempo_events.append({
						"tick": event.absolute_ticks,
						"bpm": current_tempo_bpm
					})
			
			# Collect note events
			elif event is MidiFileParserClass.Midi:
				if event.status == MidiFileParserClass.Midi.Status.NOTE_ON and event.param2 > 0:
					note_events.append({
						"type": "note_on",
						"tick": event.absolute_ticks,
						"note": event.param1,
						"velocity": event.param2
					})
				elif event.status == MidiFileParserClass.Midi.Status.NOTE_OFF or \
					 (event.status == MidiFileParserClass.Midi.Status.NOTE_ON and event.param2 == 0):
					note_events.append({
						"type": "note_off",
						"tick": event.absolute_ticks,
						"note": event.param1
					})
		
		tracks_data.append({
			"name": track_name,
			"events": note_events
		})
	
	# Sort tempo events by tick
	tempo_events.sort_custom(func(a, b): return a.tick < b.tick)
	
	return {
		"format": midi_parser.header.format,
		"num_tracks": midi_parser.header.tracks,
		"division": midi_parser.header.time_division,
		"tracks": tracks_data,
		"tempo_events": tempo_events
	}

func get_resolution(sections: Dictionary) -> int:
	# MIDI division can be in ticks per quarter note or SMPTE format
	# For now, assume ticks per quarter note (positive values)
	var division = sections.get("division", 96)
	if division & 0x8000:  # Negative values indicate SMPTE format
		push_error("SMPTE time division not supported")
		return 96
	return division

func get_offset(_sections: Dictionary) -> float:
	# MIDI doesn't typically have an offset like .chart files
	# Could be added as a custom meta event in the future
	return 0.0

func get_music_stream(sections: Dictionary) -> String:
	# MIDI files don't contain embedded audio
	# Look for associated audio file in the same directory
	var midi_path = sections.get("path", "")
	if midi_path.is_empty():
		return ""

	var dir = midi_path.get_base_dir()

	# Try common audio file names first
	var common_names = ["song.ogg", "music.ogg", "audio.ogg", "track.ogg", "song.opus", "music.opus", "audio.opus", "track.opus"]
	for name in common_names:
		var full_path = dir + "/" + name
		var global_path = ProjectSettings.globalize_path(full_path)
		if FileAccess.file_exists(global_path):
			return name

	# Fall back to searching for any supported audio file
	var global_dir = ProjectSettings.globalize_path(dir)
	var dir_access = DirAccess.open(global_dir)
	if not dir_access:
		return ""

	# Look for common audio file extensions
	var extensions = ["ogg", "mp3", "wav", "flac", "opus"]
	for ext in extensions:
		dir_access.list_dir_begin()
		var file_name = dir_access.get_next()
		while file_name != "":
			if file_name.get_extension().to_lower() == ext:
				var full_path = dir + "/" + file_name
				var global_path = ProjectSettings.globalize_path(full_path)
				if FileAccess.file_exists(global_path):
					return file_name
			file_name = dir_access.get_next()

	return ""

func get_tempo_events(sections: Dictionary) -> Array:
	# Tempo events are already extracted in _convert_midi_data
	return sections.get("tempo_events", [])

func get_notes(sections: Dictionary, instrument: String, _resolution: int, _progress_callback: Callable = Callable()) -> Array:
	print("MidiParser: Getting notes for instrument: %s" % instrument)
	var notes = []
	
	# Extract difficulty from instrument string (e.g., "ExpertSingle" -> "Expert")
	var difficulty = _extract_difficulty(instrument)
	if not MIDI_MAPPING.has(difficulty):
		push_warning("MidiParser: Unknown difficulty '%s', defaulting to Expert" % difficulty)
		difficulty = "Expert"
	
	var mapping = MIDI_MAPPING[difficulty]
	var active_notes = {}  # MIDI note number -> {start_tick, fret, is_hopo, is_tap}
	
	# Find the appropriate track for this instrument
	var target_track = _find_instrument_track(sections.get("tracks", []), instrument)
	if target_track.is_empty():
		print("MidiParser: No track found for instrument '%s', using first track with notes" % instrument)
		# Fallback to first track with note events
		for track in sections.get("tracks", []):
			if not track.get("events", []).is_empty():
				target_track = track
				break
	
	if target_track.is_empty():
		push_warning("MidiParser: No tracks with notes found")
		return notes
	
	# Process note events
	for event in target_track.get("events", []):
		var midi_note = event.get("note", -1)
		if midi_note < 0:
			continue
		
		if event.get("type") == "note_on":
			# Check if this is a game note
			var fret = _map_midi_note_to_fret(midi_note, mapping)
			if fret >= 0:
				active_notes[midi_note] = {
					"start_tick": event.get("tick", 0),
					"fret": fret,
					"is_hopo": _is_hopo_note(midi_note, mapping),
					"is_tap": _is_tap_note(midi_note, mapping)
				}
		
		elif event.get("type") == "note_off":
			if active_notes.has(midi_note):
				var note_data = active_notes[midi_note]
				var start_tick = note_data.start_tick
				var end_tick = event.get("tick", start_tick)
				var length = end_tick - start_tick
				
				notes.append({
					"pos": start_tick,
					"fret": note_data.fret,
					"length": length,
					"is_hopo": note_data.is_hopo,
					"is_tap": note_data.is_tap
				})
				
				active_notes.erase(midi_note)
	
	# Sort by position
	notes.sort_custom(func(a, b): return a.pos < b.pos)
	
	print("MidiParser: Found %d notes for %s %s" % [notes.size(), difficulty, instrument])
	return notes

## Extract difficulty from instrument string
func _extract_difficulty(instrument: String) -> String:
	if "Expert" in instrument:
		return "Expert"
	elif "Hard" in instrument:
		return "Hard"
	elif "Medium" in instrument:
		return "Medium"
	elif "Easy" in instrument:
		return "Easy"
	return "Expert"  # Default

## Find track for specific instrument
func _find_instrument_track(tracks: Array, instrument: String) -> Dictionary:
	# Determine which part we're looking for
	var target_part = "PART GUITAR"  # Default
	if "Bass" in instrument:
		target_part = "PART BASS"
	elif "Drums" in instrument:
		target_part = "PART DRUMS"
	elif "Keys" in instrument:
		target_part = "PART KEYS"
	
	for track in tracks:
		var track_name = track.get("name", "").to_upper()
		if target_part in track_name:
			print("MidiParser: Found track '%s' for instrument '%s'" % [track_name, instrument])
			return track
	
	return {}

## Map MIDI note to fret (0-4) or -1 if not a playable note
func _map_midi_note_to_fret(midi_note: int, mapping: Dictionary) -> int:
	var notes = mapping.get("notes", [])
	for i in range(notes.size()):
		if midi_note == notes[i]:
			return i
	
	# Check for open note
	if midi_note == mapping.get("open", -1):
		return 5  # Open note (fret 5)
	
	return -1  # Not a playable note

## Check if MIDI note is a HOPO
func _is_hopo_note(midi_note: int, mapping: Dictionary) -> bool:
	var hopo_offset = mapping.get("hopo_offset", 5)
	var notes = mapping.get("notes", [])
	
	for note in notes:
		if midi_note == note + hopo_offset:
			return true
	
	return false

## Check if MIDI note is a TAP
func _is_tap_note(midi_note: int, mapping: Dictionary) -> bool:
	var tap_offset = mapping.get("tap_offset", 6)
	var notes = mapping.get("notes", [])
	
	for note in notes:
		if midi_note == note + tap_offset:
			return true
	
	return false

func get_note_times(notes: Array, resolution: int, tempo_events: Array) -> Array:
	var note_times = []
	var division = resolution  # resolution parameter is actually division in MIDI context

	for note in notes:
		var hit_time = ticks_to_time(note.pos, division, tempo_events)
		note_times.append({
			"hit_time": hit_time,
			"lane": note.fret,
			"note_type": 0,  # Regular note
			"is_sustain": note.length > 0,
			"sustain_length": ticks_to_time(note.length, division, tempo_events) if note.length > 0 else 0.0
		})

	return note_times

func get_available_instruments(sections: Dictionary) -> Dictionary:
	# MIDI files typically have one instrument per track
	# For now, return a single "MIDI" instrument
	var instruments = {}

	for track_idx in range(sections.get("tracks", []).size()):
		var track_name = "Track%d" % track_idx
		instruments[track_name] = {
			"name": track_name,
			"difficulty": 0  # Could be enhanced to detect difficulty
		}

	return instruments
