extends Node3D

@onready var runway: MeshInstance3D = $Runway
@onready var note_scene = preload("res://Scenes/note.tscn")
@onready var input_handler = $InputHandler
@onready var score_manager = $ScoreManager
@onready var note_spawner = $NoteSpawner
@onready var note_pool = $NoteSpawner/NotePool
@onready var vfx_manager = $GameplayVFXManager
var hit_effect_pool: Node
var timeline_controller = null

# Audio playback (supports both single-stream and MIDI multi-track)
var midi_track_manager: Node = null  # For MIDI songs with multiple audio tracks
var is_midi_song: bool = false  # Flag to determine which audio system to use

# Lane color mapping (matching fret colors)
const LANE_COLORS = [
	Color.GREEN,    # Lane 0
	Color.RED,      # Lane 1
	Color.YELLOW,   # Lane 2
	Color.BLUE,     # Lane 3
	Color.ORANGE    # Lane 4
]

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

func start_countdown(callback: Callable):
	countdown_active = true
	var label = $UI/JudgementLabel
	for i in range(3, 0, -1):
		label.text = str(i)
		label.modulate = Color.WHITE
		label.modulate.a = 1
		# Play countdown tick sound
		if SoundEffectManager:
			SoundEffectManager.play_sfx("countdown_tick", SoundEffectManager.SoundCategory.COUNTDOWN)
		await get_tree().create_timer(1.0).timeout
	label.text = "Go!"
	# Play countdown go sound
	if SoundEffectManager:
		SoundEffectManager.play_sfx("countdown_go", SoundEffectManager.SoundCategory.COUNTDOWN)
	await get_tree().create_timer(0.5).timeout
	label.text = ""
	countdown_active = false
	callback.call()

var chart_loading_service: ChartLoadingService

