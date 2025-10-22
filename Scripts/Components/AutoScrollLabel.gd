extends ScrollContainer

# AutoScrollLabel: a ScrollContainer that horizontally scrolls an inner Label
# when content overflow occurs. Designed for lists where long text should be readable.

@export var scroll_speed: float = 30.0 # pixels per second
@export var hold_time: float = 3.8     # pause at each edge (seconds)

var _label: Label
var _tween: Tween

func _ready() -> void:
	# Ensure label exists even if setters were called before _ready
	_ensure_label()
	# Configure ScrollContainer
	horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mouse_filter = Control.MOUSE_FILTER_IGNORE


	# React to size/text changes
	connect("resized", Callable(self, "_update_scroll"))
	connect("minimum_size_changed", Callable(self, "_update_scroll"))

	_update_scroll()

func set_text(value: String) -> void:
	_ensure_label()
	_label.text = value
	if is_inside_tree():
		_update_scroll()
	else:
		call_deferred("_update_scroll")

func set_label_settings(settings: LabelSettings) -> void:
	_ensure_label()
	_label.label_settings = settings
	if is_inside_tree():
		_update_scroll()
	else:
		call_deferred("_update_scroll")

func set_horizontal_alignment(align: int) -> void:
	_ensure_label()
	_label.horizontal_alignment = align as HorizontalAlignment
	# Adjust size flags based on alignment for proper positioning
	if align == HORIZONTAL_ALIGNMENT_LEFT:
		_label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	elif align == HORIZONTAL_ALIGNMENT_CENTER:
		_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	elif align == HORIZONTAL_ALIGNMENT_RIGHT:
		_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if is_inside_tree():
		_update_scroll()
	else:
		call_deferred("_update_scroll")

func set_vertical_alignment(align: int) -> void:
	_ensure_label()
	_label.vertical_alignment = align as VerticalAlignment
	if is_inside_tree():
		_update_scroll()
	else:
		call_deferred("_update_scroll")

func get_label() -> Label:
	return _label

func _stop_scroll() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null
	scroll_horizontal = 0

func _update_scroll() -> void:
	if not is_inside_tree():
		return
	# Allow one frame for layout to update sizes
	await get_tree().process_frame

	# Calculate content vs viewport widths
	var content_width: float = _label.get_combined_minimum_size().x
	var viewport_width: float = size.x

	if viewport_width <= 0.0 or content_width <= viewport_width:
		_stop_scroll()
		return

	# Prepare tween
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_loops()

	var max_scroll: float = max(content_width - viewport_width, 0.0)
	var duration: float = max(max_scroll / scroll_speed, 0.01)

	# Animate left then right with a hold at each end
	scroll_horizontal = 0
	_tween.tween_property(self, "scroll_horizontal", int(max_scroll), duration)
	_tween.tween_interval(hold_time)
	_tween.tween_property(self, "scroll_horizontal", 0, duration)
	_tween.tween_interval(hold_time)

func _ensure_label() -> void:
	if _label:
		return
	_label = Label.new()
	_label.clip_text = false
	_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_label.size_flags_vertical = Control.SIZE_FILL
	# size_flags_horizontal will be set by set_horizontal_alignment()
	add_child(_label)
