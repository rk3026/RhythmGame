extends Node

# ResourceCache.gd - Preloads and caches resources for better performance

var texture_cache: Dictionary = {}
var audio_cache: Dictionary = {}
var chart_cache: Dictionary = {}

func _ready():
	preload_common_textures()

func preload_common_textures():
	# Preload note textures (using actual file names)
	var note_textures = [
		"res://Assets/Textures/Notes/note_green.png",
		"res://Assets/Textures/Notes/note_red.png", 
		"res://Assets/Textures/Notes/note_yellow.png",
		"res://Assets/Textures/Notes/note_blue.png",
		"res://Assets/Textures/Notes/note_orange.png",
		"res://Assets/Textures/Notes/note_star.png",
		# HOPO versions
		"res://Assets/Textures/Notes/note_green_h.png",
		"res://Assets/Textures/Notes/note_red_h.png",
		"res://Assets/Textures/Notes/note_yellow_h.png",
		"res://Assets/Textures/Notes/note_blue_h.png",
		"res://Assets/Textures/Notes/note_orange_h.png",
		"res://Assets/Textures/Notes/note_star_h.png"
	]
	
	for texture_path in note_textures:
		if ResourceLoader.exists(texture_path):
			texture_cache[texture_path] = load(texture_path)
		else:
			push_warning("Texture not found: " + texture_path)
	
	# Preload UI textures that actually exist
	var ui_textures = [
		"res://Assets/Textures/Generic/bar.png",
		"res://Assets/Textures/Generic/bar2.png",
		"res://Assets/Textures/Generic/Circle.png"
	]
	
	for texture_path in ui_textures:
		if ResourceLoader.exists(texture_path):
			texture_cache[texture_path] = load(texture_path)

func get_texture(path: String) -> Texture2D:
	if texture_cache.has(path):
		return texture_cache[path]
	
	# Load on demand if not cached
	if ResourceLoader.exists(path):
		var texture = load(path)
		texture_cache[path] = texture
		return texture
	
	push_error("Texture not found: " + path)
	return null

func preload_audio(path: String) -> AudioStream:
	if audio_cache.has(path):
		return audio_cache[path]
	
	if not ResourceLoader.exists(path):
		push_error("Audio file not found: " + path)
		return null
	
	var audio = load(path)
	audio_cache[path] = audio
	return audio

func cache_chart(chart_path: String, sections: Dictionary):
	chart_cache[chart_path] = sections

func get_cached_chart(chart_path: String) -> Dictionary:
	return chart_cache.get(chart_path, {})

func clear_cache():
	texture_cache.clear()
	audio_cache.clear()
	chart_cache.clear()

func get_cache_stats() -> Dictionary:
	return {
		"textures": texture_cache.size(),
		"audio": audio_cache.size(), 
		"charts": chart_cache.size()
	}