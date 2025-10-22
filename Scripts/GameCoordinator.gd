extends Node3D

class_name GameCoordinator

@onready var runway: MeshInstance3D = $Runway
@onready var input_handler = $InputHandler
@onready var score_manager = $ScoreManager
@onready var note_spawner = $NoteSpawner
@onready var note_pool = $NoteSpawner/NotePool

@export var num_lanes: int
var lanes: Array = []
var original_materials: Array = []

@export var chart_path: String
@export var instrument: String

var preloaded_data: Dictionary = {}
var current_tween = null
var song_finished: bool = false
var settings_manager
var animation_director: Node = null
var chart_offset: float = 0.0

var audio_manager
var ui_manager
var timeline_controller: Node = null
var parser_factory: ParserFactory

func _ready():
	parser_factory = load("res://Scripts/Parsers/ParserFactory.gd").new()
	
	# Create managers
	audio_manager = AudioManager.new()
	add_child(audio_manager)
	ui_manager = UIManager.new()
	add_child(ui_manager)
	
	var sections
	var resolution
	var offset
	var tempo_events
	var notes
	var parser
	
	if preloaded_data.is_empty():
		parser = parser_factory.create_parser_for_file(chart_path)
		if not parser:
			push_error("Failed to create parser for: " + chart_path)
			return
		
		sections = parser.load_chart(chart_path)
		resolution = parser.get_resolution(sections)
		offset = parser.get_offset(sections)
		chart_offset = offset
		if settings_manager:
			chart_offset += settings_manager.timing_offset
		tempo_events = parser.get_tempo_events(sections)
		notes = parser.get_notes(sections, instrument, resolution)
	else:
		sections = preloaded_data.sections
		resolution = preloaded_data.resolution
		offset = preloaded_data.offset
		chart_offset = offset
		if settings_manager:
			chart_offset += settings_manager.timing_offset
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

	# Create hit effect pool
	var hit_effect_pool = load("res://Scripts/HitEffectPool.gd").new()
	hit_effect_pool.name = "HitEffectPool"
	add_child(hit_effect_pool)

	# Animation director
	if not has_node("AnimationDirector"):
		animation_director = load("res://Scripts/animation_director.gd").new()
		animation_director.name = "AnimationDirector"
		add_child(animation_director)
	else:
		animation_director = get_node("AnimationDirector")
	
	settings_manager = _get_settings_manager()
	
	input_handler.original_materials = original_materials
	input_handler.configure(lanes, num_lanes)
	
	note_spawner.notes = notes
	note_spawner.tempo_events = tempo_events
	note_spawner.resolution = resolution
	note_spawner.offset = offset
	note_spawner.lanes = lanes
	note_spawner.note_scene = load("res://Scenes/note.tscn")
	note_spawner.note_pool = note_pool
	
	if settings_manager:
		input_handler.setup_lane_keys(num_lanes)
	
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
		audio_path = FileSystemHelper.find_audio_file(folder)
	
	audio_manager.load_audio(audio_path, offset)
	audio_manager.connect("countdown_finished", Callable(self, "_on_countdown_finished"))
	
	ui_manager.connect_pause_buttons(self)

func _get_settings_manager():
	if Engine.has_singleton("SettingsManager"):
		return Engine.get_singleton("SettingsManager")
	return null

func _on_countdown_finished():
	note_spawner.song_start_time = Time.get_ticks_msec() / 1000.0
	input_handler.song_start_time = note_spawner.song_start_time
	note_spawner.start_spawning()
	
	if not timeline_controller:
		if not has_node("TimelineController"):
			timeline_controller = load("res://Scripts/TimelineController.gd").new()
			timeline_controller.name = "TimelineController"
			add_child(timeline_controller)
		else:
			timeline_controller = $TimelineController
	
	timeline_controller.ctx = {
		"note_spawner": note_spawner,
		"note_pool": note_pool,
		"score_manager": score_manager,
		"get_time": Callable(timeline_controller, "get_time"),
		"song_start_time": note_spawner.song_start_time
	}
	var spawn_cmds = note_spawner.build_spawn_commands()
	var last_time = 0.0
	for d in note_spawner.spawn_data:
		last_time = max(last_time, d.hit_time)
	last_time += 5.0
	timeline_controller.setup(timeline_controller.ctx, spawn_cmds, last_time)
	note_spawner.attach_timeline(timeline_controller)
	timeline_controller.active = true

