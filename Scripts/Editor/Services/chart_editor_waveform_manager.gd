extends RefCounted
class_name ChartEditorWaveformManager

const DEFAULT_RUNWAY_COLOR := Color(0.2, 0.2, 0.25)
const AudioPCMExtractorScript := preload("res://Scripts/Editor/Services/audio_pcm_extractor.gd")

var runway_board_renderer: Node = null
var waveform_mesh_instance: MeshInstance3D = null
var show_waveform: bool = false
var num_lanes: int = 5
var pcm_extractor: AudioPCMExtractor
var audio_duration: float = 0.0
var hyperspeed: float = 10.0  # Will be set from editor
var current_time: float = 0.0
var waveform_data: Array = []  # Stores [time, amplitude] pairs
var last_update_time: float = 0.0
var update_interval: float = 0.033  # ~30 FPS for waveform updates (smoother than every frame)

# Waveform rendering settings
const WAVEFORM_WIDTH: float = 1.2  # Horizontal amplitude scaling (increased for visibility)
const SAMPLES_PER_POINT: int = 512  # More points for better detail
const BEAT_THRESHOLD: float = 0.15  # Amplify sounds above this threshold
const BEAT_BOOST: float = 2.5  # Multiplier for loud parts (beats)

func _init() -> void:
	pcm_extractor = AudioPCMExtractorScript.new()

func configure(renderer: Node, lane_count: int, initial_hyperspeed: float = 10.0) -> void:
	runway_board_renderer = renderer
	num_lanes = lane_count
	hyperspeed = initial_hyperspeed
	_create_waveform_mesh()
	_apply_waveform_state()

func set_hyperspeed(value: float) -> void:
	hyperspeed = value

func _create_waveform_mesh() -> void:
	if waveform_mesh_instance:
		waveform_mesh_instance.queue_free()
		waveform_mesh_instance = null
	
	if not runway_board_renderer:
		return
	
	waveform_mesh_instance = MeshInstance3D.new()
	waveform_mesh_instance.name = "WaveformLine"
	waveform_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# Add as child to runway's parent (same level as runway)
	runway_board_renderer.get_parent().add_child(waveform_mesh_instance)
	
	# Position between board (y=0) and hit zones (y=0.01), below lane separators (y=0.05)
	# Runway is horizontal (rotated -90 on X), so waveform needs same rotation
	waveform_mesh_instance.position = Vector3(0, 0.005, 0)  # Between board and hit zones
	waveform_mesh_instance.rotation_degrees = Vector3(-90, 0, 0)  # Match runway rotation
	waveform_mesh_instance.visible = false
	
	# Create material for waveform
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.4, 0.8, 1.0, 0.85)  # Slightly more transparent
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.no_depth_test = false  # Enable depth testing so it renders behind hit zones
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Show from both sides
	mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_OPAQUE_ONLY  # Proper depth sorting
	waveform_mesh_instance.material_override = mat

func set_waveform_enabled(enabled: bool) -> void:
	show_waveform = enabled
	if waveform_mesh_instance:
		waveform_mesh_instance.visible = show_waveform
	_apply_waveform_state()

func update_scroll(current_time_value: float, song_duration: float) -> void:
	current_time = current_time_value
	
	# Throttle updates to improve performance
	var current_engine_time = Time.get_ticks_msec() / 1000.0
	if current_engine_time - last_update_time < update_interval:
		return
	
	last_update_time = current_engine_time
	
	if waveform_data.size() > 0 and waveform_mesh_instance:
		_update_waveform_positions()

