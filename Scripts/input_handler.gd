extends Node

signal note_hit(note: Node, grade: int)

var lane_keys: Array = []
var original_materials: Array = []
var num_lanes: int
var lanes: Array = []
var gameplay: Node
var song_start_time: float
var key_states: Array[bool] = []
var processed_frame_id: int = -1
var key_changed_this_frame: bool = false

func _ready():
	# Defer lane/key initialization until gameplay passes proper lane data.
	# (Child _ready runs before parent gameplay._ready, so lane count & lanes aren't ready yet.)
	gameplay = get_parent()
	# gameplay will call configure() once lanes are built.
	pass

func configure(lanes_array: Array, lane_count: int):
	lanes = lanes_array
	num_lanes = lane_count
	setup_lane_keys(num_lanes)

func refresh_lane_keys():
	# Refresh keys from SettingsManager (useful when settings change mid-game)
	setup_lane_keys(num_lanes)

func setup_lane_keys(lanes_count: int):
	# Fallback default keys if SettingsManager singleton not available yet
	var default_keys = [KEY_D, KEY_F, KEY_J, KEY_K, KEY_L, KEY_SEMICOLON]
	
	# Try to use SettingsManager first (user's custom keys), then defaults
	if is_instance_valid(SettingsManager):
		lane_keys = SettingsManager.lane_keys.slice(0, lanes_count)
		print("Using SettingsManager keys: ", lane_keys)
	else:
		lane_keys = default_keys.slice(0, lanes_count)
		print("Warning: No settings available, using default keys: ", lane_keys)
	
	# Initialize key states array
	key_states = []
	for i in range(lanes_count):
		key_states.append(false)

func _input(event):
	if event is InputEventKey and not event.echo:
		for i in range(lane_keys.size()):
			if event.keycode == lane_keys[i]:
				if event.pressed:
					# Key pressed
					key_states[i] = true
					light_up_zone(i, true)
					key_changed_this_frame = true
					# Defer actual hit processing to _process so multiple simultaneous keys are considered together
				else:
					# Key released
					key_states[i] = false
					light_up_zone(i, false)
					key_changed_this_frame = true

func _process(_delta: float):
	# Only process hits if keys changed this frame or we have sustained notes
	var frame_id = Engine.get_frames_drawn()
	if frame_id == processed_frame_id:
		return
	processed_frame_id = frame_id

	# Process hits for currently pressed keys (only when key state changed for efficiency)
	if key_changed_this_frame:
		for i in range(key_states.size()):
			if key_states[i]:
				check_hit(i)
		key_changed_this_frame = false
	
	# Add sustain scoring for held keys (this runs every frame but is lightweight)
	for i in range(key_states.size()):
		if key_states[i] and has_sustain_held(i):
			gameplay.score_manager.add_sustain_score(_delta)

func has_sustain_held(lane_index: int) -> bool:
	var lane_x = lanes[lane_index]
	var note_spawner = gameplay.get_node("NoteSpawner")
	for note in note_spawner.active_notes:
		if is_instance_valid(note) and note.was_hit and note.is_sustain and abs(note.position.x - lane_x) < 0.1:
			return true
	return false

func check_hit(lane_index: int):
	# Fallback timing windows if GameConfig not available
	var perfect_window = 0.025
	var great_window = 0.05 
	var good_window = 0.1
	var hit_grade_perfect = 0
	var hit_grade_great = 1
	var hit_grade_good = 2
	
	# Use SettingsManager if available
	if is_instance_valid(SettingsManager):
		perfect_window = SettingsManager.perfect_window
		great_window = SettingsManager.great_window
		good_window = SettingsManager.good_window
		hit_grade_perfect = SettingsManager.HitGrade.PERFECT
		hit_grade_great = SettingsManager.HitGrade.GREAT
		hit_grade_good = SettingsManager.HitGrade.GOOD
	
	# Collect candidate notes in this lane within the largest timing window
	var lane_x = lanes[lane_index]
	var current_time = Time.get_ticks_msec() / 1000.0 - song_start_time
	if gameplay and gameplay.has_method("_get_song_time"):
		current_time = gameplay._get_song_time()
	var note_spawner = gameplay.get_node("NoteSpawner")
	var best_note: Node = null
	var best_diff: float = 9999.0
	for note in note_spawner.active_notes:
		if not is_instance_valid(note) or note.was_hit:
			continue
		if abs(note.position.x - lane_x) < 0.1:
			var diff = current_time - note.expected_hit_time
			if diff > 0:  # Early press - miss
				continue
			var abs_diff = -diff  # Make positive for grading
			if abs_diff <= good_window and abs_diff < best_diff:
				best_diff = abs_diff
				best_note = note

	if best_note:
		var grade = hit_grade_good
		if best_diff <= perfect_window:
			grade = hit_grade_perfect
		elif best_diff <= great_window:
			grade = hit_grade_great
		emit_signal("note_hit", best_note, grade)
		best_note.was_hit = true

func light_up_zone(lane_index: int, is_pressed: bool):
	var zone = gameplay.get_node("HitZone" + str(lane_index))
	if zone:
		if is_pressed:
			# Light up the zone
			var mat = original_materials[lane_index].duplicate()
			mat.albedo_color = mat.albedo_color.lightened(0.5)
			zone.material_override = mat
		else:
			# Restore original material
			zone.material_override = original_materials[lane_index]
		# Animate pulse via AnimationDirector if present
		if gameplay.has_node("AnimationDirector"):
			gameplay.get_node("AnimationDirector").animate_lane_press(zone, is_pressed)
