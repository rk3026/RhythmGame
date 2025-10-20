extends Node3D

@onready var runway: MeshInstance3D = $Runway
@onready var note_scene = preload("res://Scenes/note.tscn")
@onready var input_handler = $InputHandler
@onready var score_manager = $ScoreManager
@onready var note_spawner = $NoteSpawner
@onready var note_pool = $NoteSpawner/NotePool
var hit_effect_pool: Node
var timeline_controller = null

@export var num_lanes: int
var lanes: Array = []
var original_materials: Array = []

@export var chart_path: String
@export var instrument: String

var preloaded_data: Dictionary = {}
var current_tween = null
var audio_player: AudioStreamPlayer
var song_finished: bool = false
var countdown_active: bool = false
var settings_manager
var animation_director: Node = null
var chart_offset: float = 0.0

func find_audio_file(folder_path: String) -> String:
	var dir = DirAccess.open(folder_path)
	if not dir:
		return ""
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(".ogg"):
			dir.list_dir_end()
			return folder_path + "/" + file_name
		file_name = dir.get_next()
	dir.list_dir_end()
	return ""

func start_countdown(callback: Callable):
	countdown_active = true
	var label = $UI/JudgementLabel
	for i in range(3, 0, -1):
		label.text = str(i)
		label.modulate = Color.WHITE
		label.modulate.a = 1
		await get_tree().create_timer(1.0).timeout
	label.text = "Go!"
	await get_tree().create_timer(0.5).timeout
	label.text = ""
	countdown_active = false
	callback.call()

var parser_factory: ParserFactory

