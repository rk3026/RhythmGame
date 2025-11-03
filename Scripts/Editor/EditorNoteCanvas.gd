extends Control
class_name EditorNoteCanvas

# 2D vertical scrolling note highway for chart editing
# Similar to Moonscraper's main charting interface

signal note_clicked(note_id: int, button_index: int)
signal canvas_clicked(lane: int, tick: int, button_index: int)
signal notes_selected(note_ids: Array)
signal notes_moved(note_ids: Array, offset_lane: int, offset_tick: int, original_positions: Dictionary)

const LANE_COUNT = 5
const LANE_COLORS = [
	Color(0.0, 1.0, 0.0),  # Lane 0 - Green
	Color(1.0, 0.0, 0.0),  # Lane 1 - Red
	Color(1.0, 1.0, 0.0),  # Lane 2 - Yellow
	Color(0.0, 0.0, 1.0),  # Lane 3 - Blue
	Color(1.0, 0.5, 0.0),  # Lane 4 - Orange
]

# Visual settings
var pixels_per_tick: float = 0.1  # Zoom level
var scroll_offset: int = 0  # Current tick at bottom of view
var lane_width: float = 80.0
var grid_line_color = Color(0.3, 0.3, 0.3, 0.5)
var beat_line_color = Color(0.5, 0.5, 0.5, 0.8)
var measure_line_color = Color(0.7, 0.7, 0.7, 1.0)

# Snap settings
var snap_division: int = 16  # From EditorToolbar
var resolution: int = 192  # Ticks per beat (from ChartDataModel)

# Data references
var chart_data: ChartDataModel
var current_instrument: String = "Single"
var current_difficulty: String = "Expert"

# Visual note cache
var visual_notes: Dictionary = {}  # note_id -> visual properties

# Selection state
var selected_notes: Array[int] = []  # Array of selected note IDs
var is_dragging_selection: bool = false
var selection_start_pos: Vector2 = Vector2.ZERO
var selection_rect: Rect2 = Rect2()

# Note dragging state
var is_dragging_notes: bool = false
var drag_start_pos: Vector2 = Vector2.ZERO
var drag_start_tick: int = 0
var drag_offset_lane: int = 0
var drag_offset_tick: int = 0
var original_note_positions: Dictionary = {}  # note_id -> {lane, tick}

# Playback visualization
var playback_tick: int = 0
var is_playing: bool = false

func _ready():
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL

func set_chart_data(data: ChartDataModel) -> void:
	"""Connect to chart data and listen for changes"""
	chart_data = data
	
	# Connect to chart data signals
	if chart_data:
		chart_data.note_added.connect(_on_note_added)
		chart_data.note_removed.connect(_on_note_removed)
		chart_data.note_modified.connect(_on_note_modified)
		chart_data.bpm_changed.connect(_on_bpm_changed)
	
	_rebuild_visual_notes()
	queue_redraw()

func set_instrument_difficulty(instrument: String, difficulty: String) -> void:
	"""Change the current instrument/difficulty being edited"""
	current_instrument = instrument
	current_difficulty = difficulty
	_rebuild_visual_notes()
	queue_redraw()

func set_snap_division(division: int) -> void:
	"""Update snap division for grid display"""
	snap_division = division
	queue_redraw()

func set_zoom(zoom: float) -> void:
	"""Set zoom level (pixels per tick)"""
	pixels_per_tick = clamp(zoom, 0.01, 1.0)
	queue_redraw()

func scroll_to_tick(tick: int) -> void:
	"""Scroll to show a specific tick"""
	scroll_offset = tick
	queue_redraw()

func get_visible_tick_range() -> Vector2i:
	"""Returns the min and max ticks visible on screen"""
	var height = size.y
	var ticks_on_screen = int(height / pixels_per_tick)
	return Vector2i(scroll_offset, scroll_offset + ticks_on_screen)

func tick_to_y(tick: int) -> float:
	"""Convert tick position to Y coordinate on canvas"""
	# Bottom of canvas is scroll_offset, top is scroll_offset + visible_ticks
	var relative_tick = tick - scroll_offset
	return size.y - (relative_tick * pixels_per_tick)

func y_to_tick(y: float) -> int:
	"""Convert Y coordinate to tick position"""
	var relative_tick = (size.y - y) / pixels_per_tick
	return scroll_offset + int(relative_tick)

func x_to_lane(x: float) -> int:
	"""Convert X coordinate to lane number"""
	var canvas_width = size.x
	var total_lane_width = lane_width * LANE_COUNT
	var offset_x = (canvas_width - total_lane_width) / 2.0
	
	var lane = int((x - offset_x) / lane_width)
	return clamp(lane, 0, LANE_COUNT - 1)

