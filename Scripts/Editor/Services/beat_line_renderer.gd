class_name BeatLineRenderer
extends Node

## BeatLineRenderer - Draws beat grid lines on the chart editor runway
## Provides visual feedback for BPM-based snapping

var runway_viewport: Control = null
var camera_3d: Camera3D = null
var note_speed: float = 20.0
var current_time: float = 0.0
var viewport_height: float = 600.0

# Line rendering settings - ENHANCED VISIBILITY
var measure_line_color: Color = Color(1.0, 1.0, 1.0, 0.9)  # Bright white, very opaque
var beat_line_color: Color = Color(0.8, 0.8, 0.8, 0.7)     # Light gray, more opaque
var subdivision_line_color: Color = Color(0.6, 0.6, 0.6, 0.4)  # Medium gray, visible
var measure_line_width: float = 5.0  # Thicker for measures
var beat_line_width: float = 3.0     # Thicker for beats
var subdivision_line_width: float = 1.5  # Slightly thicker for subdivisions

# Tempo data
var tempo_events: Array = []
var time_signatures: Array = []
var resolution: int = 192
var snap_division: int = 16

# Cached line mesh
var line_mesh_instance: MeshInstance3D = null
var line_material: StandardMaterial3D = null

func configure(params: Dictionary) -> void:
	runway_viewport = params.get("runway_viewport")
	camera_3d = params.get("camera")
	note_speed = params.get("note_speed", 20.0)
	viewport_height = params.get("viewport_height", 600.0)
	
	_setup_line_renderer()

func set_tempo_events(events: Array) -> void:
	tempo_events = events.duplicate(true)

func set_time_signatures(signatures: Array) -> void:
	time_signatures = signatures.duplicate(true)

func set_resolution(res: int) -> void:
	resolution = max(res, 1)

func set_snap_division(division: int) -> void:
	snap_division = max(division, 1)

func set_current_time(time: float) -> void:
	current_time = time
	_update_beat_lines()

func set_note_speed(speed: float) -> void:
	note_speed = speed
	_update_beat_lines()

func _setup_line_renderer() -> void:
	if not runway_viewport:
		print("ERROR: runway_viewport is null!")
		return
	
	var viewport: SubViewport = runway_viewport.get_node("SubViewport")
	if not viewport:
		print("ERROR: Could not find SubViewport!")
		return
	
	# Create a MeshInstance3D to hold the beat lines
	line_mesh_instance = MeshInstance3D.new()
	line_material = StandardMaterial3D.new()
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.vertex_color_use_as_albedo = true
	line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_material.no_depth_test = true  # Always render on top
	line_material.disable_receive_shadows = true
	line_material.cull_mode = BaseMaterial3D.CULL_DISABLED  # Render both sides
	line_mesh_instance.material_override = line_material
	line_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	line_mesh_instance.position = Vector3(0, 0, 0)  # Position in world space
	viewport.add_child(line_mesh_instance)

func _update_beat_lines() -> void:
	if not line_mesh_instance:
		return
	
	# Calculate visible time range - show much more than just viewport
	var visible_duration: float = 20.0  # Show 20 seconds ahead
	var start_time: float = max(0.0, current_time - 2.0)  # 2 seconds behind
	var end_time: float = current_time + visible_duration  # 20 seconds ahead
	
	# Generate beat line positions
	var line_data: Array = _generate_beat_line_data(start_time, end_time)
	
	if line_data.is_empty():
		print("WARNING: No beat line data generated (tempo_events: ", tempo_events.size(), ")")
	
	# Create mesh from line data
	var mesh: ImmediateMesh = ImmediateMesh.new()
	_draw_lines_to_mesh(mesh, line_data)
	line_mesh_instance.mesh = mesh
	
func _generate_beat_line_data(start_time: float, end_time: float) -> Array:
	var lines: Array = []
	
	if tempo_events.is_empty():
		return lines
	
	# Convert time range to tick range
	var start_tick: int = TempoCalculator.time_to_tick(start_time, tempo_events, resolution)
	var end_tick: int = TempoCalculator.time_to_tick(end_time, tempo_events, resolution)
	
	# Calculate ticks per subdivision based on snap division
	var ticks_per_beat: int = resolution
	var ticks_per_subdivision: int = ticks_per_beat / (snap_division / 4)
	if ticks_per_subdivision < 1:
		ticks_per_subdivision = 1
	
	# Snap start tick to subdivision grid
	start_tick = (start_tick / ticks_per_subdivision) * ticks_per_subdivision
	
	# Generate lines for each subdivision
	var current_tick: int = start_tick
	while current_tick <= end_tick:
		var time: float = TempoCalculator.tick_to_time(current_tick, tempo_events, resolution)
		var line_type: String = _get_line_type(current_tick, ticks_per_beat)
		
		lines.append({
			"time": time,
			"type": line_type,
			"tick": current_tick
		})
		
		current_tick += ticks_per_subdivision
	
	return lines

func _get_line_type(tick: int, ticks_per_beat: int) -> String:
	# Determine time signature at this tick
	var time_sig_numerator: int = 4
	for sig in time_signatures:
		if sig.get("tick", 0) <= tick:
			time_sig_numerator = sig.get("numerator", 4)
		else:
			break
	
	var ticks_per_measure: int = ticks_per_beat * time_sig_numerator
	
	# Check if this is a measure line
	if tick % ticks_per_measure == 0:
		return "measure"
	
	# Check if this is a beat line
	if tick % ticks_per_beat == 0:
		return "beat"
	
	# Otherwise it's a subdivision line
	return "subdivision"

func _draw_lines_to_mesh(mesh: ImmediateMesh, line_data: Array) -> void:
	if line_data.is_empty():
		return
	
	# Start drawing lines
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var lines_drawn: int = 0
	for line in line_data:
		var time: float = line.get("time", 0.0)
		var line_type: String = line.get("type", "subdivision")
		
		# Calculate Z position based on time relative to current time
		# Negative because future notes (time > current_time) should be at negative Z (towards camera)
		var time_diff: float = time - current_time
		var z_pos: float = time_diff * -note_speed
		
		# Skip if line is way out of visible range (runway is ~60 units deep)
		if z_pos < -80.0 or z_pos > 30.0:
			continue
		
		# Determine line appearance
		var color: Color = subdivision_line_color
		var width_scale: float = subdivision_line_width
		
		match line_type:
			"measure":
				color = measure_line_color
				width_scale = measure_line_width
			"beat":
				color = beat_line_color
				width_scale = beat_line_width
		
		# Draw line across entire runway width (runway is 10 units wide: -5 to +5)
		var x_start: float = -5.0
		var x_end: float = 5.0
		var y_pos: float = 0.1  # Well above runway surface to be visible
		
		# Draw simple line (PRIMITIVE_LINES doesn't support thickness)
		_draw_simple_line(mesh, 
			Vector3(x_start, y_pos, z_pos),
			Vector3(x_end, y_pos, z_pos),
			color
		)
		lines_drawn += 1
	
	# Finalize the mesh
	mesh.surface_end()

func _draw_simple_line(mesh: ImmediateMesh, start: Vector3, end: Vector3, color: Color) -> void:
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(start)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(end)

func _process(delta: float) -> void:
	# Updates are handled externally via set_current_time from chart_editor
	pass

func cleanup() -> void:
	if line_mesh_instance:
		line_mesh_instance.queue_free()
		line_mesh_instance = null
