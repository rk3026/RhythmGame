extends ICommand
class_name SpawnNoteCommand

# Immutable snapshot of spawn data fields used to execute
var lane: int
var hit_time: float
var note_type: int
var is_sustain: bool
var sustain_length: float
var travel_time: float
var spawn_time: float # RELATIVE song time when note should begin traveling (timeline space)

# Runtime instance id for undo lookup
var _note_instance_id: int = -1
var _note_ref: WeakRef = null
var _last_removed_time: float = -1.0

func _init(p_data: Dictionary):
	lane = p_data.lane
	hit_time = p_data.hit_time
	note_type = p_data.note_type
	is_sustain = p_data.is_sustain
	sustain_length = p_data.sustain_length
	travel_time = p_data.travel_time
	spawn_time = p_data.spawn_time
	scheduled_time = spawn_time

func execute(ctx: Dictionary) -> void:
	if _note_instance_id != -1:
		return # already executed
	var spawner = ctx.get("note_spawner")
	if spawner == null:
		return
	var current_time: float = ctx.get("get_time").call()
	var note = _spawn_for_time(spawner, current_time)
	if note:
		_capture_note(note)

func undo(ctx: Dictionary) -> void:
	if _note_instance_id == -1:
		return
	var spawner = ctx.get("note_spawner")
	if spawner == null:
		return
	spawner._command_despawn_note_by_instance_id(_note_instance_id)
	_note_instance_id = -1
	_note_ref = null
	_last_removed_time = -1.0

func notify_note_removed(note, removal_time: float = -1.0):
	if _note_ref and _note_ref.get_ref() == note:
		_note_ref = null
		_note_instance_id = -1
		_last_removed_time = removal_time

func ensure_note_present(spawner, current_time: float):
	if current_time < spawn_time:
		return
	if _last_removed_time >= 0.0 and current_time >= _last_removed_time:
		return
	if _note_ref:
		var existing = _note_ref.get_ref()
		if existing and spawner.active_notes.has(existing):
			return
	var note = _spawn_for_time(spawner, current_time)
	if note:
		_capture_note(note)

func _spawn_for_time(spawner, current_time: float):
	var distance = abs(spawner.runway_begin_z)
	var initial_z = spawner.runway_begin_z
	var late_progress = current_time - spawn_time
	if travel_time > 0.0 and late_progress > 0.0:
		var speed = distance / travel_time if travel_time != 0 else 0.0
		if late_progress < travel_time:
			var fraction = late_progress / travel_time
			initial_z = spawner.runway_begin_z + distance * fraction
		else:
			var extra = late_progress - travel_time
			var forward_z = speed * extra
			if forward_z >= spawner.runway_end_z:
				return null
			initial_z = forward_z
	var note = spawner._command_spawn_note(lane, hit_time, note_type, is_sustain, sustain_length, initial_z, spawn_time, travel_time, self)
	return note

func _capture_note(note):
	_note_instance_id = note.get_instance_id()
	_note_ref = weakref(note)
	_last_removed_time = -1.0