func _ready():
	# Load chart data
	var chart_data: ChartLoadingService.ChartData
	
	if preloaded_data.is_empty():
		# Load chart using service
		chart_loading_service = ChartLoadingService.new()
		chart_data = chart_loading_service.load_chart_data_sync(chart_path, instrument)
		if not chart_data:
			push_error("Failed to load chart: " + chart_path)
			return
	else:
		# Use preloaded data
		chart_data = ChartLoadingService.chart_data_from_preloaded(preloaded_data)
		if not chart_data:
			push_error("Invalid preloaded data")
			return
	
	# Extract chart data
	var _sections = chart_data.sections  # Available if needed for future features
	var resolution = chart_data.resolution
	var offset = chart_data.offset
	chart_offset = offset
	var tempo_events = chart_data.tempo_events
	var notes = chart_data.notes
	var _parser = chart_data.parser  # Available if needed for future features
	
	# Calculate number of lanes needed
	num_lanes = ChartLoadingService.calculate_num_lanes(notes)
	
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
	
	# Initialize VFX manager with camera and environment references
	if vfx_manager:
		vfx_manager.initialize($Camera3D, $WorldEnvironment, num_lanes, lanes)
	
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
	
	# Preload sound effects for gameplay
	if SoundEffectManager:
		SoundEffectManager.preload_category(SoundEffectManager.SoundCategory.HIT_PERFECT)
		SoundEffectManager.preload_category(SoundEffectManager.SoundCategory.COMBO_MILESTONE)
		SoundEffectManager.preload_category(SoundEffectManager.SoundCategory.COUNTDOWN)
	
	# Setup audio playback (MIDI multi-track or single-stream)
	is_midi_song = chart_data.is_midi
	var folder = chart_path.get_base_dir()
	
	print("Gameplay: is_midi_song=%s, audio_tracks.size=%d" % [is_midi_song, chart_data.audio_tracks.size()])
	
	if is_midi_song and chart_data.audio_tracks.size() > 0:
		# MIDI song with multiple audio tracks
		print("Gameplay: Loading MIDI multi-track audio system...")
		var MidiTrackManagerClass = load("res://Scripts/Audio/MidiTrackManager.gd")
		midi_track_manager = MidiTrackManagerClass.new()
		add_child(midi_track_manager)
		var success = midi_track_manager.load_tracks(chart_data.audio_tracks)
		print("Gameplay: MidiTrackManager loaded successfully: %s" % success)
		
		# Start countdown before playing
		start_countdown(func():
			if offset < 0:
				midi_track_manager.play(-offset)
			else:
				midi_track_manager.play(0.0)
			_start_note_spawning()
		)
	else:
		# Regular song with single audio stream
		var music_stream = chart_data.music_stream
		var audio_path = ""
		if music_stream:
			audio_path = folder + "/" + music_stream
		else:
			# Scan for any .ogg file in the folder
			audio_path = FileSystemHelper.find_audio_file(folder)
		
		if audio_path and FileAccess.file_exists(audio_path):
			audio_player = AudioStreamPlayer.new()
			audio_player.stream = load(audio_path)
			audio_player.bus = "Music"  # Route to Music bus for proper volume control
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
	if timeline_controller and timeline_controller.direction == 1:
		if is_midi_song and midi_track_manager:
			# MIDI multi-track sync (MidiTrackManager handles internal sync automatically)
			if midi_track_manager.is_playing:
				var desired = _timeline_to_audio_time(timeline_controller.current_time)
				var diff = abs(midi_track_manager.get_playback_position() - desired)
				if diff > 0.050: # 50 ms tolerance
					midi_track_manager.seek(desired)
		elif audio_player and audio_player.playing and not audio_player.stream_paused:
			# Single-stream sync
			var desired = _timeline_to_audio_time(timeline_controller.current_time)
			var diff = abs(audio_player.get_playback_position() - desired)
			if diff > 0.050: # 50 ms tolerance
				audio_player.seek(desired)
	
	# Detect completion: all notes spawned AND active notes empty AND (audio ended or no audio or timeline reached end)
	var spawner_done = timeline_controller != null and timeline_controller.executed_count >= timeline_controller.command_log.size()
	var no_active = note_spawner.active_notes.is_empty()
	var audio_done = false
	if is_midi_song and midi_track_manager:
		audio_done = not midi_track_manager.is_playing
	elif audio_player:
		audio_done = not audio_player.playing
	else:
		audio_done = true  # No audio system loaded
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
		var has_audio = (is_midi_song and midi_track_manager) or audio_player
		if has_audio and not dbg.has_node("VBox/AudioLabel"):
			# Dynamically add only once if user wants to inspect
			var lbl = Label.new()
			lbl.name = "AudioLabel"
			dbg.get_node("VBox").add_child(lbl)
		if has_audio and dbg.has_node("VBox/AudioLabel"):
			var audio_pos = 0.0
			if is_midi_song and midi_track_manager:
				audio_pos = midi_track_manager.get_playback_position()
			elif audio_player:
				audio_pos = audio_player.get_playback_position()
			dbg.get_node("VBox/AudioLabel").text = "Audio: %.3f" % audio_pos

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
				if new_dir == -1:
					# Entering reverse: pause audio (cannot play backwards easily)
					if is_midi_song and midi_track_manager:
						midi_track_manager.pause()
					elif audio_player:
						audio_player.stream_paused = true
				else:
					# Resume forward playback at correct mapped time
					if is_midi_song and midi_track_manager:
						_sync_audio_to_timeline(false)
					elif audio_player:
						audio_player.stream_paused = false
						_sync_audio_to_timeline(false)
				return

func _get_song_time() -> float:
	if timeline_controller:
		return timeline_controller.get_time()
	# Fallback before timeline setup
	return Time.get_ticks_msec() / 1000.0 - note_spawner.song_start_time

