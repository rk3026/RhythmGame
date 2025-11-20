extends Node
class_name TimelineController

var command_log: Array = [] # Array of ICommand (SpawnNoteCommand initially)
var executed_count: int = 0
var current_time: float = 0.0
var direction: int = 1
var ctx: Dictionary = {}
var song_end_time: float = 0.0
var active: bool = false

func _ready() -> void:
	set_process(true)

func setup(p_ctx: Dictionary, p_commands: Array, p_song_end: float) -> void:
	ctx = p_ctx
	command_log = p_commands
	command_log.sort_custom(func(a,b): return a.scheduled_time < b.scheduled_time)
	executed_count = 0
	song_end_time = p_song_end
	current_time = 0.0
	active = true

func _process(delta: float) -> void:
	if not active:
		return
	current_time += delta * direction
	current_time = clamp(current_time, 0.0, song_end_time)
	advance_to(current_time)

func get_time() -> float:
	return current_time

func advance_to(target_time: float) -> void:
	# Forward execute
	while executed_count < command_log.size() and command_log[executed_count].scheduled_time <= target_time:
		command_log[executed_count].execute(ctx)
		executed_count += 1
	# Undo backwards
	while executed_count > 0 and command_log[executed_count - 1].scheduled_time > target_time:
		executed_count -= 1
		command_log[executed_count].undo(ctx)

func scrub_to(target_time: float) -> void:
	current_time = clamp(target_time, 0.0, song_end_time)
	advance_to(current_time)
	# After structural changes, reposition surviving active notes
	var spawner = ctx.get("note_spawner")
	if spawner:
		spawner.reposition_active_notes(current_time)

func add_command(cmd) -> void:
	# Insert maintaining order (simple append + bubble back for sparse runtime hits)
	command_log.append(cmd)
	var i = command_log.size() - 1
	while i > 0 and command_log[i - 1].scheduled_time > command_log[i].scheduled_time:
		var tmp = command_log[i]
		command_log[i] = command_log[i - 1]
		command_log[i - 1] = tmp
		i -= 1
	# If new command time <= current_time, execute immediately to keep state consistent
	if cmd.scheduled_time <= current_time:
		# Find its index post insertion for executed_count adjust
		var idx = command_log.find(cmd)
		if idx != -1:
			# Execute missing commands between executed_count and idx inclusively.
			while executed_count <= idx:
				command_log[executed_count].execute(ctx)
				executed_count += 1

func set_direction(dir: int) -> void:
	if dir == direction:
		return
	if dir != 1 and dir != -1:
		return
	direction = dir
	# For reverse playback we do not auto-undo; notes move backward under their own logic.
	# Scrub-based rewind remains via scrub_to().

func step_scrub(delta_seconds: float) -> void:
	scrub_to(current_time + delta_seconds)
