extends HBoxContainer
class_name EditorStatusBar
## Editor Status Bar Component
## Displays current editor state information

@onready var time_display: Label = $TimeDisplay
@onready var bpm_display: Label = $BPMDisplay
@onready var snap_display: Label = $SnapDisplay
@onready var notes_display: Label = $NotesDisplay
@onready var modified_indicator: Label = $ModifiedIndicator

func _ready():
	update_time(0.0)
	update_bpm(120.0)
	update_snap(16)
	update_note_count(0)
	set_modified(false)

func update_time(time: float):
	var minutes = int(time / 60.0)
	var seconds = int(time) % 60
	var milliseconds = int((time - int(time)) * 100)
	time_display.text = "Time: %02d:%02d.%02d" % [minutes, seconds, milliseconds]

func update_bpm(bpm: float):
	bpm_display.text = "BPM: %.2f" % bpm

func update_snap(snap_division: int):
	var snap_label = "1/%d" % snap_division
	snap_display.text = "Snap: %s" % snap_label

func update_note_count(count: int):
	notes_display.text = "Notes: %d" % count

func set_modified(is_modified: bool):
	if is_modified:
		modified_indicator.text = "[Modified]"
		modified_indicator.modulate = Color(1.0, 0.5, 0.0)  # Orange
	else:
		modified_indicator.text = "[Saved]"
		modified_indicator.modulate = Color(0.5, 1.0, 0.5)  # Green

func update_selection(selection_count: int):
	if selection_count > 0:
		notes_display.text = "Notes: %d (%d selected)" % [0, selection_count]
	else:
		update_note_count(0)
