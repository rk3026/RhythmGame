extends Node3D
# LaneLightingEffect.gd - Creates Fortnite Festival-style lane lighting on note hits
# Dynamic light strips that pulse and fade, extending beyond the hit zone

class_name LaneLightingEffect

@export var light_length: float = 8.0  # How far forward/back the light extends
@export var light_width: float = 0.8   # Width of the light strip (should match lane width)
@export var light_height: float = 0.01 # Thin strip
@export var pulse_duration: float = 0.4 # How long the light pulse lasts
@export var emission_strength: float = 3.0 # Brightness of the emissive glow
@export var pulse_forward_offset: float = 2.0  # Extends forward from hit line
@export var pulse_backward_offset: float = 6.0 # Extends backward from hit line

var light_mesh: MeshInstance3D
var material: StandardMaterial3D
var elapsed_time: float = 0.0
var is_active: bool = false
var target_color: Color = Color.WHITE

func _ready():
	_create_light_mesh()

func _create_light_mesh():
	# Create a thin quad that represents the light strip
	light_mesh = MeshInstance3D.new()
	var quad = QuadMesh.new()
	quad.size = Vector2(light_width, light_length)
	quad.orientation = PlaneMesh.FACE_Z  # Lay flat on the runway
	light_mesh.mesh = quad
	
	# Create glowing emissive material
	material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD  # Additive blending for glow
	material.emission_enabled = true
	material.emission_energy_multiplier = emission_strength
	material.albedo_color = Color.TRANSPARENT
	
	light_mesh.material_override = material
	light_mesh.visible = false
	add_child(light_mesh)

func trigger(color: Color, lane_position: Vector3):
	"""Trigger the lane lighting effect at the specified position with the given color"""
	target_color = color
	elapsed_time = 0.0
	is_active = true
	
	# Position the light strip to extend forward and backward from hit zone
	# The hit zone is at Z=0, so we offset the strip
	var strip_center_z = (pulse_forward_offset - pulse_backward_offset) / 2.0
	light_mesh.global_position = Vector3(lane_position.x, 0.05, strip_center_z)
	
	# Rotate to lay flat on runway
	light_mesh.rotation_degrees = Vector3(-90, 0, 0)
	
	light_mesh.visible = true
	material.albedo_color = color
	material.emission = color

func _process(delta):
	if not is_active:
		return
	
	elapsed_time += delta
	var progress = elapsed_time / pulse_duration
	
	if progress >= 1.0:
		# Effect finished
		is_active = false
		light_mesh.visible = false
		return
	
	# Pulse animation: quick rise, slower fall
	var intensity: float
	if progress < 0.15:
		# Fast rise
		intensity = progress / 0.15
	else:
		# Slower decay
		intensity = 1.0 - ((progress - 0.15) / 0.85)
	
	# Apply easing for smoother animation
	intensity = ease(intensity, -2.0)  # Ease out
	
	# Update material brightness
	var current_color = target_color
	current_color.a = intensity
	material.albedo_color = current_color
	material.emission = current_color * intensity * emission_strength

func reset():
	"""Reset the effect to inactive state"""
	is_active = false
	elapsed_time = 0.0
	light_mesh.visible = false
