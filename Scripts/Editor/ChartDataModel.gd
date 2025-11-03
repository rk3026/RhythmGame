extends RefCounted
class_name ChartDataModel
## Chart Data Model
## Manages all chart data including notes, BPM changes, events, and metadata

signal data_changed()
signal note_added(note: Dictionary)
signal note_removed(note_id: int)
signal note_modified(note_id: int)
signal bpm_changed(tick: int, bpm: float)

# Metadata
var metadata: Dictionary = {
	"title": "",
	"artist": "",
	"album": "",
	"charter": "",
	"year": 2024,
	"audio_file": "",
	"offset": 0.0
}

# Chart data organized by instrument and difficulty
# Structure: charts[instrument][difficulty] = ChartDifficulty
var charts: Dictionary = {}

# Timing data (shared across all charts)
var bpm_changes: Array[Dictionary] = []  # {tick: int, bpm: float}
var time_signatures: Array[Dictionary] = []  # {tick: int, numerator: int, denominator: int}

# Global settings
var resolution: int = 192  # Ticks per beat (standard for .chart format)

# Note ID counter
var _next_note_id: int = 0

class ChartDifficulty:
	var notes: Array[Dictionary] = []  # {id: int, tick: int, lane: int, type: int, length: int}
	var events: Array[Dictionary] = []  # {tick: int, event_type: String, data: Dictionary}
	
	func add_note(note: Dictionary) -> void:
		notes.append(note)
		notes.sort_custom(_compare_notes)
	
	func remove_note(note_id: int) -> bool:
		for i in range(notes.size()):
			if notes[i].get("id") == note_id:
				notes.remove_at(i)
				return true
		return false
	
	func get_note(note_id: int) -> Dictionary:
		for note in notes:
			if note.get("id") == note_id:
				return note
		return {}
	
	func get_notes_in_range(start_tick: int, end_tick: int) -> Array[Dictionary]:
		var result: Array[Dictionary] = []
		for note in notes:
			var tick = note.get("tick", 0)
			if tick >= start_tick and tick <= end_tick:
				result.append(note)
		return result
	
	static func _compare_notes(a: Dictionary, b: Dictionary) -> bool:
		var tick_a = a.get("tick", 0)
		var tick_b = b.get("tick", 0)
		if tick_a != tick_b:
			return tick_a < tick_b
		return a.get("lane", 0) < b.get("lane", 0)

func _init():
	# Initialize with default BPM
	bpm_changes.append({"tick": 0, "bpm": 120.0})
	time_signatures.append({"tick": 0, "numerator": 4, "denominator": 4})

func create_chart(instrument: String, difficulty: String) -> void:
	if instrument not in charts:
		charts[instrument] = {}
	if difficulty not in charts[instrument]:
		charts[instrument][difficulty] = ChartDifficulty.new()
		data_changed.emit()

func get_chart(instrument: String, difficulty: String) -> ChartDifficulty:
	if instrument in charts and difficulty in charts[instrument]:
		return charts[instrument][difficulty]
	return null

func has_chart(instrument: String, difficulty: String) -> bool:
	return instrument in charts and difficulty in charts[instrument]

func add_note(instrument: String, difficulty: String, lane: int, tick: int, note_type: int = 0, length: int = 0) -> int:
	var chart = get_chart(instrument, difficulty)
	if not chart:
		create_chart(instrument, difficulty)
		chart = get_chart(instrument, difficulty)
	
	var note_id = _next_note_id
	_next_note_id += 1
	
	var note = {
		"id": note_id,
		"tick": tick,
		"lane": lane,
		"type": note_type,  # 0 = normal, 1 = HOPO, 2 = tap
		"length": length     # 0 for regular notes, > 0 for sustains
	}
	
	chart.add_note(note)
	note_added.emit(note)
	data_changed.emit()
	return note_id

func remove_note(instrument: String, difficulty: String, note_id: int) -> bool:
	var chart = get_chart(instrument, difficulty)
	if chart and chart.remove_note(note_id):
		note_removed.emit(note_id)
		data_changed.emit()
		return true
	return false

