extends Node

## Input Handler for Rhythm Game
## Handles player input and determines note hits/misses based on timing windows
## Spam prevention is inherent to the logic - notes are processed once per input

signal note_hit(note: Node, grade: int)

# Configuration
var lane_keys: Array = []
var original_materials: Array = []
var num_lanes: int
var lanes: Array = []
var gameplay: Node
var song_start_time: float

# Key state tracking
var key_states: Array[bool] = []
var last_hit_times: Array[float] = [] # Track last successful hit time per lane to prevent rapid re-hits

func _ready():
	gameplay = get_parent()

func configure(lanes_array: Array, lane_count: int):
	lanes = lanes_array
	num_lanes = lane_count
	setup_lane_keys(num_lanes)
	
	# Initialize last hit times for each lane
	last_hit_times = []
	for i in range(num_lanes):
		last_hit_times.append(-999.0)

func refresh_lane_keys():
	setup_lane_keys(num_lanes)

func setup_lane_keys(lanes_count: int):
	var default_keys = [KEY_D, KEY_F, KEY_J, KEY_K, KEY_L, KEY_SEMICOLON]
	
	if is_instance_valid(SettingsManager):
		lane_keys = SettingsManager.lane_keys.slice(0, lanes_count)
		print("Using SettingsManager keys: ", lane_keys)
	else:
		lane_keys = default_keys.slice(0, lanes_count)
		print("Warning: No settings available, using default keys: ", lane_keys)
	
	# Initialize key states
	key_states = []
	for i in range(lanes_count):
		key_states.append(false)

func _input(event):
	if event is InputEventKey and not event.echo:
		for i in range(lane_keys.size()):
			if event.keycode == lane_keys[i]:
				if event.pressed:
					# Key pressed - immediately check for hit
					key_states[i] = true
					light_up_zone(i, true)
					_process_lane_input(i)
				else:
					# Key released
					key_states[i] = false
					light_up_zone(i, false)

func _process(_delta: float):
	# Handle sustain scoring for held keys
	for i in range(key_states.size()):
		if key_states[i] and _has_sustain_held(i):
			gameplay.score_manager.add_sustain_score(_delta)

## Core hit detection logic - finds and judges the next hittable note in a lane
func _process_lane_input(lane_index: int):
	var current_time = _get_current_time()
	var note_spawner = gameplay.get_node("NoteSpawner")
	
	# Get timing windows from settings
	var perfect_window = SettingsManager.perfect_window if is_instance_valid(SettingsManager) else 0.025
	var great_window = SettingsManager.great_window if is_instance_valid(SettingsManager) else 0.05
	var good_window = SettingsManager.good_window if is_instance_valid(SettingsManager) else 0.1
	var miss_window = SettingsManager.miss_window if is_instance_valid(SettingsManager) else 0.7
	
	# Find the earliest unhit note in this lane that's within the miss window
	var target_note = _find_next_hittable_note(lane_index, current_time, miss_window, note_spawner)
	
	if not target_note:
		return # No note to hit
	
	# Calculate timing difference
	var time_diff = current_time - target_note.expected_hit_time
	var abs_diff = abs(time_diff)
	
	# Determine if this is a hit or miss based on timing
	if abs_diff <= good_window:
		# Within hit window - grade the hit
		var grade = _calculate_grade(abs_diff, perfect_window, great_window, good_window)
		_register_hit(target_note, grade, lane_index, current_time)
	else:
		# Outside hit window but within miss window - active miss (early)
		_register_miss(target_note, true)

## Find the next note in a lane that can be hit (earliest by expected hit time)
func _find_next_hittable_note(lane_index: int, current_time: float, miss_window: float, note_spawner: Node) -> Node:
	var lane_x = lanes[lane_index]
	var earliest_note: Node = null
	var earliest_time: float = INF
	
	for note in note_spawner.active_notes:
		# Skip invalid or already processed notes
		if not is_instance_valid(note):
			continue
		if note.was_hit or note.was_missed:
			continue
		
		# Check if note is in the correct lane
		if abs(note.position.x - lane_x) > 0.1 or note.fret != lane_index:
			continue
		
		# Check if note is within the miss window (can only hit notes ahead or slightly behind)
		var time_diff = note.expected_hit_time - current_time
		if time_diff > miss_window:
			continue # Note is too far in the future
		if time_diff < -miss_window:
			continue # Note is too far in the past (should have been passive missed already)
		
		# Track the earliest note by expected hit time
		if note.expected_hit_time < earliest_time:
			earliest_time = note.expected_hit_time
			earliest_note = note
	
	return earliest_note

## Calculate hit grade based on timing accuracy
func _calculate_grade(abs_diff: float, perfect_window: float, great_window: float, good_window: float) -> int:
	if abs_diff <= perfect_window:
		return SettingsManager.HitGrade.PERFECT if is_instance_valid(SettingsManager) else 0
	elif abs_diff <= great_window:
		return SettingsManager.HitGrade.GREAT if is_instance_valid(SettingsManager) else 1
	elif abs_diff <= good_window:
		return SettingsManager.HitGrade.GOOD if is_instance_valid(SettingsManager) else 2
	else:
		return SettingsManager.HitGrade.MISS if is_instance_valid(SettingsManager) else 3

## Register a successful hit
func _register_hit(note: Node, grade: int, lane_index: int, current_time: float):
	note.was_hit = true
	last_hit_times[lane_index] = current_time
	emit_signal("note_hit", note, grade)

## Register a miss (active or passive)
func _register_miss(note: Node, _is_active: bool):
	note.was_missed = true
	note.visible = false
	if note.tail_instance:
		note.tail_instance.visible = false
	note.emit_signal("note_miss", note)

## Check if a sustain note is currently being held in this lane
func _has_sustain_held(lane_index: int) -> bool:
	var lane_x = lanes[lane_index]
	var note_spawner = gameplay.get_node("NoteSpawner")
	
	for note in note_spawner.active_notes:
		if is_instance_valid(note) and note.was_hit and note.is_sustain:
			if abs(note.position.x - lane_x) < 0.1 and note.fret == lane_index:
				return true
	
	return false

## Get current song time
func _get_current_time() -> float:
	if gameplay and gameplay.has_method("_get_song_time"):
		return gameplay._get_song_time()
	return Time.get_ticks_msec() / 1000.0 - song_start_time

## Light up hit zone visual feedback
func light_up_zone(lane_index: int, is_pressed: bool):
	var zone = gameplay.get_node("HitZone" + str(lane_index))
	if zone:
		if is_pressed:
			var mat = original_materials[lane_index].duplicate()
			mat.albedo_color = mat.albedo_color.lightened(0.5)
			zone.material_override = mat
		else:
			zone.material_override = original_materials[lane_index]
		
		if gameplay.has_node("AnimationDirector"):
			gameplay.get_node("AnimationDirector").animate_lane_press(zone, is_pressed)
