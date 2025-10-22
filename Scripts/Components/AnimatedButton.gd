extends Button

# AnimatedButton: A reusable button component with built-in hover/press animations
# Provides consistent visual feedback across all menu systems

@export_group("Animation Settings")
@export var hover_scale: Vector2 = Vector2(1.05, 1.05)
@export var press_scale: Vector2 = Vector2(0.95, 0.95)
@export var animation_duration: float = 0.2
@export var hover_brightness: float = 1.2

@export_group("Effects")
@export var enable_bounce: bool = false
@export var enable_shake: bool = false
@export var shake_intensity: float = 5.0
@export var enable_glow: bool = false
@export var glow_color: Color = Color.WHITE

@export_group("Sound")
@export var hover_sound: AudioStream
@export var click_sound: AudioStream

var _tween: Tween
var _is_hovered: bool = false
var _original_modulate: Color
var _audio_player: AudioStreamPlayer

func _ready() -> void:
	_original_modulate = modulate
	pivot_offset = size / 2.0
	
	# Create audio player for sound effects
	_audio_player = AudioStreamPlayer.new()
	add_child(_audio_player)
	
	# Connect signals
	connect("mouse_entered", Callable(self, "_on_mouse_entered"))
	connect("mouse_exited", Callable(self, "_on_mouse_exited"))
	connect("button_down", Callable(self, "_on_button_down"))
	connect("button_up", Callable(self, "_on_button_up"))
	connect("pressed", Callable(self, "_on_pressed"))
	
	# React to size changes
	connect("resized", Callable(self, "_on_resized"))

func _on_resized() -> void:
	pivot_offset = size / 2.0

func _on_mouse_entered() -> void:
	if disabled:
		return
	
	_is_hovered = true
	_play_hover_animation()
	
	if hover_sound and _audio_player:
		_audio_player.stream = hover_sound
		_audio_player.play()

func _on_mouse_exited() -> void:
	if disabled:
		return
	
	_is_hovered = false
	_play_normal_animation()

func _on_button_down() -> void:
	if disabled:
		return
	
	_play_press_animation()

func _on_button_up() -> void:
	if disabled:
		return
	
	if _is_hovered:
		_play_hover_animation()
	else:
		_play_normal_animation()

func _on_pressed() -> void:
	if click_sound and _audio_player:
		_audio_player.stream = click_sound
		_audio_player.play()
	
	if enable_bounce:
		_play_bounce_effect()
	
	if enable_shake:
		_play_shake_effect()

func _play_hover_animation() -> void:
	_cancel_tween()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "scale", hover_scale, animation_duration)
	_tween.tween_property(self, "modulate", _original_modulate * Color(hover_brightness, hover_brightness, hover_brightness, 1.0), animation_duration)
	
	if enable_glow:
		_add_glow_effect()

func _play_normal_animation() -> void:
	_cancel_tween()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	_tween.tween_property(self, "scale", Vector2.ONE, animation_duration)
	_tween.tween_property(self, "modulate", _original_modulate, animation_duration)
	
	if enable_glow:
		_remove_glow_effect()

func _play_press_animation() -> void:
	_cancel_tween()
	_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_property(self, "scale", press_scale, animation_duration * 0.5)

func _play_bounce_effect() -> void:
	var bounce_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	bounce_tween.tween_property(self, "scale", hover_scale * 1.1, 0.3)
	bounce_tween.tween_property(self, "scale", hover_scale, 0.3)

func _play_shake_effect() -> void:
	var original_pos = position
	var shake_tween = create_tween()
	for i in range(4):
		var offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
		shake_tween.tween_property(self, "position", original_pos + offset, 0.05)
	shake_tween.tween_property(self, "position", original_pos, 0.05)

func _add_glow_effect() -> void:
	# Create a simple glow by adding a shadow/outline effect via modulation
	# In a more advanced implementation, you could use a shader or BackBufferCopy
	pass

func _remove_glow_effect() -> void:
	pass

func _cancel_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
		_tween = null

func set_enabled(enabled: bool) -> void:
	disabled = not enabled
	if disabled:
		scale = Vector2.ONE
		modulate = _original_modulate * Color(0.5, 0.5, 0.5, 1.0)
	else:
		modulate = _original_modulate

# Public methods for external control
func animate_attention() -> void:
	"""Play an attention-grabbing animation (useful for tutorial prompts)"""
	var attention_tween = create_tween().set_loops()
	attention_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.5)
	attention_tween.tween_property(self, "scale", Vector2.ONE, 0.5)

func stop_attention() -> void:
	"""Stop attention animation"""
	_cancel_tween()
	scale = Vector2.ONE
