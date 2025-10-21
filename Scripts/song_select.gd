extends Control

@onready var song_list_container = $MarginContainer/VBoxContainer/Middle/MarginContainer/SongList/VBoxContainer
@onready var song_info_panel = $MarginContainer/VBoxContainer/Middle/SongSelection/SongInfo/VBoxContainer
@onready var audio_player = $AudioStreamPlayer
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
	# Create the song button (flat style, 50px height)
	var song_button = Button.new()
	song_button.custom_minimum_size = Vector2(0, 50)
	song_button.flat = true
	song_button.pivot_offset = Vector2(0, 25)  # Center pivot for scaling
	
	# Create the background panel with semi-transparent style
	var panel = Panel.new()
	panel.name = "Panel"
	panel.layout_mode = 1
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow clicks to pass through to button
	
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.7647059, 0.7647059, 0.7647059, 0.2509804)
	panel.add_theme_stylebox_override("panel", panel_style)
	song_button.add_child(panel)
	
	# Create HBoxContainer for labels
	var hbox = HBoxContainer.new()
	hbox.layout_mode = 1
	hbox.anchor_right = 1.0
	hbox.anchor_bottom = 1.0
	hbox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hbox.grow_vertical = Control.GROW_DIRECTION_BOTH
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_theme_constant_override("separation", 20)
	song_button.add_child(hbox)
	
	# Create LabelSettings for consistent styling
	var label_settings = LabelSettings.new()
	label_settings.font_size = 22
	
	# Artist container with fixed width
	var artist_container = Control.new()
	artist_container.custom_minimum_size = Vector2(200, 0)
	artist_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	artist_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(artist_container)
	
	# Artist label (uppercase, right-aligned, auto-scroll)
	var artist_label = load("res://Scripts/Components/AutoScrollLabel.gd").new()
	artist_label.layout_mode = 1
	artist_label.anchor_right = 1.0
	artist_label.anchor_bottom = 1.0
	artist_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	artist_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	artist_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	artist_label.set_label_settings(label_settings)
	artist_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_RIGHT)
	artist_label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	artist_label.set_text(song_info.artist.to_upper())
	artist_container.add_child(artist_label)
	
	# Song container with fixed width
	var song_container = Control.new()
	song_container.custom_minimum_size = Vector2(300, 0)
	song_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	song_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(song_container)
	
	# Song title label (left-aligned, auto-scroll)
	var song_label = load("res://Scripts/Components/AutoScrollLabel.gd").new()
	song_label.layout_mode = 1
	song_label.anchor_right = 1.0
	song_label.anchor_bottom = 1.0
	song_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	song_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	song_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	song_label.set_label_settings(label_settings)
	song_label.set_vertical_alignment(VERTICAL_ALIGNMENT_CENTER)
	song_label.set_horizontal_alignment(HORIZONTAL_ALIGNMENT_LEFT)
	song_label.set_text(song_info.title)
	song_container.add_child(song_label)
	
	# Score label (placeholder for future high score tracking)
	var score_label = Label.new()
	score_label.text = ""  # Will be populated below
	score_label.label_settings = label_settings
	score_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(score_label)
	
	# Percent label (placeholder for future completion tracking)
	var percent_label = Label.new()
	percent_label.text = ""  # Will be populated below
	percent_label.label_settings = label_settings
	percent_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(percent_label)
	
	# NEW: Populate score and accuracy from history
	_populate_score_labels(song_info, score_label, percent_label)
	
	# Connect button press to update song info panel
	song_button.connect("pressed", Callable(self, "_on_song_selected").bind(song_info))
	
	# Connect hover events for scale and highlight effects
	song_button.connect("mouse_entered", Callable(self, "_on_song_button_hover_enter").bind(song_button))
	song_button.connect("mouse_exited", Callable(self, "_on_song_button_hover_exit").bind(song_button))
	
	song_list_container.add_child(song_button)

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
	song_title.append_text(_convert_color_tags_to_bbcode(song_info.title))
	
	# Update artist
	var artist = song_info_panel.get_node("Artist")
	artist.bbcode_enabled = true
	artist.clear()
	artist.append_text(_convert_color_tags_to_bbcode("Artist: " + song_info.artist))
	
	# Update album
	var album = song_info_panel.get_node("Album")
	album.bbcode_enabled = true
	album.clear()
	album.append_text(_convert_color_tags_to_bbcode("Album: " + (song_info.album if song_info.album else "Unknown")))
	album.visible = true
	
	# Update year
	var year = song_info_panel.get_node("Year")
	year.bbcode_enabled = true
	year.clear()
	year.append_text(_convert_color_tags_to_bbcode("Year: " + (song_info.year if song_info.year else "Unknown")))
	year.visible = true
	
	# Update genre
	var genre = song_info_panel.get_node("Genre")
	genre.bbcode_enabled = true
	genre.clear()
	genre.append_text(_convert_color_tags_to_bbcode("Genre: " + (song_info.genre if song_info.genre else "Unknown")))
	genre.visible = true
	
	# Update length
	var length = song_info_panel.get_node("Length")
	length.bbcode_enabled = true
	length.clear()
	length.append_text(_convert_color_tags_to_bbcode("Length: " + (song_info.length if song_info.length else "Unknown")))
	length.visible = true
	
	# Update charter (convert HTML-style color tags to BBCode)
	var charter = song_info_panel.get_node("Charter")
	charter.bbcode_enabled = true
	charter.clear()
	charter.append_text(_convert_color_tags_to_bbcode("Charter: " + song_info.charter))
	
	# Update difficulty buttons
	var difficulty_container = $MarginContainer/VBoxContainer/Middle/SongSelection/Difficulty/VBoxContainer/ScrollContainer/HBoxContainer
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

