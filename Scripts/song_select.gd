extends Control

@onready var song_list_container = $MarginContainer/VBoxContainer/Middle/HBoxContainer/SongList/VBoxContainer
@onready var song_info_panel = $MarginContainer/VBoxContainer/Middle/HBoxContainer/SongSelection/SongInfo/VBoxContainer
@onready var audio_player = $AudioStreamPlayer
var midi_track_manager = null  # For MIDI song previews
@onready var back_button = $MarginContainer/VBoxContainer/Top/BackButton

var parser_factory: ParserFactory
var selected_song_info: Dictionary = {}
var all_songs: Array = []

func _ready():
	parser_factory = load("res://Scripts/Parsers/ParserFactory.gd").new()
	# Clear sample items from scene
	for child in song_list_container.get_children():
		child.queue_free()
	scan_songs()
	back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))
	
	# Auto-select first song if available
	if all_songs.size() > 0:
		_on_song_selected(all_songs[0])

func scan_songs():
	var tracks_dir = "res://Assets/Tracks/"
	var dir = DirAccess.open(tracks_dir)
	if not dir:
		print("Tracks directory not found")
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir():
			var song_info = parse_song_info(file_name)
			if song_info:
				all_songs.append(song_info)
				add_song_to_ui(song_info)
		file_name = dir.get_next()
	dir.list_dir_end()

func parse_song_info(folder_name: String) -> Dictionary:
	var folder_path = "res://Assets/Tracks/" + folder_name + "/"
	
	# Try to find chart file (could be .chart or .mid/.midi)
	var chart_path = FileSystemHelper.find_chart_file(folder_path)
	if not chart_path:
		return {}
	
	# Get song info from INI (lightweight, doesn't parse full chart)
	var ini_parser = parser_factory.create_metadata_parser()
	var ini_song_info = ini_parser.get_song_info_from_ini(chart_path)
	
	# Prefer metadata-defined music stream; chart scanning is avoided for performance
	var music_stream = ini_parser.get_music_stream_from_ini(chart_path)
	var instruments = _scan_instruments(chart_path)
	
	# Parse folder name for charter (fallback if not in INI)
	var regex = RegEx.new()
	regex.compile("(.+) - (.+) \\[(.+)\\]")
	var result = regex.search(folder_name)
	var charter = ini_song_info.get("charter", "Unknown")
	if charter == "" and result:
		charter = result.get_string(3).strip_edges()
	
	var image_path = FileSystemHelper.find_image_file(folder_path)
	var audio_path = folder_path + music_stream if music_stream else FileSystemHelper.find_audio_file(folder_path)
	
	# Use song length from INI if available; avoid loading audio here to keep UI snappy
	var length_str = ini_song_info.get("song_length_formatted", "")
	
	return {
		"title": ini_song_info.get("name", "Unknown Title"),
		"artist": ini_song_info.get("artist", "Unknown Artist"),
		"album": ini_song_info.get("album", ""),
		"year": ini_song_info.get("year", ""),
		"genre": ini_song_info.get("genre", ""),
		"charter": charter,
		"image_path": image_path,
		"chart_path": chart_path,
		"music_path": audio_path,
		"instruments": instruments,
		"length": length_str,
		"preview_start_time": ini_song_info.get("preview_start_time", -1.0),
		"loading_phrase": ini_song_info.get("loading_phrase", ""),
		"diff_guitar": ini_song_info.get("diff_guitar", ""),
		"icon": ini_song_info.get("icon", ""),
		"album_track": ini_song_info.get("album_track", ""),
		"playlist_track": ini_song_info.get("playlist_track", "")
	}



func _scan_instruments(chart_path: String) -> Dictionary:
	var extension = chart_path.get_extension().to_lower()
	match extension:
		"chart":
			return _scan_chart_instruments(chart_path)
		"mid", "midi":
			return _scan_midi_instruments(chart_path)
		_:
			return {}

