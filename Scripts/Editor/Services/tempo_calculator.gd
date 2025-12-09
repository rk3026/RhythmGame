class_name TempoCalculator
extends RefCounted

## TempoCalculator - Service for converting between time and tick positions
## Uses tempo map (BPM changes) to accurately calculate note positions

# Converts time (seconds) to tick position using tempo map
static func time_to_tick(time: float, tempo_events: Array, resolution: int, offset: float = 0.0) -> int:
	var adjusted_time = time - offset
	if adjusted_time <= 0.0:
		return 0
	
	if tempo_events.is_empty():
		# Default to 120 BPM if no tempo events
		var bpm = 120.0
		var seconds_per_beat = 60.0 / bpm
		var seconds_per_tick = seconds_per_beat / float(resolution)
		return int(adjusted_time / seconds_per_tick)
	
	var current_tick: int = 0
	var current_time: float = 0.0
	
	for i in range(tempo_events.size()):
		var event = tempo_events[i]
		var next_event_time: float = INF
		
		if i + 1 < tempo_events.size():
			next_event_time = tempo_events[i + 1].get("time", INF)
		
		var bpm = event.get("bpm", 120.0)
		var seconds_per_beat = 60.0 / bpm
		var seconds_per_tick = seconds_per_beat / float(resolution)
		
		if adjusted_time <= next_event_time:
			var time_in_section = adjusted_time - current_time
			var ticks_in_section = int(time_in_section / seconds_per_tick)
			return current_tick + ticks_in_section
		else:
			var time_in_section = next_event_time - current_time
			var ticks_in_section = int(time_in_section / seconds_per_tick)
			current_tick += ticks_in_section
			current_time = next_event_time
	
	# If we get here, time is beyond last tempo event
	var last_event = tempo_events[tempo_events.size() - 1]
	var bpm = last_event.get("bpm", 120.0)
	var seconds_per_beat = 60.0 / bpm
	var seconds_per_tick = seconds_per_beat / float(resolution)
	var last_event_time = last_event.get("time", 0.0)
	var time_beyond = adjusted_time - last_event_time
	var last_event_tick = last_event.get("tick", 0)
	return last_event_tick + int(time_beyond / seconds_per_tick)

# Converts tick position to time (seconds) using tempo map
static func tick_to_time(tick: int, tempo_events: Array, resolution: int, offset: float = 0.0) -> float:
	if tick <= 0:
		return offset
	
	if tempo_events.is_empty():
		# Default to 120 BPM if no tempo events
		var bpm = 120.0
		var seconds_per_beat = 60.0 / bpm
		var seconds_per_tick = seconds_per_beat / float(resolution)
		return (tick * seconds_per_tick) + offset
	
	var current_tick: int = 0
	var current_time: float = 0.0
	
	for i in range(tempo_events.size()):
		var event = tempo_events[i]
		var event_tick = event.get("tick", 0)
		var next_event_tick: int = 999999999
		
		if i + 1 < tempo_events.size():
			next_event_tick = tempo_events[i + 1].get("tick", 999999999)
		
		var bpm = event.get("bpm", 120.0)
		var seconds_per_beat = 60.0 / bpm
		var seconds_per_tick = seconds_per_beat / float(resolution)
		
		if tick <= next_event_tick:
			var ticks_in_section = tick - event_tick
			return current_time + (ticks_in_section * seconds_per_tick) + offset
		else:
			var ticks_in_section = next_event_tick - event_tick
			current_time += ticks_in_section * seconds_per_tick
	
	# If we get here, tick is beyond last tempo event
	var last_event = tempo_events[tempo_events.size() - 1]
	var bpm = last_event.get("bpm", 120.0)
	var seconds_per_beat = 60.0 / bpm
	var seconds_per_tick = seconds_per_beat / float(resolution)
	var last_event_tick = last_event.get("tick", 0)
	var ticks_beyond = tick - last_event_tick
	var last_event_time = last_event.get("time", 0.0)
	return last_event_time + (ticks_beyond * seconds_per_tick) + offset

