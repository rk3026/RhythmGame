extends PanelContainer
class_name KeybindDisplay

## Reusable keybind visualization component
## Shows keyboard key, mouse button, or gamepad button with visual feedback
## Usage: KeybindDisplay.create(KEY_SPACE, "Jump") or KeybindDisplay.from_action("ui_accept")

signal key_pressed
signal key_released
signal keybind_changed

enum InputDeviceType {
	KEYBOARD,
	MOUSE,
	GAMEPAD
}

enum KeyState {
	NORMAL,
	PRESSED,
	WAITING,      # Used during rebind prompts
	DISABLED
}

@export_group("Display Settings")
@export var key_text: String = "?" :
	set(value):
		key_text = value
		if _label:
			_label.text = key_text
@export var show_label: bool = false
@export var label_text: String = ""
@export var device_type: InputDeviceType = InputDeviceType.KEYBOARD

@export_group("Visual Style")
@export var key_size: Vector2 = Vector2(60, 60)
@export var font_size: int = 24
@export var label_font_size: int = 14

@export_group("Colors")
@export var normal_color: Color = Color(0.2, 0.2, 0.2)
@export var pressed_color: Color = Color(0.1, 0.5, 0.9)
@export var waiting_color: Color = Color(0.9, 0.6, 0.1)
@export var disabled_color: Color = Color(0.15, 0.15, 0.15)
@export var border_color: Color = Color(0.4, 0.4, 0.4)

@export_group("Animation")
@export var enable_press_animation: bool = true
@export var press_scale: float = 0.9
@export var animation_speed: float = 0.1

var _current_state: KeyState = KeyState.NORMAL
var _label: Label = null
var _name_label: Label = null
var _original_scale: Vector2 = Vector2.ONE
var _key_code: int = -1

func _ready() -> void:
	custom_minimum_size = key_size
	_build_display()
	_update_style()

func _build_display() -> void:
	# Main container
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(vbox)
	
	# Key label (the actual key/button text)
	_label = Label.new()
	_label.text = key_text
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", font_size)
	vbox.add_child(_label)
	
	# Optional name label (e.g., "Jump", "Fire")
	if show_label and label_text != "":
		_name_label = Label.new()
		_name_label.text = label_text
		_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_name_label.add_theme_font_size_override("font_size", label_font_size)
		_name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		vbox.add_child(_name_label)

func _update_style() -> void:
	var style = StyleBoxFlat.new()
	
	# Choose color based on state
	match _current_state:
		KeyState.NORMAL:
			style.bg_color = normal_color
		KeyState.PRESSED:
			style.bg_color = pressed_color
		KeyState.WAITING:
			style.bg_color = waiting_color
		KeyState.DISABLED:
			style.bg_color = disabled_color
	
	# Border
	style.border_color = border_color
	style.set_border_width_all(2)
	
	# Rounded corners
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	# Padding
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	
	# Shadow for depth
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	style.shadow_color = Color(0, 0, 0, 0.3)
	
	add_theme_stylebox_override("panel", style)

func set_state(new_state: KeyState) -> void:
	_current_state = new_state
	_update_style()
	
	# Animate press
	if enable_press_animation and new_state == KeyState.PRESSED:
		_play_press_animation()
	elif enable_press_animation and new_state == KeyState.NORMAL:
		_play_release_animation()

func _play_press_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(press_scale, press_scale), animation_speed)
	key_pressed.emit()

func _play_release_animation() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", _original_scale, animation_speed)
	key_released.emit()

func set_key_from_event(event: InputEvent) -> void:
	"""Sets the display based on an InputEvent"""
	if event is InputEventKey:
		var key_event = event as InputEventKey
		_key_code = key_event.physical_keycode
		device_type = InputDeviceType.KEYBOARD
		key_text = OS.get_keycode_string(key_event.physical_keycode)
	elif event is InputEventMouseButton:
		var mouse_event = event as InputEventMouseButton
		device_type = InputDeviceType.MOUSE
		match mouse_event.button_index:
			MOUSE_BUTTON_LEFT:
				key_text = "LMB"
			MOUSE_BUTTON_RIGHT:
				key_text = "RMB"
			MOUSE_BUTTON_MIDDLE:
				key_text = "MMB"
			MOUSE_BUTTON_WHEEL_UP:
				key_text = "Wheel ↑"
			MOUSE_BUTTON_WHEEL_DOWN:
				key_text = "Wheel ↓"
			_:
				key_text = "M%d" % mouse_event.button_index
	elif event is InputEventJoypadButton:
		var joy_event = event as InputEventJoypadButton
		device_type = InputDeviceType.GAMEPAD
		key_text = _get_gamepad_button_name(joy_event.button_index)

func _get_gamepad_button_name(button_index: int) -> String:
	match button_index:
		JOY_BUTTON_A: return "Ⓐ"
		JOY_BUTTON_B: return "Ⓑ"
		JOY_BUTTON_X: return "Ⓧ"
		JOY_BUTTON_Y: return "Ⓨ"
		JOY_BUTTON_LEFT_SHOULDER: return "LB"
		JOY_BUTTON_RIGHT_SHOULDER: return "RB"
		JOY_BUTTON_START: return "Start"
		JOY_BUTTON_BACK: return "Select"
		_: return "Btn %d" % button_index

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		keybind_changed.emit()

func shake() -> void:
	"""Play shake animation (for invalid input)"""
	var tween = create_tween()
	var shake_amount = 5.0
	tween.tween_property(self, "position:x", position.x + shake_amount, 0.05)
	tween.tween_property(self, "position:x", position.x - shake_amount, 0.05)
	tween.tween_property(self, "position:x", position.x + shake_amount, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)

static func create(key: int = KEY_UNKNOWN, action_label: String = ""):
	"""Static factory method to create a KeybindDisplay from a keycode"""
	var script_path = "res://Scripts/Components/KeybindDisplay.gd"
	var display_script = load(script_path)
	var display = display_script.new()
	
	if key != KEY_UNKNOWN:
		display.key_text = OS.get_keycode_string(key)
		display._key_code = key
	
	if action_label != "":
		display.show_label = true
		display.label_text = action_label
	
	return display

static func from_action(action_name: String):
	"""Creates a KeybindDisplay from an InputMap action"""
	var script_path = "res://Scripts/Components/KeybindDisplay.gd"
	var display_script = load(script_path)
	var display = display_script.new()
	
	display.label_text = action_name
	display.show_label = true
	
	# Get the first event from the action
	if InputMap.has_action(action_name):
		var events = InputMap.action_get_events(action_name)
		if events.size() > 0:
			display.set_key_from_event(events[0])
	else:
		display.key_text = "?"
	
	return display
