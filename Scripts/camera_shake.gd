extends Node
# CameraShake.gd - Provides camera shake effects for gameplay impact feedback

class_name CameraShake

@export var target_camera: Camera3D
@export var trauma_decay_rate: float = 1.5  # How fast trauma reduces per second
@export var max_shake_offset: float = 0.15  # Maximum position offset
@export var max_shake_rotation: float = 2.0  # Maximum rotation in degrees

var trauma: float = 0.0  # 0.0 to 1.0
var base_position: Vector3
var base_rotation: Vector3
var noise_offset: float = 0.0

func _ready():
	if target_camera:
		base_position = target_camera.position
		base_rotation = target_camera.rotation_degrees

func add_trauma(amount: float):
	"""Add trauma to the camera shake. Amount should be 0.0 to 1.0"""
	trauma = min(trauma + amount, 1.0)

func _process(delta):
	if trauma <= 0.0:
		return
	
	# Decay trauma over time
	trauma = max(trauma - trauma_decay_rate * delta, 0.0)
	
	# Calculate shake using trauma squared for more impact
	var shake_amount = trauma * trauma
	noise_offset += delta * 10.0  # Advance noise for varied movement
	
	# Generate shake using sine/cosine for smooth random-like movement
	var offset_x = max_shake_offset * shake_amount * sin(noise_offset * 3.7)
	var offset_y = max_shake_offset * shake_amount * sin(noise_offset * 2.3)
	var offset_z = max_shake_offset * shake_amount * 0.3 * sin(noise_offset * 4.1)
	
	var rotation_x = max_shake_rotation * shake_amount * sin(noise_offset * 2.9)
	var rotation_y = max_shake_rotation * shake_amount * sin(noise_offset * 3.4)
	var rotation_z = max_shake_rotation * shake_amount * sin(noise_offset * 4.7)
	
	# Apply shake to camera
	if target_camera:
		target_camera.position = base_position + Vector3(offset_x, offset_y, offset_z)
		target_camera.rotation_degrees = base_rotation + Vector3(rotation_x, rotation_y, rotation_z)

func reset():
	"""Reset camera to base position/rotation"""
	trauma = 0.0
	if target_camera:
		target_camera.position = base_position
		target_camera.rotation_degrees = base_rotation
