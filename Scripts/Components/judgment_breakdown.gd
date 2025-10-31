extends PanelContainer
## Displays judgment breakdown with progress bars and percentages

@onready var perfect_bar: ProgressBar = $MarginContainer/VBox/PerfectRow/Bar
@onready var perfect_label: Label = $MarginContainer/VBox/PerfectRow/Label
@onready var great_bar: ProgressBar = $MarginContainer/VBox/GreatRow/Bar
@onready var great_label: Label = $MarginContainer/VBox/GreatRow/Label
@onready var good_bar: ProgressBar = $MarginContainer/VBox/GoodRow/Bar
@onready var good_label: Label = $MarginContainer/VBox/GoodRow/Label
@onready var miss_bar: ProgressBar = $MarginContainer/VBox/MissRow/Bar
@onready var miss_label: Label = $MarginContainer/VBox/MissRow/Label
@onready var header_label: Label = $MarginContainer/VBox/HeaderLabel

func set_judgments(perfect: int, great: int, good: int, miss: int, total_notes: int):
	"""Set the judgment counts and update progress bars."""
	# Calculate percentages
	var perfect_pct = (float(perfect) / float(total_notes)) * 100.0 if total_notes > 0 else 0.0
	var great_pct = (float(great) / float(total_notes)) * 100.0 if total_notes > 0 else 0.0
	var good_pct = (float(good) / float(total_notes)) * 100.0 if total_notes > 0 else 0.0
	var miss_pct = (float(miss) / float(total_notes)) * 100.0 if total_notes > 0 else 0.0
	
	# Update progress bars (0-100 scale)
	perfect_bar.value = perfect_pct
	great_bar.value = great_pct
	good_bar.value = good_pct
	miss_bar.value = miss_pct
	
	# Update labels
	perfect_label.text = "Perfect: %d (%.0f%%)" % [perfect, perfect_pct]
	great_label.text = "Great: %d (%.0f%%)" % [great, great_pct]
	good_label.text = "Good: %d (%.0f%%)" % [good, good_pct]
	miss_label.text = "Miss: %d (%.0f%%)" % [miss, miss_pct]
	
	# Animate bars
	_animate_bars()

func _animate_bars():
	"""Animate progress bars filling up."""
	# Store target values
	var targets = [perfect_bar.value, great_bar.value, good_bar.value, miss_bar.value]
	var bars = [perfect_bar, great_bar, good_bar, miss_bar]
	
	# Start from 0
	for bar in bars:
		bar.value = 0
	
	# Animate each bar with slight delay
	for i in range(bars.size()):
		var tween = create_tween()
		tween.tween_property(bars[i], "value", targets[i], 0.8).set_delay(i * 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
