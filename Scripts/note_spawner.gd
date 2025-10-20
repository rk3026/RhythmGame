extends Node

signal note_spawned(note)

var lanes: Array = []
var note_scene: PackedScene
var active_notes: Array = []
var notes: Array
var tempo_events: Array
var resolution: int
var offset: float
var song_start_time: float
var runway_begin_z: float = -25.0 # in the distance
var runway_end_z: float = 20.0 # towards player, where the cam cannot see anymore

var spawn_data = []  # Array of {spawn_time, lane, hit_time, note_type, is_sustain, sustain_length, travel_time}
var spawn_index = 0
var spawning_started = false
var note_pool
var timeline_controller: Node = null

func _ready():
	pass  # Wait for start signal

func start_spawning():
	# Guard against multiple calls that would create duplicate notes
	if spawning_started:
		print("Warning: start_spawning() called multiple times, ignoring duplicate call")
		return
	
	var hit_times = get_note_times(notes, resolution, tempo_events)
	
	# Get note speed from SettingsManager
	var note_speed = 20.0
	if is_instance_valid(SettingsManager):
		note_speed = SettingsManager.note_speed
	
	print("Note spawner using note speed: ", note_speed)
	
	for i in notes.size():
		var hit_time = hit_times[i] + offset
		var distance = abs(runway_begin_z)  # Distance from spawn point to hit line (negative z toward 0)
		var travel_time = distance / note_speed
		var spawn_time = hit_time - travel_time  # World time when note should appear at runway_begin_z
		var lane = notes[i].fret  # Use fret as lane index
		var note_type = get_note_type(notes[i])
		var is_sustain = notes[i].length > 0
		var sustain_length = 0.0
		if is_sustain:
			sustain_length = (notes[i].length / resolution) * (60.0 / get_current_bpm(tempo_events, notes[i].pos))
		# Deduplicate spawn entries: if an existing spawn has same lane & hit_time within tiny epsilon, skip
		add_spawn_entry(spawn_time, lane, hit_time, note_type, is_sustain, sustain_length, travel_time)
	
	spawn_data.sort_custom(func(a, b): return a.spawn_time < b.spawn_time)
	spawning_started = true

func add_spawn_entry(spawn_time: float, lane: int, hit_time: float, note_type: NoteType.Type, is_sustain: bool, sustain_length: float, travel_time: float):
	for existing in spawn_data:
		if existing.lane == lane and abs(existing.hit_time - hit_time) < 0.0005:
			# Merge sustains
			if is_sustain and not existing.is_sustain:
				existing.is_sustain = true
				existing.sustain_length = sustain_length
			elif is_sustain and existing.is_sustain and sustain_length > existing.sustain_length:
				existing.sustain_length = sustain_length
			return  # Don't add new
	# Add new
	spawn_data.append({spawn_time = spawn_time, lane = lane, hit_time = hit_time, note_type = note_type, is_sustain = is_sustain, sustain_length = sustain_length, travel_time = travel_time})

func get_note_type(note: Dictionary) -> int:
	if note.fret == 5:  # Open notes (fret 7 already converted to 5 by parser)
		return NoteType.Type.OPEN
	elif note.is_tap:
		return NoteType.Type.TAP
	elif note.is_hopo:
		return NoteType.Type.HOPO
	else:
		return NoteType.Type.REGULAR

func get_note_times(notes: Array, resolution: int, tempo_events: Array) -> Array:
	var times = []
	var current_bpm = 120.0
	var last_tick = 0
	var accumulated_time = 0.0
	var event_index = 0
	for note in notes:
		var note_tick = note.pos
		while event_index < tempo_events.size() and tempo_events[event_index].tick <= note_tick:
			var event = tempo_events[event_index]
			var ticks_elapsed = event.tick - last_tick
			var time_elapsed = (ticks_elapsed / resolution) * (60.0 / current_bpm)
			accumulated_time += time_elapsed
			current_bpm = event.bpm
			last_tick = event.tick
			event_index += 1
		var ticks_from_last = note_tick - last_tick
		var time_from_last = (ticks_from_last / resolution) * (60.0 / current_bpm)
		var hit_time = accumulated_time + time_from_last
		times.append(hit_time)
	return times

func get_current_bpm(tempo_events: Array, tick: int) -> float:
	var current_bpm = 120.0
	for event in tempo_events:
		if event.tick <= tick:
			current_bpm = event.bpm
		else:
			break
	return current_bpm