func lane_to_x(lane: int) -> float:
	"""Convert lane number to X coordinate (center of lane)"""
	var canvas_width = size.x
	var total_lane_width = lane_width * LANE_COUNT
	var offset_x = (canvas_width - total_lane_width) / 2.0
	
	return offset_x + (lane * lane_width) + (lane_width / 2.0)

func snap_tick_to_grid(tick: int) -> int:
	"""Snap a tick value to the current snap division"""
	var ticks_per_snap = int(resolution / snap_division)
	return int(round(float(tick) / ticks_per_snap)) * ticks_per_snap

func _draw():
	"""Custom drawing for the note highway"""
	_draw_grid()
	_draw_notes()
	_draw_selection_box()
	_draw_playback_line()

func _draw_grid():
	"""Draw the grid lines and lane separators"""
	var visible_range = get_visible_tick_range()
	var canvas_width = size.x
	var total_lane_width = lane_width * LANE_COUNT
	var offset_x = (canvas_width - total_lane_width) / 2.0
	
	# Draw lane backgrounds
	for i in LANE_COUNT:
		var lane_x = offset_x + i * lane_width
		var lane_rect = Rect2(lane_x, 0, lane_width, size.y)
		var lane_color = LANE_COLORS[i]
		lane_color.a = 0.1
		draw_rect(lane_rect, lane_color)
	
	# Draw vertical lane separators
	for i in range(LANE_COUNT + 1):
		var lane_x = offset_x + i * lane_width
		draw_line(Vector2(lane_x, 0), Vector2(lane_x, size.y), grid_line_color, 1.0)
	
	# Draw horizontal grid lines
	var ticks_per_beat = resolution
	var ticks_per_measure = ticks_per_beat * 4  # Assuming 4/4 time
	var ticks_per_snap = int(resolution / snap_division)
	
	# Start from a measure boundary
	var start_tick = (visible_range.x / ticks_per_measure) * ticks_per_measure
	var end_tick = visible_range.y
	
	for tick in range(start_tick, end_tick + 1, ticks_per_snap):
		var y = tick_to_y(tick)
		if y < 0 or y > size.y:
			continue
		
		var line_color = grid_line_color
		var line_width = 1.0
		
		# Measure lines
		if tick % ticks_per_measure == 0:
			line_color = measure_line_color
			line_width = 2.0
		# Beat lines
		elif tick % ticks_per_beat == 0:
			line_color = beat_line_color
			line_width = 1.5
		
		draw_line(
			Vector2(offset_x, y),
			Vector2(offset_x + total_lane_width, y),
			line_color,
			line_width
		)

func _draw_notes():
	"""Draw all visible notes"""
	if not chart_data:
		return
	
	var visible_range = get_visible_tick_range()
	
	for note_id in visual_notes:
		var note_data = visual_notes[note_id]
		var tick = note_data.tick
		
		# Skip if note is outside visible range
		if tick < visible_range.x or tick > visible_range.y:
			continue
		
		var lane = note_data.lane
		var length = note_data.length
		
		var y = tick_to_y(tick)
		var x = lane_to_x(lane)
		
		# Draw note
		var note_size = Vector2(lane_width * 0.8, 8.0)
		var note_rect = Rect2(x - note_size.x / 2.0, y - note_size.y / 2.0, note_size.x, note_size.y)
		
		var note_color = LANE_COLORS[lane]
		var is_selected = note_id in selected_notes
		
		# Brighten selected notes
		if is_selected:
			note_color = note_color.lightened(0.3)
		
		draw_rect(note_rect, note_color)
		
		# Different outline for selected notes
		if is_selected:
			draw_rect(note_rect, Color.YELLOW, false, 3.0)  # Thick yellow outline
		else:
			draw_rect(note_rect, Color.WHITE, false, 2.0)  # Normal outline
		
		# Draw sustain tail if applicable
		if length > 0:
			var tail_end_y = tick_to_y(tick + length)
			var tail_height = abs(y - tail_end_y)
			var tail_rect = Rect2(x - 4.0, tail_end_y, 8.0, tail_height)
			var tail_color = note_color * 0.6
			draw_rect(tail_rect, tail_color)
			if is_selected:
				draw_rect(tail_rect, Color.YELLOW, false, 2.0)

func _draw_playback_line():
	"""Draw the current playback position"""
	if is_playing:
		var y = tick_to_y(playback_tick)
		if y >= 0 and y <= size.y:
			draw_line(
				Vector2(0, y),
				Vector2(size.x, y),
				Color.WHITE,
				3.0
			)

