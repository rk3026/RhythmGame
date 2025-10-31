extends PanelContainer
## Reusable stat card that displays a metric with optional comparison to previous best

@onready var stat_label: Label = $MarginContainer/VBox/StatLabel
@onready var value_label: Label = $MarginContainer/VBox/ValueLabel
@onready var comparison_label: Label = $MarginContainer/VBox/ComparisonLabel

func _ready():
	comparison_label.visible = false

func set_stat(stat_name: String, value: String):
	"""Set the stat name and current value."""
	stat_label.text = stat_name
	value_label.text = value

func set_comparison(difference: float, format_as_percent: bool = false):
	"""
	Show comparison to previous value.
	difference: positive = improvement, negative = worse
	format_as_percent: whether to format as percentage or raw number
	"""
	if abs(difference) < 0.01:  # No meaningful difference
		comparison_label.visible = false
		return
	
	comparison_label.visible = true
	
	var sign_prefix = "+" if difference > 0 else ""
	var value_text = ""
	
	if format_as_percent:
		value_text = "%.1f%%" % difference
	else:
		value_text = str(int(difference))
	
	var arrow = " ↑" if difference > 0 else " ↓"
	comparison_label.text = sign_prefix + value_text + arrow
	
	# Color code: green for improvement, red for worse
	if difference > 0:
		comparison_label.modulate = Color(0.5, 1.0, 0.5)  # Light green
	else:
		comparison_label.modulate = Color(1.0, 0.5, 0.5)  # Light red

func hide_comparison():
	"""Hide the comparison label (useful for first-time plays)."""
	comparison_label.visible = false
