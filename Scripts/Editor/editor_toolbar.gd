extends HBoxContainer

# Signal emissions for menu actions
signal file_new_requested
signal file_open_requested
signal file_save_requested
signal file_save_as_requested
signal file_export_requested
signal instrument_changed(instrument: String)
signal difficulty_changed(difficulty: String)
signal song_properties_requested
signal tool_selected(tool_name: String)
signal options_requested
signal help_requested

# Menu references
@onready var file_menu: PopupMenu = $FileButton.get_popup()
@onready var instrument_menu: PopupMenu = $InstrumentButton.get_popup()
@onready var difficulty_menu: PopupMenu = $DifficultyButton.get_popup()
@onready var song_properties_button: Button = $SongPropertiesButton
@onready var tools_menu: PopupMenu = $ToolsButton.get_popup()
@onready var options_menu: PopupMenu = $OptionsButton.get_popup()
@onready var help_menu: PopupMenu = $HelpButton.get_popup()

func _ready():
	_setup_menus()

func _setup_menus():
	# File Menu
	file_menu.add_item("New Chart", 0)
	file_menu.add_item("Open Chart", 1)
	file_menu.add_separator()
	file_menu.add_item("Save", 2)
	file_menu.add_item("Save As...", 3)
	file_menu.add_separator()
	file_menu.add_item("Export", 4)
	file_menu.add_separator()
	file_menu.add_item("Exit", 5)
	file_menu.id_pressed.connect(_on_file_menu_id_pressed)
	
	# Instrument Menu
	instrument_menu.add_item("Single", 0)
	instrument_menu.add_item("Double Bass", 1)
	instrument_menu.add_item("Double Guitar", 2)
	instrument_menu.add_item("Drums", 3)
	instrument_menu.add_item("Keys", 4)
	instrument_menu.add_item("GHL Guitar", 5)
	instrument_menu.add_item("GHL Bass", 6)
	instrument_menu.id_pressed.connect(_on_instrument_menu_id_pressed)
	
	# Difficulty Menu
	difficulty_menu.add_item("Easy", 0)
	difficulty_menu.add_item("Medium", 1)
	difficulty_menu.add_item("Hard", 2)
	difficulty_menu.add_item("Expert", 3)
	difficulty_menu.id_pressed.connect(_on_difficulty_menu_id_pressed)
	
	# Song Properties Button
	song_properties_button.pressed.connect(_on_song_properties_pressed)
	
	# Tools Menu
	tools_menu.add_item("Note Tool", 0)
	tools_menu.add_item("Select Tool", 1)
	tools_menu.add_item("Erase Tool", 2)
	tools_menu.add_separator()
	tools_menu.add_item("BPM Tool", 3)
	tools_menu.add_item("Section Tool", 4)
	tools_menu.add_item("Event Tool", 5)
	tools_menu.id_pressed.connect(_on_tools_menu_id_pressed)
	
	# Options Menu
	options_menu.add_item("Preferences", 0)
	options_menu.add_item("Key Bindings", 1)
	options_menu.add_separator()
	options_menu.add_check_item("Show Grid", 2)
	options_menu.add_check_item("Show Waveform", 3)
	options_menu.add_check_item("Metronome", 4)
	options_menu.set_item_checked(2, true)  # Grid on by default
	options_menu.id_pressed.connect(_on_options_menu_id_pressed)
	
	# Help Menu
	help_menu.add_item("Keyboard Shortcuts", 0)
	help_menu.add_item("User Guide", 1)
	help_menu.add_separator()
	help_menu.add_item("About", 2)
	help_menu.id_pressed.connect(_on_help_menu_id_pressed)

func _on_file_menu_id_pressed(id: int):
	match id:
		0: file_new_requested.emit()
		1: file_open_requested.emit()
		2: file_save_requested.emit()
		3: file_save_as_requested.emit()
		4: file_export_requested.emit()
		5: SceneSwitcher.pop_scene()

func _on_instrument_menu_id_pressed(id: int):
	var instruments = ["Single", "DoubleBass", "DoubleGuitar", "Drums", "Keys", "GHLGuitar", "GHLBass"]
	if id < instruments.size():
		instrument_changed.emit(instruments[id])

func _on_difficulty_menu_id_pressed(id: int):
	var difficulties = ["Easy", "Medium", "Hard", "Expert"]
	if id < difficulties.size():
		difficulty_changed.emit(difficulties[id])

func _on_song_properties_pressed():
	song_properties_requested.emit()

func _on_tools_menu_id_pressed(id: int):
	var tools = ["Note", "Select", "Erase", "BPM", "Section", "Event"]
	if id < tools.size():
		tool_selected.emit(tools[id])

func _on_options_menu_id_pressed(id: int):
	if id <= 1:
		options_requested.emit()
	else:
		# Toggle checkboxes for display options
		var is_checked = options_menu.is_item_checked(id)
		options_menu.set_item_checked(id, !is_checked)

func _on_help_menu_id_pressed(_id: int):
	help_requested.emit()
