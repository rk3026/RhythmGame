extends MeshInstance3D

signal note_finished(note_tail)

var sustain_length: float = 0.0  # in seconds
var fret: int = 0
var note_type: int = 0  # NoteType enum from note.gd
var was_hit: bool = false
var sustain_started: bool = false
var sustain_hit_time: float = 0.0
var _next_sustain_emit_time: float = 0.0
var sustain_emit_interval: float = 0.09  # seconds between grind particles
var sustain_effect_scale: float = 0.6
var hit_effect_pool: Node = null
var _input_handler: Node = null

func _ready():
	update_visuals()

func update_visuals():
	if sustain_length > 0:
		mesh = QuadMesh.new()
		var mat = StandardMaterial3D.new()
		var colors = [Color.GREEN, Color.RED, Color.YELLOW, Color.BLUE, Color.ORANGE]
		mat.albedo_color = colors[fret] if fret < colors.size() else Color.WHITE
		# Set priority below note (1 < 2) and adjust depth draw to prevent z-fighting
		mat.render_priority = 1
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material_override = mat

		# Slight vertical lift to avoid coplanar z-fight with board surface
		var tail_z = - (sustain_length * SettingsManager.note_speed) / 2
		position = Vector3(0, 0, tail_z)
		rotation_degrees = Vector3(-90, 0, 0)
		mesh.size = Vector2(0.1, sustain_length * SettingsManager.note_speed)
	else:
		mesh = null

func _process(_delta: float):
	# Mark sustain start time once hit
	if was_hit and not sustain_started:
		sustain_started = true
		sustain_hit_time = Time.get_ticks_msec() / 1000.0

	# Time-based sustain completion
	if was_hit and sustain_started:
		var now = Time.get_ticks_msec() / 1000.0
		if now - sustain_hit_time >= sustain_length:
			emit_signal("note_finished", self)
			visible = false

	# While holding sustain at hit line, emit small grind particles
	# Require the lane key to be held to visually indicate active hold
	if was_hit and visible and hit_effect_pool and _is_lane_pressed():
		var now = Time.get_ticks_msec() / 1000.0
		if now >= _next_sustain_emit_time:
			_emit_sustain_particle()
			_next_sustain_emit_time = now + sustain_emit_interval

func _is_lane_pressed() -> bool:
	# Locate and cache InputHandler by walking up to a parent that has it as a child
	if _input_handler == null or not is_instance_valid(_input_handler):
		var node: Node = self
		while node:
			if node.has_node("InputHandler"):
				_input_handler = node.get_node("InputHandler")
				break
			node = node.get_parent()
	if _input_handler and fret >= 0 and fret < _input_handler.key_states.size():
		return _input_handler.key_states[fret]
	return true  # Fallback to true if we can't resolve input (preserves previous visuals)

func _emit_sustain_particle():
	if not hit_effect_pool or not hit_effect_pool.has_method("get_effect"):
		return
	var eff = hit_effect_pool.get_effect()
	# Place at hit line (z ~ 0) using lane x (assuming note.x remains lane x)
	var gameplay: Node = null
	if get_parent() and get_parent().get_parent():
		var p = get_parent().get_parent().get_parent() if get_parent().get_parent().get_parent() else get_parent().get_parent()
		gameplay = p
	if gameplay:
		gameplay.add_child(eff)
	eff.global_transform.origin = Vector3(get_parent().position.x, 0.2, 0.0)
	var palette = [Color.GREEN, Color.RED, Color.YELLOW, Color.BLUE, Color.ORANGE]
	var col = Color.WHITE
	if note_type == 3:  # OPEN
		col = Color(1, 0.9, 0.3)
	elif fret < palette.size():
		col = palette[fret]
	# Slightly dim continuous particles to reduce visual noise
	col = col.darkened(0.2)
	if eff.has_method("play"):
		eff.play(col, sustain_effect_scale)