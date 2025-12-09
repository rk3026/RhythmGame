extends RefCounted
class_name ChartEditorFileService

const NoteSpawnerHelper = preload("res://Scripts/note_spawner.gd")
const ChartLoadingService = preload("res://Scripts/Services/ChartLoadingService.gd")

func reset_document(chart_document: ChartDocument, command_stack: EditorCommandStack) -> void:
	if chart_document:
		chart_document.clear()
	if command_stack:
		command_stack.clear()

func load_chart(path: String, instrument: String, chart_document: ChartDocument, command_stack: EditorCommandStack) -> Dictionary:
	if path.is_empty():
		return {}
	var chart_loading_service: ChartLoadingService = ChartLoadingService.new()
	var chart_data := chart_loading_service.load_chart_data_sync(path, instrument)
	if not chart_data:
		return {}
	_reset_for_import(chart_document, command_stack)
	_import_chart_notes(chart_document, chart_data)
	if command_stack:
		command_stack.clear()
	
	# Calculate time field for tempo events using TempoCalculator
	var tempo_events_with_time = TempoCalculator.recalculate_tempo_event_times(chart_data.tempo_events, chart_data.resolution)
	
	return {
		"tempo_events": tempo_events_with_time,
		"time_signatures": chart_data.time_signatures,
		"resolution": chart_data.resolution,
		"offset": chart_data.offset
	}

func save_chart(path: String, chart_document: ChartDocument, song_properties: Dictionary, chart_resolution: int, tempo_events: Array, difficulty: String, instrument: String) -> bool:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if not file:
		push_error("Failed to open file for writing: " + path)
		return false
	file.store_line("[Song]")
	file.store_line("{")
	file.store_line("  Name = \"" + song_properties.get("name", "Untitled") + "\"")
	file.store_line("  Artist = \"" + song_properties.get("artist", "Unknown") + "\"")
	file.store_line("  Charter = \"" + song_properties.get("charter", "Unknown") + "\"")
	file.store_line("  Album = \"" + song_properties.get("album", "") + "\"")
	file.store_line("  Year = \"" + song_properties.get("year", "") + "\"")
	file.store_line("  Offset = " + str(song_properties.get("offset", 0)))
	file.store_line("  Resolution = " + str(chart_resolution))
	file.store_line("  Genre = \"" + song_properties.get("genre", "") + "\"")
	if song_properties.has("audio_file"):
		file.store_line("  MusicStream = \"" + song_properties.get("audio_file", "") + "\"")
	file.store_line("}")
	file.store_line("[SyncTrack]")
	file.store_line("{")
	file.store_line("  0 = TS 4")
	for tempo_event in tempo_events:
		var tick: int = _time_to_tick(tempo_event.time, tempo_events, chart_resolution)
		file.store_line("  " + str(tick) + " = B " + str(int(tempo_event.bpm * 1000)))
	file.store_line("}")
	file.store_line("[Events]")
	file.store_line("{")
	file.store_line("}")
	var difficulty_name: String = "[" + difficulty + instrument.capitalize() + "]"
	file.store_line(difficulty_name)
	file.store_line("{")
	var sorted_notes: Array = chart_document.get_notes()
	sorted_notes.sort_custom(func(a, b): return a.time < b.time)
	for note_data in sorted_notes:
		var tick: int = _time_to_tick(note_data.time, tempo_events, chart_resolution)
		var sustain_ticks: int = _time_to_tick(note_data.sustain_length, tempo_events, chart_resolution) if note_data.sustain_length > 0 else 0
		file.store_line("  " + str(tick) + " = N " + str(note_data.lane) + " " + str(sustain_ticks))
	file.store_line("}")
	file.close()
	return true

func _reset_for_import(chart_document: ChartDocument, command_stack: EditorCommandStack) -> void:
	if chart_document:
		chart_document.clear()
	if command_stack:
		command_stack.clear()

func _import_chart_notes(chart_document: ChartDocument, chart_data) -> void:
	var helper: NoteSpawnerHelper = NoteSpawnerHelper.new()
	var source_notes: Array = chart_data.notes
	var note_times: Array = helper.get_note_times(source_notes, chart_data.resolution, chart_data.tempo_events)
	var imported: Array = []
	for i in source_notes.size():
		var raw_note: Dictionary = source_notes[i]
		var time_seconds: float = float(note_times[i]) + float(chart_data.offset)
		var sustain_length: float = 0.0
		if raw_note.length > 0:
			var bpm_at_note: float = helper.get_current_bpm(chart_data.tempo_events, raw_note.pos)
			sustain_length = (raw_note.length / chart_data.resolution) * (60.0 / bpm_at_note)
		var note_entry: Dictionary = {
			"lane": raw_note.fret,
			"time": time_seconds,
			"note_type": helper.get_note_type(raw_note),
			"is_sustain": sustain_length > 0.0,
			"sustain_length": sustain_length,
			"note_flags": {
				"is_hopo": raw_note.get("is_hopo", false),
				"is_tap": raw_note.get("is_tap", false),
				"original_tick": raw_note.get("pos", 0)
			}
		}
		imported.append(note_entry)
	chart_document.import_notes(imported)

func _time_to_tick(time: float, tempo_events: Array, chart_resolution: int) -> int:
	if tempo_events.is_empty():
		return int((time * 120.0 * chart_resolution) / 60.0)
	var bpm: float = tempo_events[0].bpm
	return int((time * bpm * chart_resolution) / 60.0)