func _ready():
	parser_factory = load("res://Scripts/Parsers/ParserFactory.gd").new()
	
	var sections
	var resolution
	var offset
	var tempo_events
	var notes
	var parser
	
	if preloaded_data.is_empty():
		# Original loading logic
		parser = parser_factory.create_parser_for_file(chart_path)
		if not parser:
			push_error("Failed to create parser for: " + chart_path)
			return
		
		sections = parser.load_chart(chart_path)
		resolution = parser.get_resolution(sections)
		offset = parser.get_offset(sections)
		chart_offset = offset
		tempo_events = parser.get_tempo_events(sections)
		notes = parser.get_notes(sections, instrument, resolution)
	else:
		# Use preloaded data
		sections = preloaded_data.sections
		resolution = preloaded_data.resolution
		offset = preloaded_data.offset
		chart_offset = offset
		tempo_events = preloaded_data.tempo_events
		notes = preloaded_data.notes
		parser = preloaded_data.parser
	
	var max_type = 0
	for note in notes:
		max_type = max(max_type, note.fret)
	num_lanes = max(5, max_type + 1)
	
	runway.set_script(load("res://Scripts/board_renderer.gd"))
	runway.num_lanes = num_lanes
	runway.board_width = runway.mesh.size.x
	runway.setup_lanes()
	runway.create_hit_zones()
	runway.create_lane_lines()
	runway.set_board_texture()
	lanes = runway.lanes
	original_materials = runway.original_materials

	# Create hit effect pool (only once per gameplay instance)
	hit_effect_pool = load("res://Scripts/HitEffectPool.gd").new()
	hit_effect_pool.name = "HitEffectPool"
	add_child(hit_effect_pool)

	# Animation director (central lightweight animation system)
	if not has_node("AnimationDirector"):
		animation_director = load("res://Scripts/animation_director.gd").new()
		animation_director.name = "AnimationDirector"
		add_child(animation_director)
	else:
		animation_director = get_node("AnimationDirector")
	
	settings_manager = _get_settings_manager()
	
	# Configure input handler AFTER lanes exist (its _ready ran earlier)
	input_handler.original_materials = original_materials
	input_handler.configure(lanes, num_lanes)
	
	# Configure note spawner
	note_spawner.notes = notes
	note_spawner.tempo_events = tempo_events
	note_spawner.resolution = resolution
	note_spawner.offset = offset
	note_spawner.lanes = lanes
	note_spawner.note_scene = note_scene
	note_spawner.note_pool = note_pool
	
	# Apply user settings (note speed and custom keys) after configuring components
	if settings_manager:
		# Re-configure input handler with custom keys
		input_handler.setup_lane_keys(num_lanes)
	
	# Connect signals
	score_manager.connect("combo_changed", Callable(self, "_on_combo_changed"))
	score_manager.connect("score_changed", Callable(self, "_on_score_changed"))
	input_handler.connect("note_hit", Callable(note_spawner, "_on_note_hit"))
	input_handler.connect("note_hit", Callable(self, "_on_note_hit"))
	note_spawner.connect("note_spawned", Callable(self, "_on_note_spawned"))
	_on_combo_changed(0)
	_on_score_changed(0)
	
	var music_stream
	if preloaded_data.is_empty():
		music_stream = parser.get_music_stream(sections)
		if not music_stream:
			var ini_parser = parser_factory.create_metadata_parser()
			music_stream = ini_parser.get_music_stream_from_ini(chart_path)
	else:
		music_stream = preloaded_data.music_stream
	
	var folder = chart_path.get_base_dir()
	var audio_path = ""
	if music_stream:
		audio_path = folder + "/" + music_stream
	else:
		# Scan for any .ogg file in the folder
		audio_path = find_audio_file(folder)
	
	if audio_path and FileAccess.file_exists(audio_path):
		audio_player = AudioStreamPlayer.new()
		audio_player.stream = load(audio_path)
		add_child(audio_player)
		# Start countdown before playing
		start_countdown(func():
			if offset < 0:
				audio_player.play(-offset)
			else:
				audio_player.play()
			_start_note_spawning()
		)
	else:
		print("No audio file found for: ", chart_path)
		# Still start the game without audio
		start_countdown(func():
			_start_note_spawning()
		)
	
	$UI/PauseButton.connect("pressed", Callable(self, "_on_pause_button_pressed"))
	
	# Connect pause menu buttons
	$UI/PauseMenu/Panel/VBoxContainer/ResumeButton.connect("pressed", Callable(self, "_on_resume"))
	$UI/PauseMenu/Panel/VBoxContainer/EndSongButton.connect("pressed", Callable(self, "_on_end_song"))
	$UI/PauseMenu/Panel/VBoxContainer/SongSelectButton.connect("pressed", Callable(self, "_on_song_select"))
	$UI/PauseMenu/Panel/VBoxContainer/MainMenuButton.connect("pressed", Callable(self, "_on_main_menu"))

	# Debug timeline UI wiring (optional panel)
	if $UI.has_node("DebugTimeline"):
		var dbg = $UI/DebugTimeline
		if dbg.has_node("VBox/Buttons/Back2"):
			dbg.get_node("VBox/Buttons/Back2").connect("pressed", Callable(self, "_on_debug_back2"))
		if dbg.has_node("VBox/Buttons/Fwd2"):
			dbg.get_node("VBox/Buttons/Fwd2").connect("pressed", Callable(self, "_on_debug_fwd2"))
		if dbg.has_node("VBox/Buttons/ToggleDir"):
			dbg.get_node("VBox/Buttons/ToggleDir").connect("pressed", Callable(self, "_on_debug_toggle_dir"))

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if visible:
			process_mode = Node.PROCESS_MODE_INHERIT
		else:
			process_mode = Node.PROCESS_MODE_DISABLED