func _scan_chart_instruments(chart_path: String) -> Dictionary:
	var file = FileAccess.open(chart_path, FileAccess.READ)
	if not file:
		return {}

	var instruments = {}
	var current_section = ""
	var in_section = false

	while not file.eof_reached():
		var line = file.get_line().strip_edges()
		if line.is_empty():
			continue
		if line.begins_with("[") and line.ends_with("]"):
			current_section = line.substr(1, line.length() - 2)
			in_section = false
		elif line == "{":
			in_section = true
		elif line == "}":
			in_section = false
		elif in_section and " = N " in line:
			var instrument = ""
			var difficulty = ""
			if current_section.ends_with("Single"):
				instrument = "Single"
				difficulty = current_section.substr(0, current_section.length() - 6)
			elif current_section.ends_with("Drums"):
				instrument = "Drums"
				difficulty = current_section.substr(0, current_section.length() - 5)
			elif current_section.ends_with("Bass"):
				instrument = "Bass"
				difficulty = current_section.substr(0, current_section.length() - 4)
			elif current_section.ends_with("Guitar"):
				instrument = "Guitar"
				difficulty = current_section.substr(0, current_section.length() - 6)
			if instrument != "" and difficulty != "":
				if not instruments.has(instrument):
					instruments[instrument] = []
				if not instruments[instrument].has(difficulty):
					instruments[instrument].append(difficulty)

	file.close()

	var order = {"Easy": 0, "Medium": 1, "Hard": 2, "Expert": 3}
	for inst in instruments.keys():
		instruments[inst].sort_custom(func(a, b):
			return order.get(a, 99) < order.get(b, 99)
		)

	return instruments

func _scan_midi_instruments(chart_path: String) -> Dictionary:
	# Use MidiFileParser to properly detect instruments and difficulties
	var MidiFileParserClass = load("res://Scripts/Parsers/midi_file_parser.gd")
	if not MidiFileParserClass:
		push_error("Failed to load MidiFileParser")
		return {}
	
	# Parse MIDI file (load_file is a static method that returns MidiFileParser instance)
	var midi_parser = MidiFileParserClass.load_file(chart_path)
	if not midi_parser or midi_parser.state == MidiFileParserClass.MIDI_PARSER_ERROR:
		return {}
	
	var instruments = {}
	var instrument_names = ["Guitar", "Bass", "Drums", "Keys"]  # Common GH MIDI instruments
	
	# Check each instrument for available difficulties
	for instrument_name in instrument_names:
		var difficulties = []
		
		# Try to find track for this instrument
		var track_name_search = "PART " + instrument_name.to_upper()
		var track_index = -1
		
		for i in range(midi_parser.tracks.size()):
			var current_track = midi_parser.tracks[i]
			# Check Meta events for TRACK_NAME
			for meta_event in current_track.meta:
				if meta_event.type == MidiFileParserClass.Meta.Type.TRACK_NAME:
					var track_name_str = meta_event.bytes.get_string_from_utf8()
					if track_name_search in track_name_str.to_upper():
						track_index = i
						break
			if track_index >= 0:
				break
		
		if track_index < 0:
			continue  # Instrument not found in MIDI
		
		# Check which difficulties have notes
		var instrument_track = midi_parser.tracks[track_index]
		var has_expert = false
		var has_hard = false
		var has_medium = false
		var has_easy = false
		
		# Check Midi events for notes
		for midi_event in instrument_track.midi:
			# Check for NOTE_ON with velocity > 0
			if midi_event.status == MidiFileParserClass.Midi.Status.NOTE_ON and midi_event.param2 > 0:
				var note = midi_event.param1
				# Check against MIDI note ranges from MidiParser.MIDI_MAPPING
				if note >= 96 and note <= 103:  # Expert range (96-100 + open 103)
					has_expert = true
				elif note >= 84 and note <= 91:  # Hard range (84-88 + open 91)
					has_hard = true
				elif note >= 72 and note <= 79:  # Medium range (72-76 + open 79)
					has_medium = true
				elif note >= 60 and note <= 67:  # Easy range (60-64 + open 67)
					has_easy = true
		
		# Add available difficulties
		if has_expert:
			difficulties.append("Expert")
		if has_hard:
			difficulties.append("Hard")
		if has_medium:
			difficulties.append("Medium")
		if has_easy:
			difficulties.append("Easy")
		
		if difficulties.size() > 0:
			instruments[instrument_name] = difficulties
	
	return instruments

func add_song_to_ui(song_info: Dictionary):
	# Use the SongPanel scene for consistent layout and to show clear/score info
	var scene = load("res://Scenes/Components/SongPanel.tscn")
	if not scene:
		push_error("Failed to load SongPanel.tscn")
		return
	var song_panel = scene.instantiate()

	# Connect button press to song selection
	song_panel.pressed.connect(_on_song_selected.bind(song_info))

	song_list_container.add_child(song_panel)

	# Populate basic data on the panel
	song_panel.set_song_data(song_info)

	# Populate score/accuracy using existing history integration
	# SongPanel exposes `score_label` and `percent_label` nodes used here
	if song_panel.has_method("get_song_info"):
		# Ensure labels exist and populate them
		var s_label = null
		var p_label = null
		if song_panel.has_node("Panel/MarginContainer/HBoxContainer/ScoreLabel"):
			s_label = song_panel.get_node("Panel/MarginContainer/HBoxContainer/ScoreLabel")
		if song_panel.has_node("Panel/MarginContainer/HBoxContainer/PercentLabel"):
			p_label = song_panel.get_node("Panel/MarginContainer/HBoxContainer/PercentLabel")
		if s_label and p_label:
			_populate_score_labels(song_info, s_label, p_label)
			# Mirror formatted values back into the song_info so panel can show them later if refreshed
			song_info["best_score_text"] = s_label.text
			song_info["best_accuracy_text"] = p_label.text

