extends Control

@onready var loading_label = $VBoxContainer/LoadingLabel
@onready var progress_bar = $VBoxContainer/ProgressBar

var chart_path: String
var instrument: String
var parser_factory: ParserFactory
var loading_thread: Thread
var loading_complete: bool = false
var loaded_data: Dictionary = {}
var target_progress: float = 0.0
var current_progress: float = 0.0
var progress_speed: float = 100.0  # units per second

func _ready():
	parser_factory = load("res://Scripts/Parsers/ParserFactory.gd").new()
	# Ensure loading screen is visible
	show()
	# Start loading process in a thread
	loading_thread = Thread.new()
	loading_thread.start(_load_chart_data_async)

func _process(delta: float) -> void:
	if current_progress < target_progress:
		current_progress = min(current_progress + progress_speed * delta, target_progress)
		progress_bar.value = current_progress
		
		if loading_complete and current_progress >= 100.0:
			_on_loading_finished()

func _load_chart_data_async():
	# Create progress callback
	var progress_callback = Callable(self, "_on_parsing_progress")
	
	# Create parser
	var parser = parser_factory.create_parser_for_file(chart_path)
	if not parser:
		push_error("Failed to create parser for: " + chart_path)
		return
	
	call_deferred("_update_progress", 5, "Initializing parser...")
	
	# Load chart sections with progress
	var sections = parser.load_chart(chart_path, progress_callback)
	call_deferred("_update_progress", 25, "Extracting metadata...")
	
	# Get basic data
	var resolution = parser.get_resolution(sections)
	var offset = parser.get_offset(sections)
	call_deferred("_update_progress", 30, "Loading tempo events...")
	
	var tempo_events = parser.get_tempo_events(sections)
	call_deferred("_update_progress", 35, "Processing notes...")
	
	# Get notes with progress
	var notes = parser.get_notes(sections, instrument, resolution, progress_callback)
	call_deferred("_update_progress", 65, "Processing note timings...")
	
	# Additional processing if needed - for now just update progress
	call_deferred("_update_progress", 75, "Loading music stream...")
	
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
			push_warning("LoadingScreen: No audio tracks found for MIDI song: " + chart_path)
		else:
			call_deferred("_update_progress", 80, "Loaded %d audio tracks..." % audio_tracks.size())
	else:
		# Get single music stream for regular charts
		music_stream = parser.get_music_stream(sections)
		if not music_stream:
			var ini_parser = parser_factory.create_metadata_parser()
			music_stream = ini_parser.get_music_stream_from_ini(chart_path)
	
	call_deferred("_update_progress", 85, "Finalizing data...")
	
	# Store loaded data
	loaded_data = {
		"sections": sections,
		"resolution": resolution,
		"offset": offset,
		"tempo_events": tempo_events,
		"notes": notes,
		"music_stream": music_stream,
		"audio_tracks": audio_tracks,
		"is_midi": is_midi,
		"parser": parser
	}
	
	call_deferred("_update_progress", 95, "Preparing gameplay...")
	call_deferred("_update_progress", 100, "Starting game...")
	call_deferred("_set_loading_complete")

func _update_progress(value: float, text: String):
	target_progress = value
	loading_label.text = text

func _on_parsing_progress(progress: float):
	# Update progress bar with actual parsing progress
	call_deferred("_update_progress", progress, "Parsing chart data...")

func _set_loading_complete():
	loading_complete = true

func _on_loading_finished():
	# Create gameplay scene with pre-loaded data
	var gameplay = load("res://Scenes/gameplay.tscn").instantiate()
	gameplay.chart_path = chart_path
	gameplay.instrument = instrument
	gameplay.preloaded_data = loaded_data
	
	# Transition to gameplay
	SceneSwitcher.replace_scene_instance(gameplay)

func _exit_tree():
	if loading_thread and loading_thread.is_alive():
		loading_thread.wait_to_finish()