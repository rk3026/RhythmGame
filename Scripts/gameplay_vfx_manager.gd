extends Node
# GameplayVFXManager.gd - Coordinates all visual effects for gameplay
# Integrates lane lighting, particles, camera shake, and post-processing

class_name GameplayVFXManager

# Preload custom VFX classes
const LaneLightingEffect = preload("res://Scripts/lane_lighting_effect.gd")
const EnhancedHitEffect = preload("res://Scripts/enhanced_hit_effect.gd")
const CameraShake = preload("res://Scripts/camera_shake.gd")
const PostProcessingManager = preload("res://Scripts/post_processing_manager.gd")

# References to VFX systems
@export var camera_shake: Node  # Will be CameraShake instance
@export var post_processing: Node  # Will be PostProcessingManager instance

# VFX pools
var lane_lights: Array = []
var gpu_particle_pool: Array = []
var max_pool_size: int = 30  # Increased for chord support (5 lanes x 6 effects)
var allow_pool_growth: bool = true  # Allow dynamic pool expansion

# Lane positions (should match your note lanes)
var lane_positions: Array[float] = [-1.5, -0.5, 0.5, 1.5]

# Effect intensity settings
@export_group("Intensity Settings")
@export var enable_lane_lighting: bool = true
@export var enable_gpu_particles: bool = true
@export var enable_camera_shake: bool = true
@export var enable_post_processing: bool = true

@export_group("Camera Shake Settings")
@export var light_hit_shake: float = 0.08
@export var medium_hit_shake: float = 0.12
@export var heavy_hit_shake: float = 0.18
@export var combo_milestone_shake: float = 0.15  # Every 25/50/100 combo

@export_group("Flash Settings")
@export var enable_hit_flash: bool = true
@export var perfect_hit_flash_intensity: float = 1.2
@export var good_hit_flash_intensity: float = 0.8
@export var okay_hit_flash_intensity: float = 0.5

func _ready():
	# Wait for initialize() to be called from parent
	pass

func initialize(camera: Camera3D, world_env: WorldEnvironment, num_lanes: int, lane_x_positions: Array):
	"""Initialize VFX manager with gameplay context"""
	# Update lane positions from gameplay
	lane_positions.clear()
	for x_pos in lane_x_positions:
		lane_positions.append(x_pos)
	
	# Set up camera shake reference
	if camera_shake and camera_shake is CameraShake:
		camera_shake.camera = camera
	
	# Set up post-processing reference
	if post_processing and post_processing is PostProcessingManager:
		post_processing.world_environment = world_env
	
	# Initialize effect pools
	_initialize_lane_lights()
	_initialize_particle_pool()

func _initialize_lane_lights():
	"""Create lane lighting effects for each lane"""
	# Clear any existing lights
	for light in lane_lights:
		if is_instance_valid(light):
			light.queue_free()
	lane_lights.clear()
	
	# Create lights for current lane count
	for i in range(lane_positions.size()):
		var lane_light = LaneLightingEffect.new()
		add_child(lane_light)
		lane_lights.append(lane_light)

func _initialize_particle_pool():
	"""Create pool of GPU particle effects"""
	# Start with enough particles for typical chord scenarios (5 lanes = 15 particles minimum)
	var initial_pool_size = max(15, max_pool_size / 2)
	for i in range(initial_pool_size):
		var particles = EnhancedHitEffect.new()
		particles.visible = false
		add_child(particles)
		gpu_particle_pool.append(particles)
	print("Initialized particle pool with ", initial_pool_size, " particles")

