extends PanelContainer
## Self-contained featured song display component with audio playback
##
## Automatically scans the song library, randomly selects songs, plays them,
## and displays song information including album art, title, artist, and playback time.
## This component is fully self-contained - just drop it into a scene.

signal song_selected(song_path: String)

# Node references
@onready var album_art: TextureRect = %AlbumArt
@onready var song_title: ScrollContainer = %SongTitle  # AutoScrollLabel (ScrollContainer)
@onready var artist: ScrollContainer = %Artist  # AutoScrollLabel (ScrollContainer)
@onready var time_label: Label = %TimeLabel
@onready var audio_player: AudioStreamPlayer = %AudioPlayer

# Visualizer bars
var visualizer_bars: Array[ColorRect] = []

# Audio analysis
var spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
const NUM_BARS := 8
const MIN_FREQ := 20.0
const MAX_FREQ := 8000.0
const BAR_LERP_SPEED := 15.0
var bar_heights: Array[float] = []

# Reuse existing utilities
var parser_factory: ParserFactory
var ini_parser: RefCounted

# Song data
var available_songs: Array[Dictionary] = []
var current_song_index: int = -1
var current_song_data: Dictionary = {}

# Playback state
var is_playing: bool = false
var playback_position: float = 0.0

func _ready():
	# Initialize parsers
	parser_factory = load("res://Scripts/Parsers/ParserFactory.gd").new()
	ini_parser = parser_factory.create_metadata_parser()
	
	# Configure AutoScrollLabel styling
	_setup_scroll_labels()
	
	# Setup visualizer bars
	_setup_visualizer()
	
	# Setup audio effect for spectrum analysis
	_setup_spectrum_analyzer()
	
	_scan_song_library()
	_play_random_song()
	
	# Connect audio player signal
	if audio_player:
		audio_player.finished.connect(_on_audio_finished)
	
	# Enable mouse filter for click detection
	mouse_filter = Control.MOUSE_FILTER_STOP

func _process(_delta: float):
	"""Update playback time display and visualizer."""
	if is_playing and audio_player and audio_player.playing:
		playback_position = audio_player.get_playback_position()
		_update_time_display()
		_update_visualizer(_delta)

func _gui_input(event: InputEvent):
	"""Handle click to select/play song."""
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_on_clicked()

func _scan_song_library():
	"""Scan Assets/Tracks directory for all available songs using existing utilities."""
	available_songs.clear()
	
	var tracks_path = "res://Assets/Tracks"
	var subdirs = FileSystemHelper.list_subdirectories(tracks_path)
	
	if subdirs.is_empty():
		push_warning("FeaturedSong: No song folders found in " + tracks_path)
		return
	
	for folder_name in subdirs:
		var song_folder = tracks_path + "/" + folder_name
		var song_data = _load_song_data(song_folder)
		
		if song_data and not song_data.is_empty():
			available_songs.append(song_data)
	
	if available_songs.is_empty():
		push_warning("FeaturedSong: No valid songs found in library")
	else:
		print("FeaturedSong: Found ", available_songs.size(), " songs in library")

func _load_song_data(song_folder: String) -> Dictionary:
	"""Load song metadata using existing IniParser."""
	var song_data = {}
	
	# Find chart file using FileSystemHelper
	var chart_path = FileSystemHelper.find_chart_file(song_folder)
	if not chart_path:
		return song_data
	
	# Use IniParser to extract song info
	var ini_song_info = ini_parser.get_song_info_from_ini(chart_path)
	if ini_song_info.is_empty():
		return song_data
	
	# Build song data dictionary
	song_data["folder_path"] = song_folder
	song_data["chart_path"] = chart_path
	song_data["name"] = ini_song_info.get("name", "Unknown Title")
	song_data["artist"] = ini_song_info.get("artist", "Unknown Artist")
	song_data["year"] = ini_song_info.get("year", "")
	song_data["preview_start_time"] = ini_song_info.get("preview_start_time", -1.0)
	song_data["song_length_seconds"] = ini_song_info.get("song_length_seconds", 0.0)
	
	# Find audio file using FileSystemHelper
	var music_stream = ini_parser.get_music_stream_from_ini(chart_path)
	if music_stream:
		song_data["audio_path"] = song_folder + "/" + music_stream
	else:
		song_data["audio_path"] = FileSystemHelper.find_audio_file(song_folder)
	
	# Find album art using FileSystemHelper
	var image_path = FileSystemHelper.find_image_file(song_folder)
	if image_path:
		song_data["album_art_path"] = image_path
	
	return song_data