func _process(_delta: float):
	# No longer responsible for forward spawning (handled by TimelineController)
	if not spawning_started:
		return
	# Update reverse flag on active notes if timeline present
	if timeline_controller:
		_ensure_spawned_notes(timeline_controller.current_time)
		var is_reverse = timeline_controller.direction == -1
		for n in active_notes:
			if is_instance_valid(n):
				n.reverse_mode = is_reverse
	_cleanup_pass()

func spawn_note_for_lane(lane_index: int, hit_time: float, note_type: int, is_sustain: bool, sustain_length: float, initial_z: float = runway_begin_z, relative_spawn_time: float = -1.0):
	var note = note_pool.get_note()
	add_child(note)
	var lane_x = lanes[lane_index]
	note.position = Vector3(lane_x, 0, initial_z)
	
	# Get note speed from SettingsManager
	var note_speed = 20.0
	if is_instance_valid(SettingsManager):
		note_speed = SettingsManager.note_speed

	# Keep the conceptual spawn time aligned with schedule (used only for animations / diagnostics)
	if relative_spawn_time >= 0.0:
		note.spawn_time = relative_spawn_time
	else:
		# Derive relative from wall clock
		note.spawn_time = Time.get_ticks_msec() / 1000.0 - song_start_time
	note.expected_hit_time = hit_time
	note.note_type = note_type
	note.fret = lane_index
	note.is_sustain = is_sustain
	note.sustain_length = sustain_length
	note.travel_time = abs(runway_begin_z) / max(1.0, note_speed)
	note.spawn_command = null
	# Ensure signals (pool keeps instances, so only connect if missing)
	if not note.is_connected("note_miss", Callable(self, "_on_note_miss")):
		note.connect("note_miss", Callable(self, "_on_note_miss"))
	if not note.is_connected("note_finished", Callable(self, "_on_note_finished")):
		note.connect("note_finished", Callable(self, "_on_note_finished"))
	# Signals are now connected once in the pool
	# Provide effect pool reference for sustain grinding BEFORE visuals so tail picks it up
	var gameplay = get_parent()
	if gameplay and gameplay.has_node("HitEffectPool"):
		note.hit_effect_pool = gameplay.get_node("HitEffectPool")
	active_notes.append(note)
	note.update_visuals()
	# Emit spawn event for animation system
	emit_signal("note_spawned", note)

func _on_note_hit(note, _grade):
	if not note.is_sustain:
		var removal_time = timeline_controller.current_time if timeline_controller else note.expected_hit_time
		_release_note(note, removal_time)
		active_notes.erase(note)
		note_pool.return_note(note)
	_spawn_hit_effect(note, false)
	# For sustains, keep the note until the sustain ends

func _on_note_finished(note):
	var removal_time = timeline_controller.current_time if timeline_controller else note.expected_hit_time + note.sustain_length
	_release_note(note, removal_time)
	active_notes.erase(note)
	note_pool.return_note(note)
	_spawn_hit_effect(note, true)

func _on_note_miss(note):
	# Miss effect: dull gray or red flash
	var gameplay = get_parent()
	if not gameplay or not gameplay.has_node("HitEffectPool"):
		return
	var pool = gameplay.get_node("HitEffectPool")
	var eff = pool.get_effect()
	gameplay.add_child(eff)
	eff.global_transform.origin = Vector3(note.position.x, 0.2, 0.0)
	if eff.has_method("play"):
		eff.play(Color(0.3,0.3,0.3), 0.9)

func _spawn_hit_effect(note, sustain_end: bool):
	var gameplay = get_parent()
	if not gameplay or not gameplay.has_node("HitEffectPool"):
		return
	var pool = gameplay.get_node("HitEffectPool")
	if not pool.has_method("get_effect"):
		return
	var eff = pool.get_effect()
	gameplay.add_child(eff)
	# Position at hit line (assumes z ~ 0) with lane x
	eff.global_transform.origin = Vector3(note.position.x, 0.2, 0.0)
	# Color mapping by fret / type
	var col = Color.WHITE
	var palette = [Color.GREEN, Color.RED, Color.YELLOW, Color.BLUE, Color.ORANGE]
	if note.note_type == 3: # OPEN / STAR
		col = Color(1, 0.9, 0.3)
	elif note.fret < palette.size():
		col = palette[note.fret]
	# Differentiate sustain release
	if sustain_end:
		col = col.lightened(0.4)
	# Removed note-type based scaling to keep effects consistent size
	if eff.has_method("play"):
		eff.play(col, 1.0)