func regenerate_waveform(audio_stream: AudioStream, source_path: String = "") -> void:
	if not audio_stream:
		return
	
	print("=== GENERATING WAVEFORM (MOONSCRAPER STYLE) ===")
	var pcm_data = pcm_extractor.extract(audio_stream, source_path)
	if pcm_data.is_empty():
		print("ERROR: No PCM data")
		return
	
	# Get audio properties
	var sample_rate: int = 44100
	if audio_stream and audio_stream.get_class() == "AudioStreamWAV":
		sample_rate = audio_stream.mix_rate
	elif ClassDB.class_exists("MiniaudioDecoder"):
		var decoder = ClassDB.instantiate("MiniaudioDecoder")
		if decoder:
			var temp_samples = decoder.extract_pcm(source_path)
			if temp_samples.size() > 0:
				sample_rate = decoder.get_sample_rate()
	
	var total_samples: int = pcm_data.size()
	audio_duration = float(total_samples) / float(sample_rate)
	
	print("Samples: %d, Sample rate: %d Hz, Duration: %.2f sec" % [total_samples, sample_rate, audio_duration])
	
	# Downsample to create line points
	var num_points: int = max(2, int(float(total_samples) / float(SAMPLES_PER_POINT)))
	var points: PackedVector3Array = []
	points.resize(num_points)
	
	print("Creating %d waveform points" % num_points)
	
	# Store time/amplitude data
	waveform_data.clear()
	for i in range(num_points):
		# Calculate which samples this point represents
		var sample_start: int = i * SAMPLES_PER_POINT
		var sample_end: int = min(sample_start + SAMPLES_PER_POINT, total_samples)
		
		# Calculate RMS (Root Mean Square) for this window - better represents perceived loudness
		var sum_squares: float = 0.0
		var max_amp: float = 0.0
		for j in range(sample_start, sample_end):
			var amp = abs(pcm_data[j])
			sum_squares += amp * amp
			if amp > max_amp:
				max_amp = amp
		
		var sample_count = sample_end - sample_start
		var rms = sqrt(sum_squares / float(sample_count)) if sample_count > 0 else 0.0
		
		# Use weighted average of RMS and peak for better beat detection
		var combined_amp = (rms * 0.7) + (max_amp * 0.3)
		
		# Calculate time for this point
		var time: float = float(sample_start) / float(sample_rate)
		
		# Dynamic range compression: boost loud parts (beats) more
		var scaled_amp: float
		if combined_amp > BEAT_THRESHOLD:
			# Apply stronger boost to beats
			scaled_amp = (BEAT_THRESHOLD + (combined_amp - BEAT_THRESHOLD) * BEAT_BOOST) * WAVEFORM_WIDTH
		else:
			# Keep quiet parts quieter
			scaled_amp = combined_amp * WAVEFORM_WIDTH * 0.5
		
		# Clamp to prevent extreme values
		scaled_amp = clamp(scaled_amp, 0.0, WAVEFORM_WIDTH * 1.5)
		
		waveform_data.append({"time": time, "amplitude": scaled_amp})
	
	# Create initial mesh
	_update_waveform_positions()
	
	if waveform_mesh_instance:
		waveform_mesh_instance.visible = show_waveform
	
	print("Waveform generated successfully")
	print("=======================================")

func _update_waveform_positions() -> void:
	if waveform_data.size() < 2:
		return
	
	# Only show waveform points in visible range for performance
	var note_speed = SettingsManager.note_speed if SettingsManager else 20.0
	var visible_range = 15.0  # seconds of waveform to show
	var min_time = current_time - 2.0
	var max_time = current_time + visible_range
	
	# Convert time/amplitude data to world positions
	var points: PackedVector3Array = []
	points.resize(waveform_data.size())
		
	# Only process visible points
	var visible_points: PackedVector3Array = []
	for i in range(waveform_data.size()):
		var data = waveform_data[i]
		
		# Skip points outside visible range
		if data.time < min_time or data.time > max_time:
			continue
		
		var time_diff = data.time - current_time
		
		# Position in LOCAL space (before -90 X rotation)
		# X = amplitude (left/right)
		# Y = time position along runway (will become Z after rotation)
		# Z = height (stays 0 on runway surface)
		var local_y = time_diff * note_speed  # Positive to move towards screen
		
		visible_points.append(Vector3(data.amplitude, local_y, 0))
	
	if visible_points.size() < 2:
		return
	
	_create_line_mesh(visible_points)

func _create_line_mesh(points: PackedVector3Array) -> void:
	if not waveform_mesh_instance or points.size() < 2:
		return
	
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	# Create vertices (each line segment needs 2 vertices per point for width)
	var vertices: PackedVector3Array = []
	var colors: PackedColorArray = []
	var indices: PackedInt32Array = []
	
	const LINE_WIDTH: float = 0.02
	var color = Color(0.4, 0.8, 1.0, 0.95)
	
	for i in range(points.size()):
		var point = points[i]
		
		# Create a quad for this waveform segment
		# In local space: X = left/right, Y = forward (timeline), Z = up
		# Left side (negative X)
		var left = Vector3(-point.x, point.y, 0)
		# Right side (positive X)  
		var right = Vector3(point.x, point.y, 0)
		
		# Add vertices
		var vert_index = vertices.size()
		vertices.append(left)
		vertices.append(right)
		colors.append(color)
		colors.append(color)
		
		# Connect to previous point to form triangles
		if i > 0:
			# Previous vertices
			var prev_left = vert_index - 2
			var prev_right = vert_index - 1
			# Current vertices
			var curr_left = vert_index
			var curr_right = vert_index + 1
			
			# Triangle 1
			indices.append(prev_left)
			indices.append(prev_right)
			indices.append(curr_left)
			
			# Triangle 2
			indices.append(prev_right)
			indices.append(curr_right)
			indices.append(curr_left)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	waveform_mesh_instance.mesh = mesh

func _apply_waveform_state() -> void:
	var material = _get_runway_material()
	if not material:
		return
	if show_waveform and not waveform_mesh_instance:
		material.albedo_texture = null
		material.albedo_color = DEFAULT_RUNWAY_COLOR
		material.uv1_scale = Vector3(num_lanes, 1, 1)
		material.uv1_offset = Vector3.ZERO
	else:
		material.albedo_texture = null
		material.albedo_color = DEFAULT_RUNWAY_COLOR
		material.uv1_scale = Vector3(num_lanes, 1, 1)
		material.uv1_offset = Vector3.ZERO

func _get_runway_material() -> BaseMaterial3D:
	if not runway_board_renderer:
		return null
	return runway_board_renderer.get_surface_override_material(0)