func trigger_note_hit(lane_index: int, judgement: String, color: Color):
	"""
	Main function to trigger all VFX for a note hit
	
	Args:
		lane_index: Which lane (0-3) the note was hit in
		judgement: "perfect", "great", "good", "okay", "miss"
		color: Color of the note/effect
	"""
	
	# Get lane position
	var lane_x = lane_positions[lane_index] if lane_index < lane_positions.size() else 0.0
	var lane_pos = Vector3(lane_x, 0, 0)
	
	# Determine effect intensity based on judgement
	var shake_intensity: float = 0.0
	var flash_intensity: float = 0.0
	var particle_scale: float = 1.0
	
	match judgement.to_lower():
		"perfect":
			shake_intensity = heavy_hit_shake
			flash_intensity = perfect_hit_flash_intensity
			particle_scale = 1.5
		"great":
			shake_intensity = medium_hit_shake
			flash_intensity = good_hit_flash_intensity
			particle_scale = 1.2
		"good":
			shake_intensity = light_hit_shake
			flash_intensity = okay_hit_flash_intensity
			particle_scale = 1.0
		"okay":
			shake_intensity = light_hit_shake * 0.5
			flash_intensity = okay_hit_flash_intensity * 0.5
			particle_scale = 0.8
		"miss":
			# Miss has minimal effects
			shake_intensity = 0.0
			flash_intensity = 0.0
			particle_scale = 0.5
			color = Color.GRAY
	
	# Trigger lane lighting
	if enable_lane_lighting and lane_index < lane_lights.size():
		lane_lights[lane_index].trigger(color, lane_pos)
	
	# Trigger GPU particles
	if enable_gpu_particles:
		var particles = _get_available_particle()
		if particles:
			particles.global_position = lane_pos
			particles.play(color, particle_scale)
		else:
			push_warning("Failed to get particle from pool!")
	
	# Trigger camera shake
	if enable_camera_shake and camera_shake and shake_intensity > 0.0:
		camera_shake.add_trauma(shake_intensity)
	
	# Trigger screen flash
	if enable_post_processing and enable_hit_flash and post_processing and flash_intensity > 0.0:
		post_processing.trigger_hit_flash(color, flash_intensity)

func trigger_combo_milestone(combo: int, color: Color):
	"""
	Trigger special VFX for combo milestones (25, 50, 100, etc.)
	"""
	if combo % 100 == 0:
		# Big milestone
		if camera_shake:
			camera_shake.add_trauma(combo_milestone_shake * 1.5)
		if post_processing:
			post_processing.trigger_hit_flash(color, 1.5)
	elif combo % 50 == 0:
		# Medium milestone
		if camera_shake:
			camera_shake.add_trauma(combo_milestone_shake * 1.2)
		if post_processing:
			post_processing.trigger_hit_flash(color, 1.2)
	elif combo % 25 == 0:
		# Small milestone
		if camera_shake:
			camera_shake.add_trauma(combo_milestone_shake)
		if post_processing:
			post_processing.trigger_hit_flash(color, 0.8)

func trigger_sustain_particle(_lane_index: int, color: Color, position: Vector3):
	"""
	Trigger small particles for sustain/hold notes
	"""
	if not enable_gpu_particles:
		return
	
	var particles = _get_available_particle()
	if particles:
		particles.global_position = position
		particles.particle_count = 5  # Fewer particles for sustain
		particles.play(color, 0.4)

func _get_available_particle():
	"""Get an available particle effect from the pool"""
	# First, try to find an available particle (either invisible or nearly finished)
	var REUSE_THRESHOLD = 0.5  # Can reuse if particle is 50%+ done
	
	for particle in gpu_particle_pool:
		# Particle is available if it's hidden OR mostly finished
		if not particle.visible or (particle.lifetime_elapsed >= particle.effect_lifetime * REUSE_THRESHOLD):
			particle.visible = true
			return particle
	
	# Pool exhausted - expand pool if allowed
	if allow_pool_growth and gpu_particle_pool.size() < max_pool_size:
		var new_particle = EnhancedHitEffect.new()
		new_particle.visible = false
		add_child(new_particle)
		gpu_particle_pool.append(new_particle)
		new_particle.visible = true
		print("Expanding particle pool to ", gpu_particle_pool.size(), " particles")
		return new_particle
	
	# Pool at max size and all particles are busy, find the one that's been running longest
	var oldest_particle = null
	var oldest_time = 0.0
	for particle in gpu_particle_pool:
		if particle.lifetime_elapsed > oldest_time:
			oldest_time = particle.lifetime_elapsed
			oldest_particle = particle
	
	# Return the oldest particle (or first if all are brand new)
	if oldest_particle:
		print("Warning: Reusing particle that's ", oldest_time, "s old (pool exhausted)")
	return oldest_particle if oldest_particle else gpu_particle_pool[0]

func set_vfx_enabled(enabled: bool):
	"""Enable or disable all VFX (for settings/performance)"""
	enable_lane_lighting = enabled
	enable_gpu_particles = enabled
	enable_camera_shake = enabled
	enable_post_processing = enabled

func set_lane_positions(positions: Array[float]):
	"""Update lane positions if they change"""
	lane_positions = positions
