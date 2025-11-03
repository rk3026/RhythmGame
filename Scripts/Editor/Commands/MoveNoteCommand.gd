extends "res://Scripts/Commands/ICommand.gd"
class_name MoveNoteCommand

# Command that moves a note to a new position (tick and/or lane)
# Supports undo by storing previous position

var instrument: String
var difficulty: String
var note_id: int
var chart_data: ChartDataModel

var old_lane: int
var old_tick: int
var new_lane: int
var new_tick: int

func _init(p_chart_data: ChartDataModel, p_instrument: String, p_difficulty: String, p_note_id: int, p_new_lane: int, p_new_tick: int):
	chart_data = p_chart_data
	instrument = p_instrument
	difficulty = p_difficulty
	note_id = p_note_id
	new_lane = p_new_lane
	new_tick = p_new_tick
	
	# Store old position for undo
	var note = chart_data.get_note(instrument, difficulty, note_id)
	if note:
		old_lane = note.lane
		old_tick = note.tick
		scheduled_time = float(new_tick)

func execute(_ctx: Dictionary) -> void:
	# Modify note position in chart data model
	chart_data.modify_note(instrument, difficulty, note_id, new_tick, new_lane)
	# ChartDataModel emits note_modified signal which visual manager will handle

func undo(_ctx: Dictionary) -> void:
	# Restore old position
	chart_data.modify_note(instrument, difficulty, note_id, old_tick, old_lane)
	# ChartDataModel emits note_modified signal which visual manager will handle
