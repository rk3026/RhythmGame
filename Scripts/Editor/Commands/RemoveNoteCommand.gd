extends "res://Scripts/Commands/ICommand.gd"
class_name RemoveNoteCommand

# Command that removes a note from the chart data model
# Stores note data to support undo

var instrument: String
var difficulty: String
var note_id: int
var chart_data: ChartDataModel

# Stored note data for undo
var stored_lane: int
var stored_tick: int
var stored_note_type: int
var stored_length: int

func _init(p_chart_data: ChartDataModel, p_instrument: String, p_difficulty: String, p_note_id: int):
	chart_data = p_chart_data
	instrument = p_instrument
	difficulty = p_difficulty
	note_id = p_note_id
	
	# Store note data before removal for undo
	var note = chart_data.get_note(instrument, difficulty, note_id)
	if note:
		stored_lane = note.lane
		stored_tick = note.tick
		stored_note_type = note.note_type
		stored_length = note.length
		scheduled_time = float(stored_tick)

func execute(_ctx: Dictionary) -> void:
	# Remove note from chart data model
	chart_data.remove_note(instrument, difficulty, note_id)
	# ChartDataModel emits note_removed signal which visual manager will handle

func undo(_ctx: Dictionary) -> void:
	# Re-add note with stored data (will get new ID)
	note_id = chart_data.add_note(instrument, difficulty, stored_lane, stored_tick, stored_note_type, stored_length)
	# ChartDataModel emits note_added signal which visual manager will handle