func _play_random_song():
	"""Select and play a random song from the library."""
	if available_songs.is_empty():
		push_warning("FeaturedSong: No songs available to play")
		return
	
	# Select random song (avoid repeating current song if possible)
	var new_index = randi() % available_songs.size()
	
	if available_songs.size() > 1:
		# Try to pick a different song than current
		var attempts = 0
		while new_index == current_song_index and attempts < 5:
			new_index = randi() % available_songs.size()
			attempts += 1
	
	current_song_index = new_index
	current_song_data = available_songs[current_song_index]
	
	_update_display()
	_play_audio()

func _update_display():
	"""Update UI with current song information."""
	if current_song_data.is_empty():
		return
	
	# Update text labels using AutoScrollLabel API
	if song_title and song_title.has_method("set_text"):
		song_title.set_text(current_song_data.get("name", "Unknown Title"))
	
	if artist and artist.has_method("set_text"):
		var artist_text = current_song_data.get("artist", "Unknown Artist")
		var year = current_song_data.get("year", "")
		if year != "":
			artist_text += " (" + str(year) + ")"
		artist.set_text(artist_text)
	
	# Load album art
	if album_art and current_song_data.has("album_art_path"):
		var texture = load(current_song_data["album_art_path"])
		if texture:
			album_art.texture = texture
		else:
			_set_default_album_art()
	else:
		_set_default_album_art()
	
	# Reset time display
	playback_position = 0.0
	_update_time_display()

func _set_default_album_art():
	"""Set a default placeholder for album art."""
	if album_art:
		album_art.texture = null
		# The ColorRect background will show through

func _play_audio():
	"""Load and play the current song's audio."""
	if not audio_player:
		return
	
	if not current_song_data.has("audio_path"):
		push_warning("FeaturedSong: No audio file for song: " + current_song_data.get("name", "Unknown"))
		return
	
	var audio_path = current_song_data["audio_path"]
	
	# Load audio stream
	var audio_stream = load(audio_path)
	if not audio_stream:
		push_error("FeaturedSong: Failed to load audio: " + audio_path)
		return
	
	audio_player.stream = audio_stream
	
	# Start from preview time if available (already in seconds from IniParser)
	var start_time = current_song_data.get("preview_start_time", -1.0)
	if start_time > 0.0:
		audio_player.play(start_time)
	else:
		audio_player.play()
	
	is_playing = true

func _update_time_display():
	"""Update the time label with current playback position."""
	if not time_label:
		return
	
	var current_seconds = int(playback_position)
	var total_seconds = 0
	
	# Get total length from song data (already in seconds from IniParser)
	if current_song_data.has("song_length_seconds"):
		total_seconds = int(current_song_data["song_length_seconds"])
	elif audio_player and audio_player.stream:
		total_seconds = int(audio_player.stream.get_length())
	
	# Format time as MM:SS using existing StringFormatter pattern
	var current_time_str = _format_time(current_seconds)
	var total_time_str = _format_time(total_seconds)
	
	time_label.text = current_time_str + " / " + total_time_str

func _format_time(seconds: int) -> String:
	"""Format seconds as MM:SS."""
	var minutes = int(float(seconds) / 60.0)
	var secs = seconds % 60
	return "%02d:%02d" % [minutes, secs]

func _on_audio_finished():
	"""Called when current song finishes playing."""
	is_playing = false
	_play_random_song()

func _on_clicked():
	"""Called when component is clicked."""
	if current_song_data.is_empty():
		return
	
	# Emit signal with current song folder path
	var song_path = current_song_data.get("folder_path", "")
	if song_path != "":
		song_selected.emit(song_path)
		print("FeaturedSong: Song selected: ", song_path)

# Public API
func skip_to_next_song():
	"""Skip to next random song."""
	_play_random_song()

func pause():
	"""Pause playback."""
	if audio_player and audio_player.playing:
		audio_player.stream_paused = true
		is_playing = false

func resume():
	"""Resume playback."""
	if audio_player:
		audio_player.stream_paused = false
		is_playing = true

func stop():
	"""Stop playback."""
	if audio_player:
		audio_player.stop()
		is_playing = false
		playback_position = 0.0
		_update_time_display()