func _on_song_selected(song_info: Dictionary):
	selected_song_info = song_info
	
	# Play preview of selected song
	_on_preview(song_info)
	
	# Update album art
	var album_art = song_info_panel.get_node("AlbumArt")
	if song_info.image_path and FileAccess.file_exists(song_info.image_path):
		var texture = load(song_info.image_path)
		if texture:
			# Replace ColorRect with TextureRect if needed
			if album_art is ColorRect:
				var texture_rect = TextureRect.new()
				texture_rect.name = "AlbumArt"
				texture_rect.custom_minimum_size = Vector2(250, 250)
				texture_rect.layout_mode = 2
				texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
				texture_rect.texture = texture
				texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
				texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				
				var parent = album_art.get_parent()
				var index = album_art.get_index()
				parent.remove_child(album_art)
				album_art.queue_free()
				parent.add_child(texture_rect)
				parent.move_child(texture_rect, index)
			elif album_art is TextureRect:
				album_art.texture = texture
	
	# Update song title
	var song_title = song_info_panel.get_node("SongTitle")
	song_title.bbcode_enabled = true
	song_title.clear()
	song_title.append_text(StringFormatter.convert_color_tags_to_bbcode(song_info.title))
	
	# Update artist
	var artist = song_info_panel.get_node("Artist")
	artist.bbcode_enabled = true
	artist.clear()
	artist.append_text(StringFormatter.convert_color_tags_to_bbcode("Artist: " + song_info.artist))
	
	# Update album
	var album = song_info_panel.get_node("Album")
	album.bbcode_enabled = true
	album.clear()
	album.append_text(StringFormatter.convert_color_tags_to_bbcode("Album: " + (song_info.album if song_info.album else "Unknown")))
	album.visible = true
	
	# Update year
	var year = song_info_panel.get_node("Year")
	year.bbcode_enabled = true
	year.clear()
	year.append_text(StringFormatter.convert_color_tags_to_bbcode("Year: " + (song_info.year if song_info.year else "Unknown")))
	year.visible = true
	
	# Update genre
	var genre = song_info_panel.get_node("Genre")
	genre.bbcode_enabled = true
	genre.clear()
	genre.append_text(StringFormatter.convert_color_tags_to_bbcode("Genre: " + (song_info.genre if song_info.genre else "Unknown")))
	genre.visible = true
	
	# Update length
	var length = song_info_panel.get_node("Length")
	length.bbcode_enabled = true
	length.clear()
	length.append_text(StringFormatter.convert_color_tags_to_bbcode("Length: " + (song_info.length if song_info.length else "Unknown")))
	length.visible = true
	
	# Update charter (convert HTML-style color tags to BBCode)
	var charter = song_info_panel.get_node("Charter")
	charter.bbcode_enabled = true
	charter.clear()
	charter.append_text(StringFormatter.convert_color_tags_to_bbcode("Charter: " + song_info.charter))
	
	# Update difficulty buttons
	var difficulty_container = $MarginContainer/VBoxContainer/Middle/HBoxContainer/SongSelection/Difficulty/VBoxContainer/ScrollContainer/HBoxContainer
	for child in difficulty_container.get_children():
		child.queue_free()
	
	# Add buttons for each instrument and difficulty
	for instrument in song_info.instruments.keys():
		for difficulty in song_info.instruments[instrument]:
			var button = Button.new()
			button.text = difficulty + " " + instrument
			button.connect("pressed", Callable(self, "_on_play").bind(song_info.chart_path, instrument, difficulty))
			difficulty_container.add_child(button)