func _start_note_spawning():
	# Common spawning logic - prevents duplication
	note_spawner.song_start_time = Time.get_ticks_msec() / 1000.0
	input_handler.song_start_time = note_spawner.song_start_time
	note_spawner.start_spawning()
	# Build command list & initialize timeline controller (Phase 1: only spawn commands)
	if not timeline_controller:
		if not has_node("TimelineController"):
			timeline_controller = load("res://Scripts/TimelineController.gd").new()
			timeline_controller.name = "TimelineController"
			add_child(timeline_controller)
		else:
			timeline_controller = $TimelineController
	# Provide context
	timeline_controller.ctx = {
		"note_spawner": note_spawner,
		"note_pool": note_pool,
		"score_manager": score_manager,
		"get_time": Callable(timeline_controller, "get_time"),
		"song_start_time": note_spawner.song_start_time
	}
	# Build spawn commands from spawner spawn_data
	var spawn_cmds = note_spawner.build_spawn_commands()
	# Song end time rough estimate: last hit_time + 5s margin
	var last_time = 0.0
	for d in note_spawner.spawn_data:
		last_time = max(last_time, d.hit_time)
	last_time += 5.0
	timeline_controller.setup(timeline_controller.ctx, spawn_cmds, last_time)
	# Attach timeline to spawner for reposition features
	note_spawner.attach_timeline(timeline_controller)
	timeline_controller.active = true

func _process(_delta):
	if song_finished:
		return
	# Keep audio synced while in forward direction (avoid constant seeks while playing normally)
	if audio_player and timeline_controller and timeline_controller.direction == 1 and audio_player.playing and not audio_player.stream_paused:
		# Drift correction: if difference exceeds small epsilon, resync
		var desired = _timeline_to_audio_time(timeline_controller.current_time)
		var diff = abs(audio_player.get_playback_position() - desired)
		if diff > 0.050: # 50 ms tolerance
			audio_player.seek(desired)
	# Detect completion: all notes spawned AND active notes empty AND (audio ended or no audio or timeline reached end)
	var spawner_done = timeline_controller != null and timeline_controller.executed_count >= timeline_controller.command_log.size()
	var no_active = note_spawner.active_notes.is_empty()
	var audio_done = (audio_player == null) or (audio_player and not audio_player.playing)
	var timeline_done = timeline_controller != null and timeline_controller.current_time >= timeline_controller.song_end_time
	if spawner_done and no_active and (audio_done or timeline_done):
		song_finished = true
		_show_results()
	# Update debug timeline labels
	if $UI.has_node("DebugTimeline") and timeline_controller:
		var dbg = $UI/DebugTimeline
		if dbg.has_node("VBox/TimeLabel"):
			dbg.get_node("VBox/TimeLabel").text = "Time: %.3f" % timeline_controller.current_time
		if dbg.has_node("VBox/DirectionLabel"):
			dbg.get_node("VBox/DirectionLabel").text = "Dir: %s" % ("+1" if timeline_controller.direction == 1 else "-1")
		if dbg.has_node("VBox/ProgressLabel"):
			dbg.get_node("VBox/ProgressLabel").text = "Exec: %d/%d" % [timeline_controller.executed_count, timeline_controller.command_log.size()]
		# Provide audio time for debugging (optional)
		if audio_player and not dbg.has_node("VBox/AudioLabel"):
			# Dynamically add only once if user wants to inspect
			var lbl = Label.new()
			lbl.name = "AudioLabel"
			dbg.get_node("VBox").add_child(lbl)
		if audio_player and dbg.has_node("VBox/AudioLabel"):
			dbg.get_node("VBox/AudioLabel").text = "Audio: %.3f" % audio_player.get_playback_position()

func _input(event):
	if not timeline_controller:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_BRACKETLEFT:
				# Scrub backward 2s
				timeline_controller.step_scrub(-2.0)
				_sync_audio_to_timeline(true)
				return
			KEY_BRACKETRIGHT:
				# Scrub forward 2s
				timeline_controller.step_scrub(2.0)
				_sync_audio_to_timeline(true)
				return
			KEY_BACKSLASH:
				# Toggle reverse direction
				var new_dir = -1 if timeline_controller.direction == 1 else 1
				timeline_controller.set_direction(new_dir)
				if audio_player:
					if new_dir == -1:
						# Entering reverse: we cannot easily play backwards with AudioStreamPlayer; mute via stream_paused.
						# Advanced reverse playback would require AudioStreamGenerator or pre-reversed buffer.
						audio_player.stream_paused = true
					else:
						# Resume forward playback at correct mapped time
						audio_player.stream_paused = false
						_sync_audio_to_timeline(false)
				return