# ============================================================================
# Audio Visualizer
# ============================================================================

func _setup_scroll_labels():
	"""Configure styling for AutoScrollLabel components."""
	# Configure song title (larger font)
	if song_title and song_title.has_method("get_label"):
		var title_label = song_title.get_label()
		if title_label:
			var title_settings = LabelSettings.new()
			title_settings.font_size = 16
			title_label.label_settings = title_settings
			song_title.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_LEFT)
	
	# Configure artist (smaller font, different color)
	if artist and artist.has_method("get_label"):
		var artist_label = artist.get_label()
		if artist_label:
			var artist_settings = LabelSettings.new()
			artist_settings.font_size = 13
			artist_settings.font_color = Color(0.8, 0.8, 0.8, 1.0)
			artist_label.label_settings = artist_settings
			artist.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_LEFT)

func _setup_visualizer():
	"""Initialize visualizer bars and data structures."""
	var visualizer_container = get_node_or_null("MarginContainer/VBoxContainer/ContentRow/VisualizerContainer")
	if not visualizer_container:
		push_warning("FeaturedSong: Visualizer container not found")
		return
	
	# Get all bar nodes
	for i in range(NUM_BARS):
		var bar = visualizer_container.get_node_or_null("Bar" + str(i + 1))
		if bar and bar is ColorRect:
			visualizer_bars.append(bar)
			bar_heights.append(0.0)
	
	if visualizer_bars.size() != NUM_BARS:
		push_warning("FeaturedSong: Expected %d bars, found %d" % [NUM_BARS, visualizer_bars.size()])

func _setup_spectrum_analyzer():
	"""Add spectrum analyzer effect to audio bus."""
	if not audio_player:
		return
	
	# Get the bus index for the audio player
	var bus_name = audio_player.bus
	var bus_idx = AudioServer.get_bus_index(bus_name)
	
	# Check if spectrum analyzer already exists
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectSpectrumAnalyzer:
			spectrum_analyzer = AudioServer.get_bus_effect_instance(bus_idx, i)
			return
	
	# Add new spectrum analyzer
	var spectrum_effect = AudioEffectSpectrumAnalyzer.new()
	spectrum_effect.buffer_length = 0.1  # Lower latency
	spectrum_effect.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
	AudioServer.add_bus_effect(bus_idx, spectrum_effect)
	
	# Get the effect instance
	var effect_idx = AudioServer.get_bus_effect_count(bus_idx) - 1
	spectrum_analyzer = AudioServer.get_bus_effect_instance(bus_idx, effect_idx)

func _update_visualizer(delta: float):
	"""Update visualizer bars based on audio spectrum data."""
	if not spectrum_analyzer or visualizer_bars.is_empty():
		return
	
	# Sample frequency bands
	for i in range(min(NUM_BARS, visualizer_bars.size())):
		# Calculate frequency range for this bar (logarithmic distribution)
		var freq_ratio = float(i) / float(NUM_BARS)
		var freq_start = MIN_FREQ * pow(MAX_FREQ / MIN_FREQ, freq_ratio)
		var freq_end = MIN_FREQ * pow(MAX_FREQ / MIN_FREQ, (freq_ratio + 1.0 / NUM_BARS))
		
		# Get magnitude for this frequency range
		var magnitude = spectrum_analyzer.get_magnitude_for_frequency_range(
			freq_start, 
			freq_end
		).length()
		
		# Convert to decibels and normalize (typical range: -60 to 0 dB)
		var db = linear_to_db(magnitude)
		var normalized = clamp((db + 60.0) / 60.0, 0.0, 1.0)
		
		# Apply smoothing
		var target_height = normalized * 40.0  # Max 40px height for more visibility
		bar_heights[i] = lerp(bar_heights[i], target_height, delta * BAR_LERP_SPEED)
		
		# Update bar visual - set both custom_minimum_size and size
		var bar = visualizer_bars[i]
		var new_height = max(3.0, bar_heights[i])  # Min 3px height
		bar.custom_minimum_size.y = new_height
		bar.size.y = new_height
		
		# Force the parent container to recalculate layout
		if bar.get_parent():
			bar.get_parent().queue_sort()
		
		# Optional: Color gradient based on intensity
		var intensity = bar_heights[i] / 40.0
		bar.color = Color(0.6 + intensity * 0.4, 0.4, 0.8, 0.8 + intensity * 0.2)