func _show_results():
	# Get song info for results screen
	if not chart_loading_service:
		chart_loading_service = ChartLoadingService.new()
	var ini_parser = chart_loading_service.parser_factory.create_metadata_parser()
	var song_info = ini_parser.get_song_info_from_ini(chart_path)
	var results_scene = load("res://Scenes/results_screen.tscn").instantiate()
	# Collect stats
	results_scene.score = score_manager.score
	results_scene.max_combo = score_manager.max_combo
	# Total notes = all grades including misses
	var counts = score_manager.grade_counts
	results_scene.hits_per_grade = counts.duplicate()
	results_scene.total_notes = counts.perfect + counts.great + counts.good + counts.miss
	results_scene.song_title = song_info.get("name", "Unknown Title")
	results_scene.difficulty = instrument
	# NEW: Pass chart path and instrument for score history tracking
	results_scene.chart_path = chart_path
	results_scene.instrument = instrument
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
	elif grade == SettingsManager.HitGrade.MISS:
		grade_str = "Miss"
		label.modulate = Color.RED
	else:
		push_error("Unknown grade: " + str(grade))
		grade_str = "Miss"
		label.modulate = Color.RED
	label.text = grade_str
	
	# Play hit sound effect based on grade
	if SoundEffectManager:
		match grade:
			SettingsManager.HitGrade.PERFECT:
				SoundEffectManager.play_sfx_variation("perfect", 2, SoundEffectManager.SoundCategory.HIT_PERFECT)
			SettingsManager.HitGrade.GREAT:
				SoundEffectManager.play_sfx("great", SoundEffectManager.SoundCategory.HIT_GREAT)
			SettingsManager.HitGrade.GOOD:
				SoundEffectManager.play_sfx("good", SoundEffectManager.SoundCategory.HIT_GOOD)
			SettingsManager.HitGrade.MISS:
				SoundEffectManager.play_sfx("bad", SoundEffectManager.SoundCategory.HIT_BAD)
	
	# Trigger VFX effects for the note hit
	if vfx_manager and note.fret >= 0 and note.fret < LANE_COLORS.size():
		var lane_color = LANE_COLORS[note.fret]
		# Convert grade int to string for VFX manager
		var grade_string = ""
		match grade:
			SettingsManager.HitGrade.PERFECT:
				grade_string = "perfect"
			SettingsManager.HitGrade.GREAT:
				grade_string = "great"
			SettingsManager.HitGrade.GOOD:
				grade_string = "good"
			_:
				grade_string = "miss"
		vfx_manager.trigger_note_hit(note.fret, grade_string, lane_color)
	
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
	
	# Play miss sound effect
	if SoundEffectManager:
		SoundEffectManager.play_sfx("miss", SoundEffectManager.SoundCategory.MISS)
	label.modulate = Color.RED
	if timeline_controller and timeline_controller.direction != 1:
		var MissNoteCommandClass = load("res://Scripts/Commands/MissNoteCommand.gd")
		var current_song_time = _get_song_time()
		var cmd = MissNoteCommandClass.new(current_song_time, score_manager.combo)
		timeline_controller.add_command(cmd)
	else:
		score_manager.add_miss()
	if animation_director:
		# Use MISS grade constant for consistent size difference
		animation_director.animate_judgement_label(label, SettingsManager.HitGrade.MISS)
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
	
	# Trigger VFX for combo milestones
	if vfx_manager and combo > 0 and combo % 50 == 0:
		# Use golden color for combo milestones
		vfx_manager.trigger_combo_milestone(combo, Color(1.0, 0.85, 0.0))

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
	if is_midi_song and midi_track_manager:
		midi_track_manager.stop()
	elif audio_player:
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
	if not timeline_controller:
		return
	if timeline_controller.direction == -1:
		# Reverse mode: keep paused (future enhancement: implement reverse generator)
		return
	
	var desired = _timeline_to_audio_time(timeline_controller.current_time)
	
	if is_midi_song and midi_track_manager:
		# MIDI multi-track sync
		var diff = abs(midi_track_manager.get_playback_position() - desired)
		if force_seek or diff > 0.010:
			midi_track_manager.seek(desired)
		if not midi_track_manager.is_playing:
			midi_track_manager.resume()
	elif audio_player:
		# Single-stream sync
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