func _on_preview(song_info: Dictionary):
	# Stop any currently playing audio
	if audio_player.playing:
		audio_player.stop()
	if midi_track_manager:
		midi_track_manager.stop()
		midi_track_manager.queue_free()
		midi_track_manager = null
	
	# Check if this is a MIDI song
	var chart_path = song_info.chart_path
	var extension = chart_path.get_extension().to_lower()
	var is_midi = (extension == "mid" or extension == "midi")
	
	if is_midi:
		# Load multi-track MIDI preview
		var folder_path = chart_path.get_base_dir()
		var MidiAudioLoaderClass = load("res://Scripts/Audio/MidiAudioLoader.gd")
		var audio_tracks = MidiAudioLoaderClass.scan_audio_files(folder_path)
		
		if not audio_tracks.is_empty():
			var MidiTrackManagerClass = load("res://Scripts/Audio/MidiTrackManager.gd")
			midi_track_manager = MidiTrackManagerClass.new()
			add_child(midi_track_manager)
			if midi_track_manager.load_tracks(audio_tracks):
				# Use preview_start_time from song.ini if available
				var preview_start = song_info.get("preview_start_time", -1.0)
				if preview_start < 0:
					# Default to 1/3 of song length (estimate ~180s for most songs)
					preview_start = 60.0
				print("MIDI Preview start time: ", preview_start)
				midi_track_manager.play(preview_start)
			else:
				print("Failed to load MIDI tracks for preview")
				midi_track_manager.queue_free()
				midi_track_manager = null
		else:
			print("No audio tracks found for MIDI song")
	else:
		# Regular single-track preview
		var music_path = song_info.music_path
		if music_path and FileAccess.file_exists(music_path):
			var stream = load(music_path)
			if stream:
				audio_player.stream = stream
				# Use preview_start_time from song.ini if available, otherwise use 1/3 of song
				var preview_start = song_info.get("preview_start_time", -1.0)
				if preview_start < 0:
					var song_length = stream.get_length()
					preview_start = song_length / 3.0
				print("Preview start time: ", preview_start)
				audio_player.play()
				audio_player.seek(preview_start)
			else:
				print("Failed to load audio stream: ", music_path)
		else:
				print("Music file not found: ", music_path)

func _on_play(chart_path: String, instrument: String, difficulty: String):
	if audio_player.playing:
		audio_player.stop()
	if midi_track_manager:
		midi_track_manager.stop()
		midi_track_manager.queue_free()
		midi_track_manager = null
	var loading_screen = load("res://Scenes/loading_screen.tscn").instantiate()
	loading_screen.chart_path = chart_path
	loading_screen.instrument = difficulty + instrument
	SceneSwitcher.push_scene_instance(loading_screen)

func _on_back_button_pressed():
	if audio_player.playing:
		audio_player.stop()
	if midi_track_manager:
		midi_track_manager.stop()
		midi_track_manager.queue_free()
		midi_track_manager = null
	SceneSwitcher.pop_scene()

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not visible:
			if audio_player.playing:
				audio_player.stop()
			if midi_track_manager:
				midi_track_manager.stop()
				midi_track_manager.queue_free()
				midi_track_manager = null

# ============================================================================
# Score History Integration
# ============================================================================

func _populate_score_labels(song_info: Dictionary, score_label: Label, percent_label: Label):
	"""Populate score and accuracy labels from score history."""
	# Get best score across all difficulties for this song
	var best_overall = _get_best_score_for_song(song_info)
	
	if best_overall.is_empty():
		# Never played
		score_label.text = "---"
		percent_label.text = "---"
	else:
		# Show best score and accuracy
		score_label.text = StringFormatter.format_score(best_overall.high_score)
		percent_label.text = StringFormatter.format_accuracy(best_overall.best_accuracy)
		
		# Color-code by accuracy tier
		percent_label.modulate = _get_accuracy_color(best_overall.best_accuracy)

func _get_best_score_for_song(song_info: Dictionary) -> Dictionary:
	"""Find the best score across all difficulties for this song."""
	var best = {}
	var max_score = 0
	
	# Check all available difficulties
	for instrument in song_info.instruments.keys():
		for difficulty in song_info.instruments[instrument]:
			var key = difficulty + instrument
			var data = ScoreHistoryManager.get_score_data(song_info.chart_path, key)
			
			if not data.is_empty() and data.high_score > max_score:
				max_score = data.high_score
				best = data
	
	return best

func _get_accuracy_color(accuracy: float) -> Color:
	"""Get color for accuracy tier (gold/silver/bronze/etc.)."""
	if accuracy >= 99.0:
		return Color.GOLD
	elif accuracy >= 95.0:
		return Color(0.75, 0.75, 0.75)  # Silver
	elif accuracy >= 90.0:
		return Color(0.8, 0.5, 0.2)     # Bronze
	elif accuracy >= 80.0:
		return Color(0.5, 0.7, 1.0)     # Light blue
	else:
		return Color.WHITE