# ---------------- Command Pattern Helpers ----------------
func build_spawn_commands() -> Array:
	var cmds: Array = []
	var SpawnNoteCommandClass = load("res://Scripts/Commands/SpawnNoteCommand.gd")
	for d in spawn_data:
		var cmd = SpawnNoteCommandClass.new(d)
		cmds.append(cmd)
	return cmds

func attach_timeline(timeline):
	timeline_controller = timeline


func _release_note(note, removal_time: float = -1.0):
	if note.spawn_command and note.spawn_command.has_method("notify_note_removed"):
		note.spawn_command.notify_note_removed(note, removal_time)
	note.spawn_command = null

func _command_spawn_note(lane_index: int, hit_time: float, note_type: int, is_sustain: bool, sustain_length: float, initial_z: float, relative_spawn_time: float, travel_time: float, command_ref = null):
	# Wrapper used by SpawnNoteCommand
	var note = note_pool.get_note()
	add_child(note)
	var lane_x = lanes[lane_index]
	note.position = Vector3(lane_x, 0, initial_z)
	var note_speed = 20.0
	if is_instance_valid(SettingsManager):
		note_speed = SettingsManager.note_speed
	# Keep spawn_time in RELATIVE song time (used by reposition logic)
	note.spawn_time = relative_spawn_time
	note.expected_hit_time = hit_time
	note.note_type = note_type
	note.fret = lane_index
	note.is_sustain = is_sustain
	note.sustain_length = sustain_length
	note.travel_time = travel_time
	note.spawn_command = command_ref
	if not note.is_connected("note_miss", Callable(self, "_on_note_miss")):
		note.connect("note_miss", Callable(self, "_on_note_miss"))
	if not note.is_connected("note_finished", Callable(self, "_on_note_finished")):
		note.connect("note_finished", Callable(self, "_on_note_finished"))
	active_notes.append(note)
	# Set effect pool BEFORE visuals so the created tail can emit sustain particles
	var gameplay = get_parent()
	if gameplay and gameplay.has_node("HitEffectPool"):
		note.hit_effect_pool = gameplay.get_node("HitEffectPool")
	note.update_visuals()
	emit_signal("note_spawned", note)
	return note

func _command_despawn_note_by_instance_id(instance_id: int):
	for i in range(active_notes.size() - 1, -1, -1):
		var n = active_notes[i]
		if is_instance_valid(n) and n.get_instance_id() == instance_id:
			var removal_time = timeline_controller.current_time if timeline_controller else -1.0
			_release_note(n, removal_time)
			active_notes.remove_at(i)
			note_pool.return_note(n)
			return

func reposition_active_notes(current_time: float):
	var distance = abs(runway_begin_z)
	for note in active_notes:
		if not is_instance_valid(note):
			continue
		if note.travel_time <= 0:
			continue
		var rel = current_time - note.spawn_time
		if rel <= 0:
			note.position.z = runway_begin_z
			continue
		var speed = distance / note.travel_time if note.travel_time > 0 else 0.0
		if rel < note.travel_time:
			var fraction = rel / note.travel_time
			note.position.z = runway_begin_z + distance * fraction
		else:
			var extra = rel - note.travel_time
			var forward_z = min(runway_end_z, speed * extra)
			note.position.z = forward_z

func _cleanup_pass():
	for i in range(active_notes.size() - 1, -1, -1):
		var note = active_notes[i]
		if not is_instance_valid(note):
			active_notes.remove_at(i)
			continue
		var beyond_end = note.position.z > runway_end_z
		var rewound_past_spawn = note.position.z < runway_begin_z - 0.5 and timeline_controller and timeline_controller.direction == -1
		if rewound_past_spawn:
			# In reverse playback, if we rewind past original spawn location we despawn (implicit undo analog)
			var removal_time = timeline_controller.current_time if timeline_controller else note.spawn_time
			_release_note(note, removal_time)
			active_notes.remove_at(i)
			note_pool.return_note(note)
			continue
		if (not note.is_sustain and beyond_end and timeline_controller and timeline_controller.direction == 1) or (not note.visible):
			var removal_time_forward = timeline_controller.current_time if timeline_controller else note.spawn_time + note.travel_time
			_release_note(note, removal_time_forward)
			active_notes.remove_at(i)
			note_pool.return_note(note)

func _ensure_spawned_notes(current_time: float):
	if not timeline_controller:
		return
	for i in range(min(timeline_controller.executed_count, timeline_controller.command_log.size())):
		var cmd = timeline_controller.command_log[i]
		if cmd is SpawnNoteCommand:
			cmd.ensure_note_present(self, current_time)
