extends HBoxContainer
class_name StatDisplay

# StatDisplay.gd - Reusable component for displaying a stat with label and value
# Shows icon (optional), label, and formatted value

@export var stat_label: String = "Stat"
@export var stat_value: String = "0"
@export var icon_path: String = ""
@export var value_color: Color = Color.WHITE

var icon_texture: TextureRect
var label_node: Label
var value_node: Label

func _ready():
	add_theme_constant_override("separation", 10)
	_build_ui()
	_update_display()

func _build_ui():
	"""Build the stat display UI."""
	# Icon (optional)
	if not icon_path.is_empty() and ResourceLoader.exists(icon_path):
		icon_texture = TextureRect.new()
		icon_texture.custom_minimum_size = Vector2(24, 24)
		icon_texture.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_texture.texture = load(icon_path)
		add_child(icon_texture)
	
	# Label
	label_node = Label.new()
	label_node.add_theme_font_size_override("font_size", 16)
	label_node.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	add_child(label_node)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(spacer)
	
	# Value
	value_node = Label.new()
	value_node.add_theme_font_size_override("font_size", 18)
	value_node.add_theme_color_override("font_color", value_color)
	add_child(value_node)

func set_stat(label: String, value: Variant, color: Color = Color.WHITE):
	"""
	Update the stat display.
	
	Args:
		label: Label text
		value: Value to display (will be converted to string)
		color: Color for the value text
	"""
	stat_label = label
	stat_value = str(value)
	value_color = color
	_update_display()

func _update_display():
	"""Update the UI with current values."""
	if label_node:
		label_node.text = stat_label + ":"
	if value_node:
		value_node.text = stat_value
		value_node.add_theme_color_override("font_color", value_color)
