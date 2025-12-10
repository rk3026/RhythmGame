extends PanelContainer

# Signals
signal section_selected(event_id: int, time: float)
signal event_add_requested(time: float)
signal event_edit_requested(event_id: int)
signal event_delete_requested(event_id: int)

# UI elements
@onready var section_list: VBoxContainer = $VBox/ScrollContainer/SectionList
var sections: Array = []
var chart_document: ChartDocument
var song_duration: float = 0.0
var current_time: float = 0.0

func _ready():
	pass  # Wait for chart_document to be set

func configure(doc: ChartDocument, duration: float):
	chart_document = doc
	song_duration = duration
	_connect_chart_signals()
	refresh_sections()

func set_current_time(time: float):
	current_time = time

func _connect_chart_signals():
	if not chart_document:
		return
	chart_document.event_added.connect(_on_event_added)
	chart_document.event_removed.connect(_on_event_removed)
	chart_document.event_changed.connect(_on_event_changed)

func _on_event_added(_event_id: int, _event_data: Dictionary):
	refresh_sections()

func _on_event_removed(_event_id: int):
	refresh_sections()

func _on_event_changed(_event_id: int, _event_data: Dictionary):
	refresh_sections()

func refresh_sections():
	clear_sections()
	if not chart_document:
		return
	
	var events = chart_document.get_events()
	for event_data in events:
		var percentage = (event_data.time / song_duration * 100.0) if song_duration > 0 else 0.0
		add_section(event_data.id, event_data.text, event_data.time, percentage)

func _on_add_button_pressed():
	# Request to add event at current timeline position
	event_add_requested.emit(current_time)

func add_section(event_id: int, section_name: String, time: float, percentage: float):
	var section_container = HBoxContainer.new()
	
	# Progress indicator (colored bar)
	var progress_bar = ColorRect.new()
	progress_bar.custom_minimum_size = Vector2(8, 20)
	progress_bar.color = _get_color_for_percentage(percentage)
	section_container.add_child(progress_bar)
	
	# Section button
	var section_button = Button.new()
	section_button.text = section_name
	section_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	section_button.pressed.connect(_on_section_pressed.bind(event_id, time))
	section_container.add_child(section_button)
	
	# Edit button
	var edit_button = Button.new()
	edit_button.text = "✎"
	edit_button.custom_minimum_size = Vector2(30, 0)
	edit_button.pressed.connect(_on_edit_pressed.bind(event_id))
	section_container.add_child(edit_button)
	
	# Delete button
	var delete_button = Button.new()
	delete_button.text = "×"
	delete_button.custom_minimum_size = Vector2(30, 0)
	delete_button.pressed.connect(_on_delete_pressed.bind(event_id))
	section_container.add_child(delete_button)
	
	section_list.add_child(section_container)
	sections.append({"id": event_id, "name": section_name, "time": time, "container": section_container})

func _on_section_pressed(event_id: int, time: float):
	section_selected.emit(event_id, time)

func _on_edit_pressed(event_id: int):
	event_edit_requested.emit(event_id)

func _on_delete_pressed(event_id: int):
	event_delete_requested.emit(event_id)

func _get_color_for_percentage(percentage: float) -> Color:
	# Create a gradient from cyan to magenta based on song progress
	var normalized = percentage / 100.0
	if normalized < 0.5:
		# Cyan to blue
		return Color(0.0, 1.0 - normalized, 1.0)
	else:
		# Blue to magenta
		return Color((normalized - 0.5) * 2.0, 0.0, 1.0)

func clear_sections():
	for child in section_list.get_children():
		child.queue_free()
	sections.clear()


