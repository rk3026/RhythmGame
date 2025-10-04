extends Sprite3D

signal note_miss(note)
signal note_finished(note)

enum NoteType {REGULAR, HOPO, TAP, OPEN}

@export var speed: float = 10.0
var spawn_time: float
var expected_hit_time: float
var was_hit: bool = false
var note_type: NoteType = NoteType.REGULAR
var is_sustain: bool = false
var sustain_length: float = 0.0  # in seconds
var fret: int = 0
var tail: MeshInstance3D = null
var hit_effect_pool: Node = null
var _next_sustain_emit_time: float = 0.0
var sustain_emit_interval: float = 0.09 # seconds between grind particles
var sustain_effect_scale: float = 0.6
var sustain_started: bool = false
var sustain_hit_time: float = 0.0
var travel_time: float = 0.0
var reverse_mode: bool = false
var spawn_command = null

func _ready():
	# Elevated priority so it draws above board; tail will use a higher one
	render_priority = 2

func reset():
	position = Vector3.ZERO
	speed = 10.0
	spawn_time = 0.0
	expected_hit_time = 0.0
	was_hit = false
	note_type = NoteType.REGULAR
	is_sustain = false
	sustain_length = 0.0
	fret = 0
	hit_effect_pool = null
	_next_sustain_emit_time = 0.0
	sustain_started = false
	sustain_hit_time = 0.0
	travel_time = 0.0
	reverse_mode = false
	spawn_command = null
	if tail:
		tail.queue_free()
		tail = null
	texture = null
	scale = Vector3.ONE
	modulate = Color.WHITE
	visible = true
	render_priority = 2

func update_visuals():
	var texture_path = ""
	var base_path = "res://Assets/Textures/Notes/"
	
	if note_type == NoteType.OPEN:
		texture_path = base_path + "note_star.png"
	else:
		var color_suffix = ""
		match fret:
			0:
				color_suffix = "green"
			1:
				color_suffix = "red"
			2:
				color_suffix = "yellow"
			3:
				color_suffix = "blue"
			4:
				color_suffix = "orange"
			_:
				color_suffix = "green"  # fallback
		
		var type_suffix = ""
		if note_type == NoteType.HOPO or note_type == NoteType.TAP:
			type_suffix = "_h"
		
		texture_path = base_path + "note_" + color_suffix + type_suffix + ".png"
	
	if texture_path:
		texture = load(texture_path)
	
	if is_sustain:
		scale.y = 1.0 + sustain_length * speed / 10.0  # make taller based on sustain length
		modulate = Color(0.7, 0.7, 0.7)  # dimmer for sustain
		# Create or update tail
		if not tail:
			tail = MeshInstance3D.new()
			tail.mesh = QuadMesh.new()
			var mat = StandardMaterial3D.new()
			var colors = [Color.GREEN, Color.RED, Color.YELLOW, Color.BLUE, Color.ORANGE]
			mat.albedo_color = colors[fret] if fret < colors.size() else Color.WHITE
			# Set priority below note (1 < 2) and adjust depth draw to prevent z-fighting (flicker) with lane board
			mat.render_priority = 1
			mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
			mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			tail.material_override = mat
			add_child(tail)
		else:
			# Ensure existing tail material keeps proper priority (below note)
			if tail.material_override:
				tail.material_override.render_priority = 1
				tail.material_override.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_ALWAYS
		# Slight vertical lift to avoid coplanar z-fight with board surface (previously overwritten)
		var tail_z = - (sustain_length * speed) / 2
		tail.position = Vector3(0, 0, tail_z)
		tail.rotation_degrees = Vector3(-90, 0, 0)
		tail.mesh.size = Vector2(0.1, sustain_length * speed)
	else:
		scale.y = 1.0
		modulate = Color.WHITE
		if tail:
			tail.queue_free()
			tail = null

func _process(delta: float):
	# Movement respects reverse playback flag
	var dir = -1.0 if reverse_mode else 1.0
	position.z += speed * delta * dir
	# Mark sustain start time once hit
	if is_sustain and was_hit and not sustain_started:
		sustain_started = true
		sustain_hit_time = Time.get_ticks_msec() / 1000.0
	# Time-based sustain completion (prevents premature end when head leaves runway bounds)
	if is_sustain and was_hit and sustain_started:
		var now = Time.get_ticks_msec() / 1000.0
		if now - sustain_hit_time >= sustain_length:
			emit_signal("note_finished", self)
			visible = false
	elif position.z >= 5 and not was_hit and not reverse_mode:
		emit_signal("note_miss", self)
		was_hit = true
		visible = false
	# While holding sustain at hit line, emit small grind particles
	if is_sustain and was_hit and visible and hit_effect_pool:
		var now = Time.get_ticks_msec() / 1000.0
		if now >= _next_sustain_emit_time:
			_emit_sustain_particle()
			_next_sustain_emit_time = now + sustain_emit_interval

func _emit_sustain_particle():
	if not hit_effect_pool or not hit_effect_pool.has_method("get_effect"):
		return
	var eff = hit_effect_pool.get_effect()
	# Place at hit line (z ~ 0) using lane x (assuming note.x remains lane x)
	var gameplay: Node = null
	if get_parent():
		var p = get_parent().get_parent() if get_parent().get_parent() else get_parent()
		gameplay = p
	if gameplay:
		gameplay.add_child(eff)
	eff.global_transform.origin = Vector3(position.x, 0.2, 0.0)
	var palette = [Color.GREEN, Color.RED, Color.YELLOW, Color.BLUE, Color.ORANGE]
	var col = Color.WHITE
	if note_type == NoteType.OPEN:
		col = Color(1, 0.9, 0.3)
	elif fret < palette.size():
		col = palette[fret]
	# Slightly dim continuous particles to reduce visual noise
	col = col.darkened(0.2)
	if eff.has_method("play"):
		eff.play(col, sustain_effect_scale)