func update_playback_position(tick: int, playing: bool) -> void:
	"""Update playback visualization"""
	playback_tick = tick
	is_playing = playing
	queue_redraw()

func _rebuild_visual_notes() -> void:
	"""Rebuild the visual note cache from chart data"""
	visual_notes.clear()
	
	if not chart_data:
		return
	
	var chart = chart_data.get_chart(current_instrument, current_difficulty)
	if not chart:
		return
	
	var notes = chart.get_all_notes()
	for note in notes:
		visual_notes[note.id] = {
			"tick": note.tick,
			"lane": note.lane,
			"note_type": note.note_type,
			"length": note.length
		}

func _on_note_added(instrument: String, difficulty: String, note_id: int) -> void:
	"""Handle note added to chart data"""
	if instrument != current_instrument or difficulty != current_difficulty:
		return
	
	var note = chart_data.get_note(instrument, difficulty, note_id)
	if note:
		visual_notes[note_id] = {
			"tick": note.tick,
			"lane": note.lane,
			"note_type": note.note_type,
			"length": note.length
		}
		queue_redraw()

func _on_note_removed(instrument: String, difficulty: String, note_id: int) -> void:
	"""Handle note removed from chart data"""
	if instrument != current_instrument or difficulty != current_difficulty:
		return
	
	visual_notes.erase(note_id)
	queue_redraw()

func _on_note_modified(instrument: String, difficulty: String, note_id: int) -> void:
	"""Handle note modified in chart data"""
	if instrument != current_instrument or difficulty != current_difficulty:
		return
	
	var note = chart_data.get_note(instrument, difficulty, note_id)
	if note:
		visual_notes[note_id] = {
			"tick": note.tick,
			"lane": note.lane,
			"note_type": note.note_type,
			"length": note.length
		}
		queue_redraw()

func _on_bpm_changed() -> void:
	"""Handle BPM changes"""
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	"""Handle mouse input for note placement and selection"""
	if event is InputEventMouseButton:
		if event.pressed:
			var lane = x_to_lane(event.position.x)
			var tick = y_to_tick(event.position.y)
			var snapped_tick = snap_tick_to_grid(tick)
			
			# Check if clicking on an existing note
			var clicked_note_id = _get_note_at_position(lane, snapped_tick)
			
			if clicked_note_id != -1:
				# Clicking on a note
				if event.button_index == MOUSE_BUTTON_LEFT:
					if event.ctrl_pressed:
						# Ctrl+Click: Toggle selection
						toggle_note_selection(clicked_note_id)
					elif clicked_note_id in selected_notes:
						# Click on already selected note: start drag
						_start_note_drag(event.position, lane, snapped_tick)
					else:
						# Click on unselected note: select only this one
						select_note(clicked_note_id, false)
						_start_note_drag(event.position, lane, snapped_tick)
				else:
					# Other button (right-click)
					note_clicked.emit(clicked_note_id, event.button_index)
			else:
				# Clicking on empty space
				if event.button_index == MOUSE_BUTTON_LEFT:
					if event.shift_pressed:
						# Shift+Click: Start selection box
						_start_selection_box(event.position)
					else:
						# Regular click: Clear selection and emit canvas click
						clear_selection()
						canvas_clicked.emit(lane, snapped_tick, event.button_index)
				else:
					canvas_clicked.emit(lane, snapped_tick, event.button_index)
		else:
			# Mouse button released
			if event.button_index == MOUSE_BUTTON_LEFT:
				if is_dragging_notes:
					_end_note_drag()
				elif is_dragging_selection:
					_end_selection_box()
	
	elif event is InputEventMouseMotion:
		if is_dragging_selection:
			_update_selection_box(event.position)
		elif is_dragging_notes:
			_update_note_drag(event.position)

func _get_note_at_position(lane: int, tick: int) -> int:
	"""Find note at given position, returns note_id or -1"""
	var tolerance = int(resolution / snap_division / 2)  # Half a snap division
	
	for note_id in visual_notes:
		var note_data = visual_notes[note_id]
		if note_data.lane == lane:
			if abs(note_data.tick - tick) <= tolerance:
				return note_id
	
	return -1

# Selection methods
func select_note(note_id: int, add_to_selection: bool = false) -> void:
	"""Select a note"""
	if not add_to_selection:
		selected_notes.clear()
	
	if note_id not in selected_notes:
		selected_notes.append(note_id)
	
	notes_selected.emit(selected_notes)
	queue_redraw()

func toggle_note_selection(note_id: int) -> void:
	"""Toggle note selection state"""
	if note_id in selected_notes:
		selected_notes.erase(note_id)
	else:
		selected_notes.append(note_id)
	
	notes_selected.emit(selected_notes)
	queue_redraw()

