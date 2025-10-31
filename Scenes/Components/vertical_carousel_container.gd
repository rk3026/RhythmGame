@tool
extends Control

class_name VerticalCarouselContainer

signal selection_changed(new_index)

@export var spacing: float = 20.0

@export var wraparound_enabled: bool = false
@export var wraparound_radius: float = 300.0
@export var wraparound_width: float = 50.0

@export_range(0.0, 1.0) var opacity_strength: float = 0.35
@export_range(0.0, 1.0) var scale_strength: float = 0.25
@export_range(0.01, 0.99, 0.01) var scale_min: float = 0.1

@export var smoothing_speed: float = 6.5
@export var selected_index: int = 0
@export var follow_button_focus: bool = false

@export var position_offset_node: Control = null

# Drag/scroll state
var _dragging: bool = false
var _drag_start_y: float = 0.0
var _drag_last_y: float = 0.0
var _drag_total: float = 0.0

const BUTTON_WHEEL_UP := 4
const BUTTON_WHEEL_DOWN := 5
const BUTTON_LEFT := 1
func _process(delta: float) -> void:
	if !position_offset_node or position_offset_node.get_child_count() == 0:
		return
	
	selected_index = clamp(selected_index, 0, position_offset_node.get_child_count() - 1)

	for i in position_offset_node.get_children():
		if wraparound_enabled:
			var max_index_range = max(1, (position_offset_node.get_child_count() - 1) / 2.0)
			var angle = clamp((i.get_index() - selected_index) / max_index_range, -1.0, 1.0) * PI
			var y = sin(angle) * wraparound_radius
			var x = cos(angle) * wraparound_width
			var target_pos = Vector2(x - wraparound_width, y) - i.size/2.0
			i.position = lerp(i.position, target_pos, smoothing_speed * delta)
		else:
			var position_y = 0
			if i.get_index() > 0:
				position_y = position_offset_node.get_child(i.get_index()-1).position.y + position_offset_node.get_child(i.get_index()-1).size.y + spacing
			i.position = Vector2(-i.size.x / 2.0, position_y)

		i.pivot_offset = i.size / 2.0
		var target_scale = 1.0 - (scale_strength * abs(i.get_index() - selected_index))
		target_scale = clamp(target_scale, scale_min, 1.0)
		i.scale = lerp(i.scale, Vector2.ONE * target_scale, smoothing_speed * delta)

		var target_opacity = 1.0 - (opacity_strength * abs(i.get_index() - selected_index))
		target_opacity = clamp(target_opacity, 0.0, 1.0)
		i.modulate.a = lerp(i.modulate.a, target_opacity, smoothing_speed * delta)

		if i.get_index() == selected_index:
			i.mouse_filter = Control.MOUSE_FILTER_STOP
			i.focus_mode = Control.FOCUS_ALL
		else:
			i.mouse_filter = Control.MOUSE_FILTER_IGNORE
			i.focus_mode = Control.FOCUS_NONE

		if follow_button_focus and i.has_focus():
			selected_index = i.get_index()

	if wraparound_enabled:
		position_offset_node.position.y = lerp(position_offset_node.position.y, 0.0, smoothing_speed * delta)
	else:
		position_offset_node.position.y = lerp(position_offset_node.position.y, -(position_offset_node.get_child(selected_index).position.y) + position_offset_node.get_child(selected_index).size.y / 2.0, smoothing_speed * delta)


func _up():
	if not position_offset_node:
		return
	var old = selected_index
	selected_index -= 1
	if selected_index < 0:
		if wraparound_enabled:
			selected_index = position_offset_node.get_child_count() - 1
		else:
			selected_index = 0
	if selected_index != old:
		emit_signal("selection_changed", selected_index)

func _down():
	if not position_offset_node:
		return
	var old = selected_index
	selected_index += 1
	if selected_index > position_offset_node.get_child_count() - 1:
		if wraparound_enabled:
			selected_index = 0
		else:
			selected_index = max(0, position_offset_node.get_child_count() - 1)
	if selected_index != old:
		emit_signal("selection_changed", selected_index)


func _gui_input(event: InputEvent) -> void:
	# Mouse wheel scroll
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == BUTTON_WHEEL_UP:
			_up()
			return
		if mb.pressed and mb.button_index == BUTTON_WHEEL_DOWN:
			_down()
			return
		# Left-click start drag
		if mb.button_index == BUTTON_LEFT and mb.pressed:
			_dragging = true
			_drag_start_y = mb.position.y
			_drag_last_y = _drag_start_y
			_drag_total = 0.0
			return
		# Left-click release -> snap to nearest
		if mb.button_index == BUTTON_LEFT and not mb.pressed and _dragging:
			_dragging = false
			_snap_to_nearest()
			return

	# Mouse motion when dragging
	if event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		var dy := mm.position.y - _drag_last_y
		_drag_last_y = mm.position.y
		_drag_total += dy
		if position_offset_node:
			position_offset_node.position.y += dy


func _snap_to_nearest() -> void:
	if not position_offset_node or position_offset_node.get_child_count() == 0:
		return
	# Current center (in position space of children)
	var current_center_y = -position_offset_node.position.y
	var best_index = 0
	var best_dist = INF
	for child in position_offset_node.get_children():
		var center = child.position.y + child.size.y / 2.0
		var d = abs(center - current_center_y)
		if d < best_dist:
			best_dist = d
			best_index = child.get_index()
	var old = selected_index
	selected_index = best_index
	if selected_index != old:
		emit_signal("selection_changed", selected_index)
