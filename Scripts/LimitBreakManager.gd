extends Node
# LimitBreakManager.gd - Manages the Limit Break mechanic
# Inspired by FF7's Limit Break system
# Charges through hitting notes, activates for a duration with score multiplier

class_name LimitBreakManager

# Signals
signal charge_changed(current_charge: float, max_charge: float)
signal limit_break_activated()
signal limit_break_deactivated()
signal limit_break_ready()

# Configuration
@export_group("Charge Settings")
@export var max_charge: float = 100.0
@export var charge_per_perfect: float = 4.0
@export var charge_per_great: float = 2.5
@export var charge_per_good: float = 1.5
@export var charge_decay_rate: float = 0.0  # Optional: decay charge over time when not active

@export_group("Activation Settings")
@export var duration: float = 10.0  # How long Limit Break lasts in seconds
@export var score_multiplier: float = 2.0  # Score multiplier when active
@export var cooldown_duration: float = 0.0  # Cooldown after deactivation (0 = none)

@export_group("Visual Settings")
@export var pulse_speed: float = 2.0  # For UI pulsing animation when ready

# State
var current_charge: float = 0.0
var is_active: bool = false
var is_ready: bool = false
var time_remaining: float = 0.0
var cooldown_remaining: float = 0.0

func _ready():
	current_charge = 0.0
	is_active = false
	is_ready = false

func _process(delta: float):
	if is_active:
		# Count down active duration
		time_remaining -= delta
		if time_remaining <= 0.0:
			deactivate_limit_break()
	elif cooldown_remaining > 0.0:
		# Count down cooldown
		cooldown_remaining -= delta
		if cooldown_remaining <= 0.0:
			cooldown_remaining = 0.0
	elif charge_decay_rate > 0.0 and current_charge > 0.0:
		# Optional: decay charge when not active
		current_charge = max(0.0, current_charge - charge_decay_rate * delta)
		_check_ready_state()
		emit_signal("charge_changed", current_charge, max_charge)

func add_charge_for_grade(grade: int):
	"""Add charge based on hit grade"""
	if is_active or cooldown_remaining > 0.0:
		return  # Don't charge while active or on cooldown
	
	var charge_amount: float = 0.0
	
	match grade:
		SettingsManager.HitGrade.PERFECT:
			charge_amount = charge_per_perfect
		SettingsManager.HitGrade.GREAT:
			charge_amount = charge_per_great
		SettingsManager.HitGrade.GOOD:
			charge_amount = charge_per_good
		SettingsManager.HitGrade.MISS:
			charge_amount = 0.0
	
	if charge_amount > 0.0:
		add_charge(charge_amount)

func add_charge(amount: float):
	"""Add charge to the meter"""
	if is_active or cooldown_remaining > 0.0:
		return
	
	var old_charge = current_charge
	current_charge = min(current_charge + amount, max_charge)
	
	# Always emit charge changed
	emit_signal("charge_changed", current_charge, max_charge)
	
	# Check if we just became ready
	if old_charge < max_charge and current_charge >= max_charge:
		_set_ready(true)

func activate_limit_break() -> bool:
	"""Activate Limit Break if ready"""
	if not is_ready or is_active or cooldown_remaining > 0.0:
		print("LimitBreak: Cannot activate - ready:", is_ready, " active:", is_active, " cooldown:", cooldown_remaining)
		return false
	
	if current_charge < max_charge:
		print("LimitBreak: Cannot activate - charge not full:", current_charge, "/", max_charge)
		return false
	
	print("LimitBreak: ACTIVATING! Resetting charge from", current_charge, "to 0")
	
	is_active = true
	is_ready = false
	time_remaining = duration
	# Reset charge immediately on activation
	current_charge = 0.0
	
	emit_signal("limit_break_activated")
	emit_signal("charge_changed", current_charge, max_charge)
	
	print("LimitBreak: Activation complete. charge=", current_charge, " active=", is_active)
	
	return true

func deactivate_limit_break():
	"""Deactivate Limit Break (called when duration expires)"""
	if not is_active:
		return
	
	is_active = false
	# Charge already set to 0 on activation, don't set again
	# Keep at 0 to ensure it's reset
	if current_charge > 0.0:
		current_charge = 0.0
		emit_signal("charge_changed", current_charge, max_charge)
	
	cooldown_remaining = cooldown_duration
	
	emit_signal("limit_break_deactivated")
	
	_check_ready_state()

func _check_ready_state():
	"""Check if we should be in ready state"""
	var should_be_ready = current_charge >= max_charge and not is_active and cooldown_remaining <= 0.0
	if should_be_ready and not is_ready:
		_set_ready(true)
	elif not should_be_ready and is_ready:
		_set_ready(false)

func _set_ready(new_ready_state: bool):
	"""Set the ready state and emit signal if changed"""
	if is_ready != new_ready_state:
		is_ready = new_ready_state
		if is_ready:
			emit_signal("limit_break_ready")

func get_score_multiplier() -> float:
	"""Get the current score multiplier (1.0 if not active)"""
	return score_multiplier if is_active else 1.0

func get_charge_percentage() -> float:
	"""Get charge as percentage (0.0 to 1.0)"""
	return current_charge / max_charge if max_charge > 0.0 else 0.0

func get_time_remaining_percentage() -> float:
	"""Get time remaining as percentage when active"""
	return time_remaining / duration if is_active and duration > 0.0 else 0.0

func reset():
	"""Reset the Limit Break state (e.g., when starting a new song)"""
	current_charge = 0.0
	is_active = false
	is_ready = false
	time_remaining = 0.0
	cooldown_remaining = 0.0
	emit_signal("charge_changed", current_charge, max_charge)
