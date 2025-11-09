extends PanelContainer

# Signals
signal section_selected(section_name: String)

# UI elements
@onready var section_list: VBoxContainer = $VBox/ScrollContainer/SectionList
var sections: Array = []

func _ready():
	# Add some default sections for visualization
	_add_default_sections()

func _add_default_sections():
	# These will be replaced with actual song sections when a chart is loaded
	var default_sections = [
		{"name": "Intro", "time": 0.0, "percentage": 0.0},
		{"name": "Verse 1A", "time": 10.0, "percentage": 5.0},
		{"name": "Verse 2A", "time": 20.0, "percentage": 10.0},
		{"name": "Riff 1A", "time": 30.0, "percentage": 15.0},
		{"name": "Riff 2A", "time": 40.0, "percentage": 20.0},
		{"name": "Bridge", "time": 50.0, "percentage": 25.0},
		{"name": "Solo A", "time": 60.0, "percentage": 30.0},
		{"name": "Solo B", "time": 70.0, "percentage": 35.0},
		{"name": "Breakdown", "time": 80.0, "percentage": 40.0},
		{"name": "Lotta Oranges", "time": 90.0, "percentage": 45.0},
		{"name": "Chorus 1", "time": 100.0, "percentage": 50.0},
		{"name": "Chorus 2", "time": 110.0, "percentage": 55.0},
		{"name": "Verse 1B", "time": 120.0, "percentage": 60.0},
		{"name": "Verse 2B", "time": 130.0, "percentage": 65.0},
		{"name": "Riff 1B", "time": 140.0, "percentage": 70.0},
		{"name": "Riff 2B", "time": 150.0, "percentage": 75.0},
		{"name": "Outro A", "time": 160.0, "percentage": 80.0},
		{"name": "Outro B", "time": 170.0, "percentage": 85.0},
	]
	
	for section_data in default_sections:
		add_section(section_data.name, section_data.time, section_data.percentage)

func add_section(section_name: String, time: float, percentage: float):
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
	section_button.pressed.connect(_on_section_pressed.bind(section_name, time))
	section_container.add_child(section_button)
	
	section_list.add_child(section_container)
	sections.append({"name": section_name, "time": time, "container": section_container})

func _on_section_pressed(section_name: String, time: float):
	section_selected.emit(section_name)
	print("Section selected: ", section_name, " at time: ", time)

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

func load_sections_from_chart(chart_sections: Array):
	clear_sections()
	var total_time = 100.0  # Will be replaced with actual song duration
	
	for section_data in chart_sections:
		var section_name = section_data.name if section_data.has("name") else "Section"
		var time = section_data.time if section_data.has("time") else 0.0
		var percentage = (time / total_time) * 100.0
		add_section(section_name, time, percentage)