func _process(_delta):
	if song_finished:
		return
	audio_manager.sync_audio(_timeline_to_audio_time(timeline_controller.current_time), timeline_controller.direction)
	
	var spawner_done = timeline_controller != null and timeline_controller.executed_count >= timeline_controller.command_log.size()
	var no_active = note_spawner.active_notes.is_empty()
	var audio_done = audio_manager.is_audio_finished()
	var timeline_done = timeline_controller != null and timeline_controller.current_time >= timeline_controller.song_end_time
	if spawner_done and no_active and (audio_done or timeline_done):
		song_finished = true
		_show_results()
	
	ui_manager.update_debug_ui(timeline_controller)

func _timeline_to_audio_time(timeline_time: float) -> float:
	return timeline_time - chart_offset

func _on_combo_changed(combo):
	$UI/ComboLabel.text = "Combo: " + str(combo)
	if combo > 0 and animation_director:
		animation_director.animate_combo_label($UI/ComboLabel)

func _on_note_spawned(note):
	if animation_director:
		animation_director.animate_note_spawn(note)

func _on_score_changed(score):
	$UI/ScoreLabel.text = "Score: " + str(int(score))

func _show_results():
	var ini_parser = parser_factory.create_metadata_parser()
	var song_info = ini_parser.get_song_info_from_ini(chart_path)
	var results_scene = load("res://Scenes/results_screen.tscn").instantiate()
	results_scene.score = score_manager.score
	results_scene.max_combo = score_manager.max_combo
	var counts = score_manager.grade_counts
	results_scene.hits_per_grade = counts.duplicate()
	results_scene.total_notes = counts.perfect + counts.great + counts.good + counts.bad + counts.miss
	results_scene.song_title = song_info.get("name", "Unknown Title")
	results_scene.difficulty = instrument
	ProjectSettings.set_setting("application/run/last_chart_path", chart_path)
	ProjectSettings.set_setting("application/run/last_instrument", instrument)
	$UI.visible = false
	SceneSwitcher.push_scene_instance(results_scene)

func _on_note_hit(note, grade: int):
	var label = $UI/JudgementLabel
	if current_tween:
		current_tween.kill()
	label.modulate.a = 1
	match grade:
		SettingsManager.HitGrade.PERFECT:
			label.text = "Perfect"
			label.modulate = Color.CYAN
		SettingsManager.HitGrade.GREAT:
			label.text = "Great"
			label.modulate = Color.GREEN
		SettingsManager.HitGrade.GOOD:
			label.text = "Good"
			label.modulate = Color.YELLOW
		SettingsManager.HitGrade.BAD:
			label.text = "Bad"
			label.modulate = Color.ORANGE
		_:
			label.text = "Miss"
			label.modulate = Color.RED
	if timeline_controller and timeline_controller.direction != 1:
		if grade != SettingsManager.HitGrade.MISS:
			var HitNoteCommandClass = load("res://Scripts/Commands/HitNoteCommand.gd")
			var current_song_time = _get_song_time()
			var cmd = HitNoteCommandClass.new(current_song_time, grade, note.note_type, score_manager.combo)
			timeline_controller.add_command(cmd)
		else:
			var MissNoteCommandClass = load("res://Scripts/Commands/MissNoteCommand.gd")
			var current_song_time = _get_song_time()
			var cmd = MissNoteCommandClass.new(current_song_time, score_manager.combo)
			timeline_controller.add_command(cmd)
	else:
		if grade != SettingsManager.HitGrade.MISS:
			score_manager.add_hit(grade, note.note_type)
		else:
			score_manager.add_miss()
	if animation_director:
		animation_director.animate_judgement_label(label, grade)
	current_tween = create_tween()
	current_tween.tween_property(label, "modulate:a", 0, 1.0)
	await current_tween.finished
	label.text = ""
	label.modulate.a = 1
	current_tween = null

func _on_pause_button_pressed():
	get_tree().paused = true
	$UI/PauseMenu.visible = true
	$UI/PauseButton.visible = false

func _on_resume():
	get_tree().paused = false
	$UI/PauseMenu.visible = false
	$UI/PauseButton.visible = true

func _on_end_song():
	get_tree().paused = false
	$UI/PauseMenu.visible = false
	$UI/PauseButton.visible = true
	if audio_manager.audio_player:
		audio_manager.audio_player.stop()
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

func _get_song_time() -> float:
	return Time.get_ticks_msec() / 1000.0 - note_spawner.song_start_time

func _sync_audio_to_timeline(force: bool = false):
	if audio_manager.audio_player and timeline_controller:
		var desired = _timeline_to_audio_time(timeline_controller.current_time)
		var diff = abs(audio_manager.audio_player.get_playback_position() - desired)
		if force or diff > 0.050:
			audio_manager.audio_player.seek(desired)