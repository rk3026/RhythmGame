extends GPUParticles3D
# EnhancedHitEffect.gd - Modern GPU-based particle effect for note hits
# Uses Godot's GPUParticles3D for performance and visual quality

class_name EnhancedHitEffect

@export var effect_lifetime: float = 0.6
@export var explosion_power: float = 2.5
@export var particle_count: int = 20
@export var spread_angle: float = 30.0  # Degrees of upward cone spread
@export var effect_color: Color = Color.WHITE

var lifetime_elapsed: float = 0.0
var proc_mat: ParticleProcessMaterial

func _ready():
	if not proc_mat:
		setup_particles()

func setup_particles():
	# Configure particle system
	amount = particle_count
	self.lifetime = effect_lifetime
	one_shot = true
	explosiveness = 1.0  # All particles spawn at once
	fixed_fps = 60
	visibility_aabb = AABB(Vector3(-2, -2, -2), Vector3(4, 4, 4))
	
	# Create process material for particle behavior
	proc_mat = ParticleProcessMaterial.new()
	
	# Emission shape - emit from a small sphere
	proc_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	proc_mat.emission_sphere_radius = 0.1
	
	# Initial velocity - burst upward and outward
	proc_mat.direction = Vector3(0, 1, 0)
	proc_mat.spread = spread_angle
	proc_mat.initial_velocity_min = explosion_power * 0.8
	proc_mat.initial_velocity_max = explosion_power * 1.2
	
	# Gravity and damping
	proc_mat.gravity = Vector3(0, -3.0, 0)
	proc_mat.damping_min = 1.0
	proc_mat.damping_max = 2.0
	
	# Scale over lifetime (start small, grow, shrink)
	proc_mat.scale_min = 0.08
	proc_mat.scale_max = 0.25
	var scale_curve = Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.3))
	scale_curve.add_point(Vector2(0.15, 1.2))  # Pop bigger
	scale_curve.add_point(Vector2(0.6, 0.8))
	scale_curve.add_point(Vector2(1.0, 0.0))
	proc_mat.scale_curve = scale_curve
	
	# Add rotation for more dynamic movement
	proc_mat.angle_min = 0.0
	proc_mat.angle_max = 360.0
	proc_mat.angular_velocity_min = 180.0
	proc_mat.angular_velocity_max = 720.0
	
	# Color over lifetime (bright start, fade out with slight color shift)
	var gradient = Gradient.new()
	# Start bright and saturated
	var bright_color = effect_color.lightened(0.3)
	bright_color.a = 1.0
	gradient.add_point(0.0, bright_color)
	# Mid-life at normal color
	gradient.add_point(0.4, effect_color)
	# Fade to darker and transparent
	var fade_color = effect_color.darkened(0.2)
	fade_color.a = 0.0
	gradient.add_point(1.0, fade_color)
	proc_mat.color_ramp = gradient
	
	# Apply the material
	self.process_material = proc_mat
	
	# Create visual mesh for particles
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.2, 0.2)
	draw_pass_1 = quad_mesh
	
	# Create glowing material for particle mesh
	var mesh_material = StandardMaterial3D.new()
	mesh_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_material.vertex_color_use_as_albedo = true
	mesh_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mesh_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mesh_material.albedo_color = Color.WHITE
	
	# Create a circular gradient texture for soft glowing particles
	var particle_texture = _create_particle_texture()
	mesh_material.albedo_texture = particle_texture
	
	# Enable emission for extra glow
	mesh_material.emission_enabled = true
	mesh_material.emission = effect_color
	mesh_material.emission_energy_multiplier = 2.0
	
	# Apply material to the mesh
	self.draw_pass_1.surface_set_material(0, mesh_material)

func _create_particle_texture() -> ImageTexture:
	"""Create a circular gradient texture for soft glowing particles"""
	var size = 64
	var image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	
	var center = Vector2(size / 2.0, size / 2.0)
	var max_dist = size / 2.0
	
	for y in range(size):
		for x in range(size):
			var pos = Vector2(x, y)
			var dist = pos.distance_to(center)
			var normalized_dist = dist / max_dist
			
			# Create a soft circular gradient with bright center
			var alpha = 1.0 - pow(normalized_dist, 0.7)  # Softer falloff
			alpha = clamp(alpha, 0.0, 1.0)
			
			# Add a star-like pattern
			var angle = atan2(y - center.y, x - center.x)
			var star_intensity = (sin(angle * 4.0) * 0.3 + 0.7)  # 4-pointed star
			alpha *= star_intensity
			
			var color = Color(1.0, 1.0, 1.0, alpha)
			image.set_pixel(x, y, color)
	
	var texture = ImageTexture.create_from_image(image)
	return texture

func play(new_color: Color, scale_factor: float = 1.0):
	"""Trigger the particle effect with a specific color and scale"""
	effect_color = new_color
	lifetime_elapsed = 0.0
	
	# Update gradient with new color
	if proc_mat:
		var gradient = Gradient.new()
		# Start bright and saturated
		var bright_color = new_color.lightened(0.3)
		bright_color.a = 1.0
		gradient.add_point(0.0, bright_color)
		# Mid-life at normal color
		gradient.add_point(0.4, new_color)
		# Fade to darker and transparent
		var fade_color = new_color.darkened(0.2)
		fade_color.a = 0.0
		gradient.add_point(1.0, fade_color)
		proc_mat.color_ramp = gradient
	
	# Update emission color on mesh material
	if draw_pass_1 and draw_pass_1.surface_get_material(0):
		var mat = draw_pass_1.surface_get_material(0) as StandardMaterial3D
		if mat:
			mat.emission = new_color
	
	# Adjust particle count based on scale (bigger hits = more particles)
	amount = int(particle_count * scale_factor)
	
	# Adjust explosion power based on scale
	if proc_mat:
		proc_mat.initial_velocity_min = explosion_power * 0.8 * scale_factor
		proc_mat.initial_velocity_max = explosion_power * 1.2 * scale_factor
	
	# Trigger emission
	emitting = true
	restart()

func _process(delta):
	lifetime_elapsed += delta
	
	# Auto-hide when done (for pooling)
	if lifetime_elapsed >= effect_lifetime and not emitting:
		visible = false
