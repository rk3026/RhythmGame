extends VBoxContainer
class_name EditorToolbar
## Editor Toolbar Component
## Manages editing tools, snap settings, and grid toggle

signal tool_selected(tool_type: ToolType)
signal snap_changed(snap_division: int)
signal grid_toggled(enabled: bool)
signal view_mode_changed(mode: ViewMode)

enum ViewMode {
	CANVAS_2D,
	RUNWAY_3D,
	SPLIT
}

enum ToolType {
	NOTE,
	HOPO,
	TAP,
	SELECT,
	BPM,
	EVENT
}

@onready var note_button: Button = $ToolButtonGroup/NoteButton
@onready var hopo_button: Button = $ToolButtonGroup/HOPOButton
@onready var tap_button: Button = $ToolButtonGroup/TapButton
@onready var select_button: Button = $ToolButtonGroup/SelectButton
@onready var bpm_button: Button = $ToolButtonGroup/BPMButton
@onready var event_button: Button = $ToolButtonGroup/EventButton
@onready var snap_selector: OptionButton = $SnapGroup/SnapSelector
@onready var view_2d_button: Button = $ViewGroup/View2DButton
@onready var view_3d_button: Button = $ViewGroup/View3DButton
@onready var view_split_button: Button = $ViewGroup/ViewSplitButton
@onready var grid_toggle: CheckButton = $GridToggle

var current_tool: ToolType = ToolType.NOTE
var current_snap: int = 16  # Default to 1/16 notes
var current_view_mode: ViewMode = ViewMode.CANVAS_2D

# Snap divisions matching Moonscraper
const SNAP_DIVISIONS = [4, 8, 12, 16, 24, 32, 48, 64, 192]
const SNAP_LABELS = ["1/4", "1/8", "1/12", "1/16", "1/24", "1/32", "1/48", "1/64", "1/192"]

# Color coding for snap lines (matches Moonscraper)
const SNAP_COLORS = {
	4: Color(1.0, 0.0, 0.0, 1.0),      # Red - quarter notes
	8: Color(0.0, 0.0, 1.0, 1.0),      # Blue - eighth notes
	12: Color(1.0, 0.0, 1.0, 1.0),     # Magenta - triplets
	16: Color(1.0, 1.0, 0.0, 1.0),     # Yellow - sixteenth notes
	24: Color(0.0, 1.0, 1.0, 1.0),     # Cyan
	32: Color(1.0, 0.5, 0.0, 1.0),     # Orange
	48: Color(0.5, 1.0, 0.5, 1.0),     # Light green
	64: Color(0.8, 0.8, 0.8, 1.0),     # Light gray
	192: Color(0.6, 0.6, 0.6, 1.0)     # Gray
}

func _ready():
	_setup_snap_options()
	_connect_signals()
	_select_tool(ToolType.NOTE)

func _setup_snap_options():
	snap_selector.clear()
	for i in SNAP_LABELS.size():
		snap_selector.add_item(SNAP_LABELS[i])
	snap_selector.selected = 3  # Default to 1/16

func _connect_signals():
	note_button.pressed.connect(_on_note_button_pressed)
	hopo_button.pressed.connect(_on_hopo_button_pressed)
	tap_button.pressed.connect(_on_tap_button_pressed)
	select_button.pressed.connect(_on_select_button_pressed)
	bpm_button.pressed.connect(_on_bpm_button_pressed)
	event_button.pressed.connect(_on_event_button_pressed)
	snap_selector.item_selected.connect(_on_snap_selected)
	view_2d_button.pressed.connect(_on_view_2d_pressed)
	view_3d_button.pressed.connect(_on_view_3d_pressed)
	view_split_button.pressed.connect(_on_view_split_pressed)
	grid_toggle.toggled.connect(_on_grid_toggled)

func _on_note_button_pressed():
	_select_tool(ToolType.NOTE)

func _on_hopo_button_pressed():
	_select_tool(ToolType.HOPO)

func _on_tap_button_pressed():
	_select_tool(ToolType.TAP)

func _on_select_button_pressed():
	_select_tool(ToolType.SELECT)

func _on_bpm_button_pressed():
	_select_tool(ToolType.BPM)

func _on_event_button_pressed():
	_select_tool(ToolType.EVENT)

func _select_tool(tool: ToolType):
	current_tool = tool
	_update_button_states()
	tool_selected.emit(tool)

func _update_button_states():
	note_button.button_pressed = current_tool == ToolType.NOTE
	hopo_button.button_pressed = current_tool == ToolType.HOPO
	tap_button.button_pressed = current_tool == ToolType.TAP
	select_button.button_pressed = current_tool == ToolType.SELECT
	bpm_button.button_pressed = current_tool == ToolType.BPM
	event_button.button_pressed = current_tool == ToolType.EVENT

func _on_snap_selected(index: int):
	current_snap = SNAP_DIVISIONS[index]
	snap_changed.emit(current_snap)

func _on_grid_toggled(enabled: bool):
	grid_toggled.emit(enabled)

func get_current_tool() -> ToolType:
	return current_tool

func get_current_snap() -> int:
	return current_snap

func get_snap_color(snap_division: int) -> Color:
	if snap_division in SNAP_COLORS:
		return SNAP_COLORS[snap_division]
	return Color.WHITE

func is_grid_enabled() -> bool:
	return grid_toggle.button_pressed

func set_snap_division(division: int):
	var index = SNAP_DIVISIONS.find(division)
	if index != -1:
		snap_selector.selected = index
		current_snap = division

func increase_snap():
	var current_index = SNAP_DIVISIONS.find(current_snap)
	if current_index < SNAP_DIVISIONS.size() - 1:
		set_snap_division(SNAP_DIVISIONS[current_index + 1])
		snap_changed.emit(current_snap)

func decrease_snap():
	var current_index = SNAP_DIVISIONS.find(current_snap)
	if current_index > 0:
		set_snap_division(SNAP_DIVISIONS[current_index - 1])
		snap_changed.emit(current_snap)

func _on_view_2d_pressed():
	_set_view_mode(ViewMode.CANVAS_2D)

func _on_view_3d_pressed():
	_set_view_mode(ViewMode.RUNWAY_3D)

func _on_view_split_pressed():
	_set_view_mode(ViewMode.SPLIT)

func _set_view_mode(mode: ViewMode):
	current_view_mode = mode
	_update_view_button_states()
	view_mode_changed.emit(mode)

func _update_view_button_states():
	view_2d_button.button_pressed = current_view_mode == ViewMode.CANVAS_2D
	view_3d_button.button_pressed = current_view_mode == ViewMode.RUNWAY_3D
	view_split_button.button_pressed = current_view_mode == ViewMode.SPLIT

func get_current_view_mode() -> ViewMode:
	return current_view_mode
