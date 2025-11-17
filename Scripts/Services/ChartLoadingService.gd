class_name ChartLoadingService
extends RefCounted

## ChartLoadingService - Centralized service for loading and parsing chart data
## Eliminates duplicate chart loading logic across gameplay scenes

## Data structure returned by load_chart_data()
## Contains all parsed chart information needed for gameplay
class ChartData:
	var sections: Dictionary
	var resolution: int
	var offset: float
	var tempo_events: Array
	var notes: Array
	var music_stream: String  # Single audio file (legacy/non-MIDI songs)
	var audio_tracks: Array   # Multiple audio tracks (MIDI songs) - Array of MidiTrackManager.AudioTrackInfo
	var is_midi: bool         # Whether this is a MIDI song with multiple tracks
	var parser: Variant       # ParserInterface implementation
	
	func _init(p_sections: Dictionary = {}, p_resolution: int = 0, p_offset: float = 0.0,
			   p_tempo_events: Array = [], p_notes: Array = [], p_music_stream: String = "",
			   p_audio_tracks: Array = [], p_is_midi: bool = false, p_parser: Variant = null):
		sections = p_sections
		resolution = p_resolution
		offset = p_offset
		tempo_events = p_tempo_events
		notes = p_notes
		music_stream = p_music_stream
		audio_tracks = p_audio_tracks
		is_midi = p_is_midi
		parser = p_parser

var parser_factory: ParserFactory

func _init():
	parser_factory = load("res://Scripts/Parsers/ParserFactory.gd").new()

## Load chart data from a file path
## @param chart_path: Path to the chart file (.chart, .mid, etc.)
## @param instrument: Instrument to load notes for (e.g., "Single")
## @param progress_callback: Optional callback for progress updates (takes float 0-100 and String message)
## @return: ChartData object with all parsed information, or null on error
func load_chart_data(chart_path: String, instrument: String, progress_callback: Callable = Callable()) -> ChartData:
	# Create parser for file type
	var parser = parser_factory.create_parser_for_file(chart_path)
	if not parser:
		push_error("ChartLoadingService: Failed to create parser for: " + chart_path)
		return null
	
	if progress_callback.is_valid():
		progress_callback.call(5.0, "Initializing parser...")
	
	# Load chart sections
	var sections = parser.load_chart(chart_path, progress_callback if progress_callback.is_valid() else Callable())
	if not sections:
		push_error("ChartLoadingService: Failed to load chart: " + chart_path)
		return null
	
	if progress_callback.is_valid():
		progress_callback.call(25.0, "Extracting metadata...")
	
	# Extract chart data
	var resolution = parser.get_resolution(sections)
	var offset = parser.get_offset(sections)
	
	if progress_callback.is_valid():
		progress_callback.call(30.0, "Loading tempo events...")
	
	var tempo_events = parser.get_tempo_events(sections)
	
	if progress_callback.is_valid():
		progress_callback.call(35.0, "Processing notes...")
	
	# Get notes with optional progress callback
	var notes = parser.get_notes(sections, instrument, resolution, 
								 progress_callback if progress_callback.is_valid() else Callable())
	
	if progress_callback.is_valid():
		progress_callback.call(75.0, "Loading music stream...")
	
	# Check if this is a MIDI file
	var extension = chart_path.get_extension().to_lower()
	var is_midi = (extension == "mid" or extension == "midi")
	var music_stream = ""
	var audio_tracks: Array = []
	
	if is_midi:
		# Load multiple audio tracks for MIDI songs
		var folder_path = chart_path.get_base_dir()
		var MidiAudioLoaderClass = load("res://Scripts/Audio/MidiAudioLoader.gd")
		audio_tracks = MidiAudioLoaderClass.scan_audio_files(folder_path)
		
		if audio_tracks.is_empty():
			push_warning("ChartLoadingService: No audio tracks found for MIDI song: " + chart_path)
		else:
			print("ChartLoadingService: Loaded %d audio tracks for MIDI song" % audio_tracks.size())
	else:
		# Get single music stream for regular charts
		music_stream = parser.get_music_stream(sections)
		if not music_stream:
			# Fallback to ini parser
			var ini_parser = parser_factory.create_metadata_parser()
			music_stream = ini_parser.get_music_stream_from_ini(chart_path)
	
	if progress_callback.is_valid():
		progress_callback.call(100.0, "Chart loading complete")
	
	# Return structured data
	return ChartData.new(sections, resolution, offset, tempo_events, notes, music_stream, audio_tracks, is_midi, parser)

## Load chart data synchronously (for quick loading without progress)
## @param chart_path: Path to the chart file
## @param instrument: Instrument to load notes for
## @return: ChartData object or null on error
func load_chart_data_sync(chart_path: String, instrument: String) -> ChartData:
	return load_chart_data(chart_path, instrument, Callable())

## Calculate number of lanes needed for a set of notes
## @param notes: Array of note objects with 'fret' property
## @return: Number of lanes required (minimum 5)
static func calculate_num_lanes(notes: Array) -> int:
	var max_type = 0
	for note in notes:
		if note.has("fret"):
			max_type = max(max_type, note.fret)
	return max(5, max_type + 1)

## Validate that preloaded data has all required fields
## @param preloaded_data: Dictionary to validate
## @return: true if valid, false otherwise
static func validate_preloaded_data(preloaded_data: Dictionary) -> bool:
	if preloaded_data.is_empty():
		return false
	
	var required_keys = ["sections", "resolution", "offset", "tempo_events", "notes"]
	for key in required_keys:
		if not preloaded_data.has(key):
			push_error("ChartLoadingService: Missing required key in preloaded_data: " + key)
			return false
	
	return true

## Create ChartData from preloaded data dictionary
## @param preloaded_data: Dictionary with chart data fields
## @return: ChartData object or null if validation fails
static func chart_data_from_preloaded(preloaded_data: Dictionary) -> ChartData:
	if not validate_preloaded_data(preloaded_data):
		return null
	
	return ChartData.new(
		preloaded_data.get("sections", {}),
		preloaded_data.get("resolution", 0),
		preloaded_data.get("offset", 0.0),
		preloaded_data.get("tempo_events", []),
		preloaded_data.get("notes", []),
		preloaded_data.get("music_stream", ""),
		preloaded_data.get("audio_tracks", []),
		preloaded_data.get("is_midi", false),
		preloaded_data.get("parser", null)
	)