func _get_song_time() -> float:
	if timeline_controller:
		return timeline_controller.get_time()
	# Fallback before timeline setup
	return Time.get_ticks_msec() / 1000.0 - note_spawner.song_start_time

func _show_results():
	var ini_parser = parser_factory.create_metadata_parser()
	var song_info = ini_parser.get_song_info_from_ini(chart_path)
	var results_scene = load("res://Scenes/results_screen.tscn").instantiate()
	# Collect stats
	results_scene.score = score_manager.score
	results_scene.max_combo = score_manager.max_combo
	# Total notes = all grades including misses
	var counts = score_manager.grade_counts
	results_scene.hits_per_grade = counts.duplicate()
	results_scene.total_notes = counts.perfect + counts.great + counts.good + counts.bad + counts.miss
	results_scene.song_title = song_info.get("name", "Unknown Title")
	results_scene.difficulty = instrument
	ProjectSettings.set_setting("application/run/last_chart_path", chart_path)
	ProjectSettings.set_setting("application/run/last_instrument", instrument)
	# Hide UI elements
	$UI.visible = false
	SceneSwitcher.push_scene_instance(results_scene)

func _on_note_hit(note, grade: int):
	var label = $UI/JudgementLabel
	if current_tween:
		current_tween.kill()
	label.modulate.a = 1
	var grade_str = ""
	if grade == SettingsManager.HitGrade.PERFECT:
		grade_str = "Perfect"
		label.modulate = Color.GREEN
	elif grade == SettingsManager.HitGrade.GREAT:
		grade_str = "Great"
		label.modulate = Color.YELLOW
	elif grade == SettingsManager.HitGrade.GOOD:
		grade_str = "Good"
		label.modulate = Color.ORANGE
	else:
		grade_str = "Bad"
		label.modulate = Color.RED
	label.text = grade_str
	# Use command pattern for reversible scoring (only during replay/scrubbing)
	if timeline_controller and timeline_controller.direction != 1:
		var HitNoteCommandClass = load("res://Scripts/Commands/HitNoteCommand.gd")
		var current_song_time = _get_song_time()
		var cmd = HitNoteCommandClass.new(current_song_time, grade, note.note_type, score_manager.combo)
		timeline_controller.add_command(cmd)
	else:
		# Regular gameplay scoring
		score_manager.add_hit(grade, note.note_type)
	# Fancy label animation (pass grade for size differentiation)
	if animation_director:
		animation_director.animate_judgement_label(label, grade)
	# Fade out
	current_tween = create_tween()
	current_tween.tween_property(label, "modulate:a", 0, 1.0)
	await current_tween.finished
	label.text = ""
	label.modulate.a = 1
	current_tween = null

func _on_note_miss(_note):
	var label = $UI/JudgementLabel
	if current_tween:
		current_tween.kill()
	label.modulate.a = 1
	label.text = "Miss"
	label.modulate = Color.RED
	if timeline_controller and timeline_controller.direction != 1:
		var MissNoteCommandClass = load("res://Scripts/Commands/MissNoteCommand.gd")
		var current_song_time = _get_song_time()
		var cmd = MissNoteCommandClass.new(current_song_time, score_manager.combo)
		timeline_controller.add_command(cmd)
	else:
		score_manager.add_miss()
	if animation_director:
		# Use BAD grade constant for consistent size difference
		animation_director.animate_judgement_label(label, SettingsManager.HitGrade.BAD)
	# Fade out
	current_tween = create_tween()
	current_tween.tween_property(label, "modulate:a", 0, 1.0)
	await current_tween.finished
	label.text = ""
	label.modulate.a = 1
	current_tween = null

