extends PanelContainer

@onready var shortcuts_grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/ShortcutsGrid

func _ready():
	_populate_shortcuts()

func _populate_shortcuts():
	# Clear existing shortcuts
	for child in shortcuts_grid.get_children():
		child.queue_free()
	
	# Define all shortcuts
	var shortcuts = [
		{"category": "TOOL SELECTION"},
		{"key": "Q", "action": "Cursor Tool"},
		{"key": "W", "action": "Note Tool"},
		{"key": "E", "action": "Erase Tool"},
		{"key": "R", "action": "BPM Tool"},
		
		{"category": "NOTE PLACEMENT"},
		{"key": "1-5", "action": "Place note in lane 1-5"},
		{"key": "Shift+1", "action": "Regular note type"},
		{"key": "Shift+2", "action": "HOPO note type"},
		{"key": "Shift+3", "action": "Tap note type"},
		{"key": "Shift+4", "action": "Open note type"},
		{"key": "Right Click + Drag", "action": "Edit sustain length"},
		
		{"category": "TIMELINE NAVIGATION"},
		{"key": "Space", "action": "Play/Pause"},
		{"key": "←", "action": "Move backward (1 snap)"},
		{"key": "→", "action": "Move forward (1 snap)"},
		{"key": "Home", "action": "Jump to start"},
		{"key": "End", "action": "Jump to end"},
		
		{"category": "SNAP DIVISION"},
		{"key": "[", "action": "Decrease snap division"},
		{"key": "]", "action": "Increase snap division"},
		
		{"category": "FILE OPERATIONS"},
		{"key": "Ctrl+S", "action": "Save chart"},
		{"key": "Ctrl+Z", "action": "Undo"},
		{"key": "Ctrl+Y", "action": "Redo"},
		{"key": "Ctrl+Shift+Z", "action": "Redo (alternate)"},
		
		{"category": "EDITING"},
		{"key": "Delete", "action": "Delete selected notes"},
	]
	
	# Create labels for each shortcut
	for shortcut in shortcuts:
		if shortcut.has("category"):
			# Category header
			var category_label = Label.new()
			category_label.text = shortcut.category
			category_label.add_theme_font_size_override("font_size", 14)
			category_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1.0))
			shortcuts_grid.add_child(category_label)
			
			# Empty cell for alignment
			var spacer = Control.new()
			shortcuts_grid.add_child(spacer)
		else:
			# Key label
			var key_label = Label.new()
			key_label.text = shortcut.key
			key_label.add_theme_font_size_override("font_size", 12)
			key_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.6))
			key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			shortcuts_grid.add_child(key_label)
			
			# Action label
			var action_label = Label.new()
			action_label.text = shortcut.action
			action_label.add_theme_font_size_override("font_size", 12)
			shortcuts_grid.add_child(action_label)

func _on_close_button_pressed():
	queue_free()

func _input(event: InputEvent):
	# Close on Escape key
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		queue_free()
		get_viewport().set_input_as_handled()