# Snaps a tick to the nearest grid division
static func snap_tick_to_grid(tick: int, snap_division: int, resolution: int, time_signatures: Array = []) -> int:
	# If no time signatures, default to 4/4
	if time_signatures.is_empty():
		time_signatures = [{"tick": 0, "numerator": 4, "denominator": 4}]
	
	# Find the relevant time signature for this tick
	var ts = time_signatures[0]
	for sig in time_signatures:
		if sig.get("tick", 0) <= tick:
			ts = sig
		else:
			break
	
	# Calculate ticks per beat and measure
	var ticks_per_beat = resolution
	var numerator = ts.get("numerator", 4)
	var ticks_per_measure = ticks_per_beat * numerator
	
	# Calculate snap grid size
	# snap_division is like 16 for 1/16 notes
	# snap_division = 4 means 1/4 notes (one per beat)
	# snap_division = 8 means 1/8 notes (two per beat)
	# snap_division = 16 means 1/16 notes (four per beat)
	var subdivisions_per_beat = snap_division / 4  # 16/4 = 4 snaps per beat
	var tick_gap = ticks_per_beat / subdivisions_per_beat
	
	# Ensure tick_gap is an integer to match beat line positions exactly
	tick_gap = int(tick_gap)
	if tick_gap < 1:
		tick_gap = 1
	
	# Find offset from time signature start
	var tick_offset_from_ts = tick - ts.get("tick", 0)
	
	# Snap to nearest grid line using integer division for exact alignment
	var snapped_offset = roundi(float(tick_offset_from_ts) / float(tick_gap)) * tick_gap
	
	return ts.get("tick", 0) + snapped_offset

# Helper function: Calculate ticks between two time points at a given BPM
static func time_diff_to_ticks(time_delta: float, bpm: float, resolution: int) -> int:
	var seconds_per_beat = 60.0 / bpm
	var seconds_per_tick = seconds_per_beat / float(resolution)
	return int(time_delta / seconds_per_tick)

# Helper function: Calculate time difference for a number of ticks at a given BPM
static func ticks_to_time_diff(ticks: int, bpm: float, resolution: int) -> float:
	var seconds_per_beat = 60.0 / bpm
	var seconds_per_tick = seconds_per_beat / float(resolution)
	return ticks * seconds_per_tick

# Calculate the current BPM at a given tick position
static func get_bpm_at_tick(tick: int, tempo_events: Array) -> float:
	if tempo_events.is_empty():
		return 120.0
	
	var current_bpm = tempo_events[0].get("bpm", 120.0)
	for event in tempo_events:
		if event.get("tick", 0) <= tick:
			current_bpm = event.get("bpm", 120.0)
		else:
			break
	
	return current_bpm

# Calculate the current BPM at a given time position
static func get_bpm_at_time(time: float, tempo_events: Array) -> float:
	if tempo_events.is_empty():
		return 120.0
	
	var current_bpm = tempo_events[0].get("bpm", 120.0)
	for event in tempo_events:
		if event.get("time", 0.0) <= time:
			current_bpm = event.get("bpm", 120.0)
		else:
			break
	
	return current_bpm

# Recalculate time values for all tempo events based on their tick positions
static func recalculate_tempo_event_times(tempo_events: Array, resolution: int) -> Array:
	if tempo_events.is_empty():
		return []
	
	var result = []
	var current_time = 0.0
	
	for i in range(tempo_events.size()):
		var event = tempo_events[i].duplicate(true)
		
		if i == 0:
			event["time"] = 0.0
		else:
			var prev_event = result[i - 1]
			var tick_delta = event.get("tick", 0) - prev_event.get("tick", 0)
			var bpm = prev_event.get("bpm", 120.0)
			var time_delta = ticks_to_time_diff(tick_delta, bpm, resolution)
			event["time"] = prev_event.get("time", 0.0) + time_delta
		
		result.append(event)
	
	return result