func _on_combo_changed(combo):
	$UI/ComboLabel.text = "Combo: " + str(combo)
	if combo > 0 and animation_director:
		animation_director.animate_combo_label($UI/ComboLabel)

func _on_note_spawned(note):
	if animation_director:
		animation_director.animate_note_spawn(note)

func _on_score_changed(score):
	$UI/ScoreLabel.text = "Score: " + str(int(score))
	# Apply updated settings on score change (settings may have changed mid-game)
	if settings_manager and is_instance_valid(SettingsManager):
		# Re-sync lane keys if they were changed in settings
		input_handler.setup_lane_keys(num_lanes)

func _on_pause_button_pressed():
	# Don't allow pausing during countdown
	if countdown_active:
		return
	if not get_tree().paused:
		get_tree().paused = true
		$UI/PauseMenu.visible = true
		$UI/PauseButton.visible = false

func _get_settings_manager():
	if Engine.has_singleton("SettingsManager"):
		return Engine.get_singleton("SettingsManager")
	return null

func _on_resume():
	$UI/PauseMenu.visible = false
	$UI/PauseButton.visible = true
	var button = $UI/PauseButton
	button.text = "Resuming..."
	start_countdown(func():
		get_tree().paused = false
		button.text = "Pause"
	)

func _on_end_song():
	get_tree().paused = false
	$UI/PauseMenu.visible = false
	$UI/PauseButton.visible = true
	# Stop audio and clear active notes to end the song
	if audio_player:
		audio_player.stop()
	# Return all active notes to pool
	for note in note_spawner.active_notes:
		note_spawner.note_pool.return_note(note)
	note_spawner.active_notes.clear()
	_show_results()

func _on_song_select():
	get_tree().paused = false
	SceneSwitcher.pop_scene()

func _on_main_menu():
	get_tree().paused = false
	SceneSwitcher.pop_scene()
	SceneSwitcher.pop_scene()

# ---------------- Debug Timeline Handlers ----------------
func _on_debug_back2():
	if timeline_controller:
		timeline_controller.step_scrub(-2.0)
		_sync_audio_to_timeline(true)

func _on_debug_fwd2():
	if timeline_controller:
		timeline_controller.step_scrub(2.0)
		_sync_audio_to_timeline(true)

func _on_debug_toggle_dir():
	if timeline_controller:
		var new_dir = -1 if timeline_controller.direction == 1 else 1
		timeline_controller.set_direction(new_dir)
		if audio_player:
			# In Godot 4, AudioStreamPlayer has no pause(); use stream_paused flag.
			if new_dir == -1:
				if audio_player.playing and not audio_player.stream_paused:
					audio_player.stream_paused = true
			else:
				# Resume forward playback
				if audio_player.stream_paused:
					audio_player.stream_paused = false
				elif not audio_player.playing:
					audio_player.play()
				_sync_audio_to_timeline(false)

# ---------------- Audio / Timeline Sync Helpers ----------------
func _timeline_to_audio_time(timeline_time: float) -> float:
	# If chart offset is negative, audio started earlier at -offset
	if chart_offset < 0.0:
		return max(0.0, timeline_time - chart_offset)
	# Positive offset delays notes relative to audio start; timeline 0 aligns to audio 0
	return max(0.0, timeline_time)

func _sync_audio_to_timeline(force_seek: bool):
	if not (audio_player and timeline_controller):
		return
	if timeline_controller.direction == -1:
		# Reverse mode: keep paused (future enhancement: implement reverse generator)
		return
	var desired = _timeline_to_audio_time(timeline_controller.current_time)
	var length = 0.0
	if audio_player.stream and audio_player.stream.has_method("get_length"):
		length = audio_player.stream.get_length()
	if length > 0.0:
		desired = clamp(desired, 0.0, length - 0.01)
	var diff = abs(audio_player.get_playback_position() - desired)
	if force_seek or diff > 0.010:
		audio_player.seek(desired)
	if not audio_player.playing:
		audio_player.play()
