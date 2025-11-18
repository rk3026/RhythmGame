extends Control
# LimitBreakUI.gd - UI component for displaying Limit Break status

@onready var charge_bar: ProgressBar = $ChargeBar
@onready var ready_label: Label = $ReadyLabel
@onready var active_overlay: ColorRect = $ActiveOverlay
@onready var timer_label: Label = $TimerLabel

var pulse_tween: Tween
var active_tween: Tween

func _ready():
	# Initialize UI state
	charge_bar.value = 0
	ready_label.visible = false
	active_overlay.visible = false
	timer_label.visible = false
	
	# Set up charge bar appearance
	charge_bar.show_percentage = false

func update_charge(current: float, maximum: float):
	"""Update the charge bar display"""
	var percentage = (current / maximum) * 100.0 if maximum > 0 else 0.0
	print("LimitBreakUI: update_charge called - current:", current, " max:", maximum, " percentage:", percentage)
	print("LimitBreakUI: Setting charge_bar.value to", percentage)
	charge_bar.value = percentage
	print("LimitBreakUI: charge_bar.value is now", charge_bar.value)

func set_ready(is_ready: bool):
	"""Show/hide the ready indicator"""
	ready_label.visible = is_ready
	
	if is_ready:
		# Start pulsing animation
		_start_ready_pulse()
	else:
		# Stop pulsing
		if pulse_tween:
			pulse_tween.kill()
			pulse_tween = null

func set_active(is_active: bool):
	"""Show/hide the active state overlay"""
	active_overlay.visible = is_active
	timer_label.visible = is_active
	
	if is_active:
		# Start active effects
		_start_active_effects()
	else:
		# Stop active effects
		if active_tween:
			active_tween.kill()
			active_tween = null

func update_timer(time_remaining: float):
	"""Update the timer display when active"""
	if timer_label.visible:
		timer_label.text = "%.1fs" % time_remaining

func _start_ready_pulse():
	"""Animate the ready label with a pulsing effect"""
	if pulse_tween:
		pulse_tween.kill()
	
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	pulse_tween.tween_property(ready_label, "modulate:a", 0.3, 0.5)
	pulse_tween.tween_property(ready_label, "modulate:a", 1.0, 0.5)

func _start_active_effects():
	"""Animate the active overlay with color cycling"""
	if active_tween:
		active_tween.kill()
	
	# Create a pulsing/glowing effect
	active_tween = create_tween()
	active_tween.set_loops()
	active_tween.tween_property(active_overlay, "modulate:a", 0.15, 0.8)
	active_tween.tween_property(active_overlay, "modulate:a", 0.3, 0.8)