func clear_selection() -> void:
	"""Clear all selected notes"""
	if selected_notes.size() > 0:
		selected_notes.clear()
		notes_selected.emit(selected_notes)
		queue_redraw()

func select_all() -> void:
	"""Select all notes in current chart"""
	selected_notes.clear()
	for note_id in visual_notes:
		selected_notes.append(note_id)
	
	notes_selected.emit(selected_notes)
	queue_redraw()

func get_selected_notes() -> Array[int]:
	"""Get array of selected note IDs"""
	return selected_notes.duplicate()

# Selection box methods
func _start_selection_box(pos: Vector2) -> void:
	"""Start dragging a selection box"""
	is_dragging_selection = true
	selection_start_pos = pos
	selection_rect = Rect2(pos, Vector2.ZERO)
	queue_redraw()

func _update_selection_box(pos: Vector2) -> void:
	"""Update selection box during drag"""
	var box_size = pos - selection_start_pos
	selection_rect = Rect2(
		Vector2(min(selection_start_pos.x, pos.x), min(selection_start_pos.y, pos.y)),
		Vector2(abs(box_size.x), abs(box_size.y))
	)
	queue_redraw()

func _end_selection_box() -> void:
	"""Finish selection box and select notes within it"""
	is_dragging_selection = false
	
	# Find notes within selection box
	var notes_in_box: Array[int] = []
	for note_id in visual_notes:
		var note_data = visual_notes[note_id]
		var note_pos = Vector2(lane_to_x(note_data.lane), tick_to_y(note_data.tick))
		
		if selection_rect.has_point(note_pos):
			notes_in_box.append(note_id)
	
	# Select found notes
	if notes_in_box.size() > 0:
		selected_notes = notes_in_box
		notes_selected.emit(selected_notes)
	
	queue_redraw()

func _draw_selection_box() -> void:
	"""Draw the selection box if dragging"""
	if is_dragging_selection:
		draw_rect(selection_rect, Color(0.5, 0.5, 1.0, 0.2))
		draw_rect(selection_rect, Color(0.5, 0.5, 1.0, 0.8), false, 2.0)

# Note dragging methods
func _start_note_drag(pos: Vector2, lane: int, tick: int) -> void:
	"""Start dragging selected notes"""
	if selected_notes.size() == 0:
		return
	
	is_dragging_notes = true
	drag_start_pos = pos
	drag_start_tick = tick
	drag_offset_lane = 0
	drag_offset_tick = 0
	
	# Store original positions
	original_note_positions.clear()
	for note_id in selected_notes:
		if note_id in visual_notes:
			var note_data = visual_notes[note_id]
			original_note_positions[note_id] = {
				"lane": note_data.lane,
				"tick": note_data.tick
			}

func _update_note_drag(pos: Vector2) -> void:
	"""Update note positions during drag"""
	if not is_dragging_notes:
		return
	
	# Calculate offset from start position
	var current_lane = x_to_lane(pos.x)
	var current_tick = y_to_tick(pos.y)
	var snapped_tick = snap_tick_to_grid(current_tick)
	
	var start_lane = x_to_lane(drag_start_pos.x)
	drag_offset_lane = current_lane - start_lane
	drag_offset_tick = snapped_tick - drag_start_tick
	
	# Update visual positions (temporary, not saved to chart data yet)
	for note_id in selected_notes:
		if note_id in original_note_positions and note_id in visual_notes:
			var original = original_note_positions[note_id]
			var new_lane = clamp(original.lane + drag_offset_lane, 0, LANE_COUNT - 1)
			var new_tick = max(0, original.tick + drag_offset_tick)
			
			# Update visual cache temporarily
			visual_notes[note_id].lane = new_lane
			visual_notes[note_id].tick = new_tick
	
	queue_redraw()

func _end_note_drag() -> void:
	"""Finish dragging and emit signal with final positions"""
	if not is_dragging_notes:
		return
	
	is_dragging_notes = false
	
	# If there was actual movement, emit a signal
	if drag_offset_lane != 0 or drag_offset_tick != 0:
		# Restore original positions in visual cache (chart_editor will handle actual move via commands)
		for note_id in selected_notes:
			if note_id in original_note_positions and note_id in visual_notes:
				var original = original_note_positions[note_id]
				visual_notes[note_id].lane = original.lane
				visual_notes[note_id].tick = original.tick
		
		# Emit signal with movement info (chart_editor will create MoveNoteCommand)
		notes_moved.emit(
			selected_notes.duplicate(),
			drag_offset_lane,
			drag_offset_tick,
			original_note_positions.duplicate()
		)
	
	original_note_positions.clear()
	queue_redraw()
