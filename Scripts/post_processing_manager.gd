extends Node
# PostProcessingManager.gd - Manages post-processing effects like bloom, color grading, and hit flashes

class_name PostProcessingManager

@export var world_environment: WorldEnvironment
@export var flash_duration: float = 0.15
@export var flash_intensity: float = 0.3

var environment: Environment
var base_glow_intensity: float = 0.5
var base_glow_strength: float = 0.7
var flash_elapsed: float = 0.0
var is_flashing: bool = false
var flash_color: Color = Color.WHITE

func _ready():
	if not world_environment:
		# Try to find WorldEnvironment in scene
		world_environment = get_tree().get_first_node_in_group("world_environment")
	
	if world_environment and world_environment.environment:
		environment = world_environment.environment
		_setup_base_environment()
	else:
		push_warning("PostProcessingManager: No WorldEnvironment found. Creating one...")
		_create_environment()

func _create_environment():
	"""Create a WorldEnvironment with bloom/glow effects"""
	world_environment = WorldEnvironment.new()
	get_parent().add_child.call_deferred(world_environment)
	
	environment = Environment.new()
	world_environment.environment = environment
	
	# Wait for next frame to ensure world_environment is in tree
	await get_tree().process_frame
	_setup_base_environment()

func _setup_base_environment():
	"""Configure baseline post-processing effects"""
	if not environment:
		return
	
	# Enable glow (bloom effect)
	environment.glow_enabled = true
	environment.glow_intensity = base_glow_intensity
	environment.glow_strength = base_glow_strength
	environment.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	environment.glow_hdr_threshold = 0.8
	environment.glow_hdr_scale = 1.0
	
	# Optional: Adjust ambient light for better mood
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_BG
	environment.ambient_light_energy = 0.3
	
	# Optional: Add slight contrast adjustment
	environment.adjustment_enabled = true
	environment.adjustment_brightness = 1.0
	environment.adjustment_contrast = 1.05
	environment.adjustment_saturation = 1.1

func trigger_hit_flash(color: Color = Color.WHITE, intensity_multiplier: float = 1.0):
	"""Trigger a brief screen flash on note hit"""
	flash_color = color
	flash_elapsed = 0.0
	is_flashing = true
	
	# Boost glow intensity temporarily
	if environment:
		environment.glow_intensity = base_glow_intensity + (flash_intensity * intensity_multiplier)

func _process(delta):
	if not is_flashing:
		return
	
	flash_elapsed += delta
	var progress = flash_elapsed / flash_duration
	
	if progress >= 1.0:
		# Flash complete, return to base
		is_flashing = false
		if environment:
			environment.glow_intensity = base_glow_intensity
		return
	
	# Ease out the flash intensity
	var fade = 1.0 - ease(progress, -2.0)
	if environment:
		environment.glow_intensity = base_glow_intensity + (flash_intensity * fade)

func set_glow_intensity(intensity: float):
	"""Adjust base glow intensity (for settings/customization)"""
	base_glow_intensity = intensity
	if environment and not is_flashing:
		environment.glow_intensity = intensity

func enable_effects(enabled: bool):
	"""Enable or disable post-processing effects"""
	if environment:
		environment.glow_enabled = enabled
