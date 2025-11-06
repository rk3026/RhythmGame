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
	if tail_instance:
		tail_instance.queue_free()
		tail_instance = null
	texture = null
	scale = Vector3.ONE
	modulate = Color.WHITE
	visible = true
	render_priority = 2

func update_visuals():
	var texture_path = ""
	var base_path = "res://Assets/Textures/Notes/"
	
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
		scale.y = 1.0 + sustain_length * SettingsManager.note_speed / 10.0  # make taller based on sustain length
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
		scale.y = 1.0
		modulate = Color.WHITE
		if tail_instance:
			tail_instance.queue_free()
			tail_instance = null

func _process(delta: float):
	# Check if we should move (only during active playback)
	var spawner = get_parent()
	var should_move = true
	if spawner and spawner.has_method("is_movement_paused"):
		should_move = not spawner.is_movement_paused()
	
	# Movement respects reverse playback flag and pause state
	if should_move:
		var dir = -1.0 if reverse_mode else 1.0
		position.z += SettingsManager.note_speed * delta * dir

	# Passive miss: note passed the hit zone without being hit
	if position.z >= 5 and not was_hit and not was_missed and not reverse_mode:
		was_missed = true
		emit_signal("note_miss", self)
		visible = false
		if tail_instance:
			tail_instance.visible = false

func _on_tail_finished(_tail):
	emit_signal("note_finished", self)
	visible = false