func _convert_color_tags_to_bbcode(text: String) -> String:
	# Convert HTML-like <color=#HEX> tags (as found in some song.ini files)
	# to Godot RichTextLabel BBCode: [color=#HEX]. Also normalize missing '#'.
	var result := text

	# 1) Convert open tags: <color=#aabbcc> or <color=aabbcc>
	var re_open := RegEx.new()
	# Capture any value up to '>' allowing optional '#'
	re_open.compile("<color=([^>]+)>")
	result = re_open.sub(result, "[color=$1]", true)

	# 2) Convert close tags: </color>
	var re_close := RegEx.new()
	re_close.compile("</color>")
	result = re_close.sub(result, "[/color]", true)

	# 3) Ensure [color=HEX] has a leading '#'
	var re_missing_hash := RegEx.new()
	re_missing_hash.compile("\\[color=([0-9a-fA-F]{3,8})\\]")
	result = re_missing_hash.sub(result, "[color=#$1]", true)

	return result

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not visible and audio_player.playing:
			audio_player.stop()

func _on_song_button_hover_enter(button: Button):
	# Animate scale up and brighten background
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.05, 1.05), 0.2)
	
	# Brighten the panel background
	var panel = button.get_node("Panel")
	tween.tween_method(func(value): 
		var style = panel.get_theme_stylebox("panel").duplicate()
		style.bg_color = Color(0.9, 0.9, 0.9, 0.4).lerp(Color(1.0, 1.0, 1.0, 0.5), value)
		panel.add_theme_stylebox_override("panel", style)
	, 0.0, 1.0, 0.2)

func _on_song_button_hover_exit(button: Button):
	# Animate scale back to normal and dim background
	var tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Dim the panel background back to original
	var panel = button.get_node("Panel")
	tween.tween_method(func(value): 
		var style = panel.get_theme_stylebox("panel").duplicate()
		style.bg_color = Color(1.0, 1.0, 1.0, 0.5).lerp(Color(0.7647059, 0.7647059, 0.7647059, 0.2509804), value)
		panel.add_theme_stylebox_override("panel", style)
	, 0.0, 1.0, 0.2)

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
		score_label.text = _format_score(best_overall.high_score)
		percent_label.text = _format_accuracy(best_overall.best_accuracy)
		
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

func _format_score(score: int) -> String:
	"""Format score with commas for readability (e.g., 123456 → 123,456)."""
	var score_str = str(score)
	var formatted = ""
	var count = 0
	
	for i in range(score_str.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			formatted = "," + formatted
		formatted = score_str[i] + formatted
		count += 1
	
	return formatted

func _format_accuracy(accuracy: float) -> String:
	"""Format accuracy as percentage with one decimal place."""
	return ("%.1f" % accuracy) + "%"

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
