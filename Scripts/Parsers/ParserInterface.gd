extends RefCounted
class_name ParserInterface

# Pure virtual methods that all parsers must implement
func load_chart(_path: String) -> Dictionary:
	push_error("load_chart() must be implemented by subclass")
	return {}

func get_resolution(_sections: Dictionary) -> int:
	push_error("get_resolution() must be implemented by subclass")
	return 192

func get_offset(_sections: Dictionary) -> float:
	push_error("get_offset() must be implemented by subclass")
	return 0.0

func get_music_stream(_sections: Dictionary) -> String:
	push_error("get_music_stream() must be implemented by subclass")
	return ""

func get_tempo_events(_sections: Dictionary) -> Array:
	push_error("get_tempo_events() must be implemented by subclass")
	return []

func get_notes(_sections: Dictionary, _instrument: String, _resolution: int) -> Array:
	push_error("get_notes() must be implemented by subclass")
	return []

func get_note_times(_notes: Array, _resolution: int, _tempo_events: Array) -> Array:
	push_error("get_note_times() must be implemented by subclass")
	return []

func get_available_instruments(_sections: Dictionary) -> Dictionary:
	push_error("get_available_instruments() must be implemented by subclass")
	return {}

# Helper method for converting ticks to time
func ticks_to_time(tick: int, resolution: int, tempo_events: Array) -> float:
	var current_bpm = 120.0
	var last_tick = 0
	var accumulated_time = 0.0
	var event_index = 0
	
	while event_index < tempo_events.size() and tempo_events[event_index].tick <= tick:
		var event = tempo_events[event_index]
		var ticks_elapsed = event.tick - last_tick
		var time_elapsed = (ticks_elapsed / float(resolution)) * (60.0 / current_bpm)
		accumulated_time += time_elapsed
		current_bpm = event.bpm
		last_tick = event.tick
		event_index += 1
	
	var ticks_from_last = tick - last_tick
	var time_from_last = (ticks_from_last / float(resolution)) * (60.0 / current_bpm)
	return accumulated_time + time_from_last