func modify_note(instrument: String, difficulty: String, note_id: int, new_tick: int = -1, new_lane: int = -1, new_type: int = -1) -> bool:
	var chart = get_chart(instrument, difficulty)
	if not chart:
		return false
	
	var note = chart.get_note(note_id)
	if note.is_empty():
		return false
	
	if new_tick >= 0:
		note["tick"] = new_tick
	if new_lane >= 0:
		note["lane"] = new_lane
	if new_type >= 0:
		note["type"] = new_type
	
	# Re-sort notes after modification
	chart.notes.sort_custom(ChartDifficulty._compare_notes)
	note_modified.emit(note_id)
	data_changed.emit()
	return true

func add_bpm_change(tick: int, bpm: float) -> void:
	# Check if BPM change already exists at this tick
	for i in range(bpm_changes.size()):
		if bpm_changes[i]["tick"] == tick:
			bpm_changes[i]["bpm"] = bpm
			bpm_changed.emit(tick, bpm)
			data_changed.emit()
			return
	
	bpm_changes.append({"tick": tick, "bpm": bpm})
	bpm_changes.sort_custom(func(a, b): return a["tick"] < b["tick"])
	bpm_changed.emit(tick, bpm)
	data_changed.emit()

func get_bpm_at_tick(tick: int) -> float:
	var current_bpm = 120.0
	for bpm_change in bpm_changes:
		if bpm_change["tick"] <= tick:
			current_bpm = bpm_change["bpm"]
		else:
			break
	return current_bpm

func tick_to_time(tick: int) -> float:
	var time = 0.0
	var current_tick = 0
	
	for i in range(bpm_changes.size()):
		var bpm_change = bpm_changes[i]
		var next_tick = bpm_change["tick"]
		
		if tick <= next_tick:
			# Calculate time for remaining ticks at current BPM
			var bpm = bpm_changes[i - 1]["bpm"] if i > 0 else bpm_change["bpm"]
			var delta_ticks = tick - current_tick
			time += (delta_ticks / float(resolution)) * (60.0 / bpm)
			return time
		
		# Calculate time up to this BPM change
		if i > 0:
			var prev_bpm = bpm_changes[i - 1]["bpm"]
			var delta_ticks = next_tick - current_tick
			time += (delta_ticks / float(resolution)) * (60.0 / prev_bpm)
		
		current_tick = next_tick
	
	# Handle ticks after last BPM change
	var last_bpm = bpm_changes[-1]["bpm"]
	var remaining_ticks = tick - current_tick
	time += (remaining_ticks / float(resolution)) * (60.0 / last_bpm)
	return time

func time_to_tick(time: float) -> int:
	var current_time = 0.0
	var current_tick = 0
	
	for i in range(bpm_changes.size()):
		var bpm_change = bpm_changes[i]
		var bpm = bpm_change["bpm"]
		
		if i < bpm_changes.size() - 1:
			var next_bpm_tick = bpm_changes[i + 1]["tick"]
			var delta_ticks = next_bpm_tick - current_tick
			var delta_time = (delta_ticks / float(resolution)) * (60.0 / bpm)
			
			if current_time + delta_time >= time:
				# Target time is in this section
				var remaining_time = time - current_time
				var ticks = (remaining_time / (60.0 / bpm)) * float(resolution)
				return int(current_tick + ticks)
			
			current_time += delta_time
			current_tick = next_bpm_tick
		else:
			# After last BPM change
			var remaining_time = time - current_time
			var ticks = (remaining_time / (60.0 / bpm)) * float(resolution)
			return int(current_tick + ticks)
	
	return 0

func set_metadata(key: String, value: Variant) -> void:
	if key in metadata:
		metadata[key] = value
		data_changed.emit()

func get_metadata(key: String) -> Variant:
	return metadata.get(key, null)

func get_all_metadata() -> Dictionary:
	return metadata.duplicate()

func clear() -> void:
	charts.clear()
	bpm_changes.clear()
	time_signatures.clear()
	metadata = {
		"title": "",
		"artist": "",
		"album": "",
		"charter": "",
		"year": 2024,
		"audio_file": "",
		"offset": 0.0
	}
	bpm_changes.append({"tick": 0, "bpm": 120.0})
	time_signatures.append({"tick": 0, "numerator": 4, "denominator": 4})
	_next_note_id = 0
	data_changed.emit()

func get_note_count(instrument: String, difficulty: String) -> int:
	var chart = get_chart(instrument, difficulty)
	return chart.notes.size() if chart else 0

func get_total_note_count() -> int:
	var total = 0
	for instrument in charts:
		for difficulty in charts[instrument]:
			total += charts[instrument][difficulty].notes.size()
	return total
