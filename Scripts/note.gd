extends Sprite3D

signal note_miss(note)
signal note_finished(note)

var spawn_time: float
var expected_hit_time: float
var was_hit: bool = false:
	set(value):
		was_hit = value
		if tail_instance:
			tail_instance.was_hit = value
var was_missed: bool = false  # Tracks if note was actively or passively missed
var note_type: NoteType.Type = NoteType.Type.REGULAR
var is_sustain: bool = false
var sustain_length: float = 0.0  # in seconds
var fret: int = 0
var tail_instance: Node = null
var hit_effect_pool: Node = null
var travel_time: float = 0.0
var reverse_mode: bool = false
var spawn_command = null
var movement_paused: bool = false  # Set externally by spawner to control movement
var use_timeline_positioning: bool = false  # If true, spawner handles positioning, not delta movement
var is_selected: bool = false : set = set_selected

var _selection_indicator: MeshInstance3D = null

func _get_visual_size() -> Vector2:
	# Convert texture pixel size into world units using Sprite3D.pixel_size
	if texture:
		var tex_size: Vector2 = texture.get_size()
		return tex_size * pixel_size
	return Vector2(0.8, 0.8)

func _ready():
	# Elevated priority so it draws above board; tail will use a higher one
	render_priority = 2

func reset():
	position = Vector3.ZERO
	spawn_time = 0.0
	expected_hit_time = 0.0
	was_hit = false
	was_missed = false
	note_type = NoteType.Type.REGULAR
	is_sustain = false
	sustain_length = 0.0
	fret = 0
	hit_effect_pool = null
	travel_time = 0.0
	reverse_mode = false
	spawn_command = null
	movement_paused = false
	use_timeline_positioning = false
	is_selected = false
	if tail_instance:
		tail_instance.queue_free()
		tail_instance = null
	texture = null
	scale = Vector3.ONE
	modulate = Color.WHITE
	visible = true
	render_priority = 2
	if _selection_indicator:
		_selection_indicator.visible = false

func update_visuals():
	var texture_path = ""
	var base_path = "res://Assets/Textures/Notes/"
	scale = Vector3.ONE
	
	if note_type == NoteType.Type.OPEN:
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
		
		var type_suffix = NoteType.get_texture_suffix(note_type)
		
		texture_path = base_path + "note_" + color_suffix + type_suffix + ".png"
	
	if texture_path:
		texture = load(texture_path)
	
	if is_sustain:
		modulate = Color(0.7, 0.7, 0.7)  # dimmer for sustain
		# Create or update tail instance
		if not tail_instance:
			var tail_scene = load("res://Scenes/note_tail.tscn")
			tail_instance = tail_scene.instantiate()
			add_child(tail_instance)
			tail_instance.connect("note_finished", Callable(self, "_on_tail_finished"))
		# Update tail properties
		tail_instance.sustain_length = sustain_length
		tail_instance.fret = fret
		tail_instance.note_type = note_type
		tail_instance.hit_effect_pool = hit_effect_pool
		tail_instance.was_hit = was_hit
		tail_instance.update_visuals()
	else:
		modulate = Color.WHITE
		if tail_instance:
			tail_instance.queue_free()
			tail_instance = null
	_update_selection_visuals()

func _process(delta: float):
	# Only use delta-based movement if NOT using timeline positioning
	# (timeline positioning is handled by spawner calling reposition_active_notes)
	if not use_timeline_positioning and not movement_paused:
		var dir = -1.0 if reverse_mode else 1.0
		position.z += SettingsManager.note_speed * delta * dir

	# Passive miss: note passed the hit zone without being hit
	if position.z >= 5 and not was_hit and not was_missed and not reverse_mode and not use_timeline_positioning:
		was_missed = true
		emit_signal("note_miss", self)
		visible = false
		if tail_instance:
			tail_instance.visible = false

func set_selected(selected: bool):
	is_selected = selected
	_update_selection_visuals()

func _ensure_selection_indicator():
	if _selection_indicator:
		return
	_selection_indicator = MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = _get_visual_size() * 1.05
	_selection_indicator.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.9, 1.0, 0.45)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.no_depth_test = true
	mat.render_priority = 4
	_selection_indicator.material_override = mat
	_selection_indicator.position = Vector3(0, 0, 0.01)
	add_child(_selection_indicator)

func _resize_selection_indicator():
	if not _selection_indicator:
		return
	var mesh := _selection_indicator.mesh
	if mesh is QuadMesh:
		mesh.size = _get_visual_size() * 1.05

func _update_selection_visuals():
	if is_selected:
		_ensure_selection_indicator()
		_resize_selection_indicator()
		_selection_indicator.visible = true
	else:
		if _selection_indicator:
			_selection_indicator.visible = false
	if tail_instance and tail_instance.has_method("set_selected"):
		tail_instance.set_selected(is_selected)

func _on_tail_finished(_tail):
	emit_signal("note_finished", self)
	visible = false
