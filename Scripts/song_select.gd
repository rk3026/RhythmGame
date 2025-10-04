extends Control

@onready var song_list_container = $ScrollContainer/VBoxContainer
@onready var audio_player = $AudioStreamPlayer
@onready var back_button = $BackButton

var parser_factory: ParserFactory

func _ready():
	parser_factory = load("res://Scripts/Parsers/ParserFactory.gd").new()
	scan_songs()
	back_button.connect("pressed", Callable(self, "_on_back_button_pressed"))

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
				add_song_to_ui(song_info)
		file_name = dir.get_next()
	dir.list_dir_end()

func parse_song_info(folder_name: String) -> Dictionary:
	var folder_path = "res://Assets/Tracks/" + folder_name + "/"
	
	# Try to find chart file (could be .chart or .mid/.midi)
	var chart_path = find_chart_file(folder_path)
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
	
	var image_path = find_image(folder_path)
	var audio_path = folder_path + music_stream if music_stream else find_audio(folder_path)
	
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

func find_image(folder_path: String) -> String:
	var dir = DirAccess.open(folder_path)
	if not dir:
		return ""
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".png") or file_name.ends_with(".jpg"):
			dir.list_dir_end()
			return folder_path + file_name
		file_name = dir.get_next()
	dir.list_dir_end()
	return ""

func find_audio(folder_path: String) -> String:
	var dir = DirAccess.open(folder_path)
	if not dir:
		return ""
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".ogg"):
			dir.list_dir_end()
			return folder_path + file_name
		file_name = dir.get_next()
	dir.list_dir_end()
	return ""

func find_chart_file(folder_path: String) -> String:
	var dir = DirAccess.open(folder_path)
	if not dir:
		return ""
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if parser_factory.is_supported_file(file_name):
			dir.list_dir_end()
			return folder_path + file_name
		file_name = dir.get_next()
	dir.list_dir_end()
	return ""

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
	var file = FileAccess.open(chart_path, FileAccess.READ)
	if not file:
		return {}

	var header = file.get_buffer(4)
	if header.size() < 4 or header.get_string_from_ascii() != "MThd":
		file.close()
		return {}
	file.big_endian = true
	file.get_32() # header length, typically 6
	file.get_16() # format, unused here
	var track_count = file.get_16()
	file.close()

	var instruments = {}
	for i in range(track_count):
		instruments["Track %d" % (i + 1)] = ["Expert"]
	return instruments

func add_song_to_ui(song_info: Dictionary):
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.15, 1)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.3, 0.3, 0.3, 1)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	panel.add_theme_stylebox_override("panel", style)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	
	# Album art
	var texture_rect = TextureRect.new()
	if song_info.image_path:
		texture_rect.texture = load(song_info.image_path)
	texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	texture_rect.custom_minimum_size = Vector2(100, 100)
	texture_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(texture_rect)
	
	# Song info
	var info_vbox = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 5)
	
	var title_label = Label.new()
	title_label.text = song_info.title
	title_label.add_theme_font_size_override("font_size", 24)
	info_vbox.add_child(title_label)
	
	var artist_label = Label.new()
	artist_label.text = "by " + song_info.artist
	artist_label.add_theme_font_size_override("font_size", 18)
	info_vbox.add_child(artist_label)
	
	var album_label = Label.new()
	if song_info.album:
		album_label.text = "Album: " + song_info.album
		album_label.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(album_label)
	
	var year_genre_label = Label.new()
	var extra_info = []
	if song_info.year:
		extra_info.append(song_info.year)
	if song_info.genre:
		extra_info.append(song_info.genre)
	if song_info.length:
		extra_info.append(song_info.length)
	year_genre_label.text = " | ".join(extra_info)
	if year_genre_label.text:
		year_genre_label.add_theme_font_size_override("font_size", 14)
		info_vbox.add_child(year_genre_label)
	
	var difficulty_label = Label.new()
	difficulty_label.text = "Charter: " + song_info.charter
	difficulty_label.add_theme_font_size_override("font_size", 16)
	info_vbox.add_child(difficulty_label)
	
	hbox.add_child(info_vbox)
	
	# Buttons
	var buttons_vbox = VBoxContainer.new()
	buttons_vbox.custom_minimum_size = Vector2(200, 0)
	buttons_vbox.size_flags_horizontal = Control.SIZE_SHRINK_END
	buttons_vbox.add_theme_constant_override("separation", 10)
	
	var preview_button = Button.new()
	preview_button.text = "Preview"
	preview_button.connect("pressed", Callable(self, "_on_preview").bind(song_info))
	buttons_vbox.add_child(preview_button)
	
	# Add play buttons for each instrument and difficulty
	for instrument in song_info.instruments.keys():
		var instrument_label = Label.new()
		instrument_label.text = instrument
		instrument_label.add_theme_font_size_override("font_size", 16)
		buttons_vbox.add_child(instrument_label)
		
		for difficulty in song_info.instruments[instrument]:
			var play_button = Button.new()
			play_button.text = difficulty
			play_button.connect("pressed", Callable(self, "_on_play").bind(song_info.chart_path, instrument, difficulty))
			buttons_vbox.add_child(play_button)
	
	hbox.add_child(buttons_vbox)
	
	panel.add_child(hbox)
	song_list_container.add_child(panel)

func _on_preview(song_info: Dictionary):
	if audio_player.playing:
		audio_player.stop()
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
			# Stop after 10 seconds
			await get_tree().create_timer(10.0).timeout
			audio_player.stop()
		else:
			print("Failed to load audio stream: ", music_path)
	else:
		print("Music file not found: ", music_path)

func _on_play(chart_path: String, instrument: String, difficulty: String):
	if audio_player.playing:
		audio_player.stop()
	var loading_screen = load("res://Scenes/loading_screen.tscn").instantiate()
	loading_screen.chart_path = chart_path
	loading_screen.instrument = difficulty + instrument
	SceneSwitcher.push_scene_instance(loading_screen)

func _on_back_button_pressed():
	if audio_player.playing:
		audio_player.stop()
	SceneSwitcher.pop_scene()

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not visible and audio_player.playing:
			audio_player.stop()
