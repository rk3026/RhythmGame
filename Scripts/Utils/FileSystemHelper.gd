class_name FileSystemHelper
extends RefCounted

## FileSystemHelper - Static utility methods for file system operations
## Eliminates duplicate directory traversal code across the codebase
## 
## NOTE: In exported builds, DirAccess.open() may not reliably list files in res://
## paths because they are packed. This class handles both editor and export scenarios
## by first checking common filenames, then falling back to directory scanning.

## Common audio filenames used by Clone Hero/rhythm game charts
const COMMON_AUDIO_FILES = [
	"song.ogg", "guitar.ogg", "bass.ogg", "drums.ogg", "vocals.ogg", 
	"keys.ogg", "rhythm.ogg", "crowd.ogg", "preview.ogg",
	"drums_1.ogg", "drums_2.ogg", "drums_3.ogg", "drums_4.ogg",
	"song.opus", "guitar.opus", "bass.opus", "drums.opus", "vocals.opus",
	"song.mp3", "guitar.mp3", "preview.mp3"
]

## Common image filenames used by Clone Hero/rhythm game charts
const COMMON_IMAGE_FILES = [
	"album.png", "album.jpg", "album.jpeg",
	"background.png", "background.jpg", "background.jpeg", 
	"cover.png", "cover.jpg", "cover.jpeg",
	"jacket.png", "jacket.jpg", "jacket.jpeg"
]

## Find the first file in a directory matching any of the given extensions
## @param folder_path: Absolute path to the directory to search
## @param extensions: Array of file extensions to match (e.g., ["ogg", "mp3"])
## @return: Full path to the first matching file, or empty string if none found
static func find_file_by_extensions(folder_path: String, extensions: Array) -> String:
	# Ensure folder_path ends with /
	if not folder_path.ends_with("/"):
		folder_path += "/"
	
	# First try directory scanning (works in editor)
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir():
				var extension = file_name.get_extension().to_lower()
				if extension in extensions:
					dir.list_dir_end()
					return folder_path + file_name
			file_name = dir.get_next()
		dir.list_dir_end()
	
	return ""

## Find an audio file in the given directory
## Searches for .ogg files (primary audio format for Godot)
## In exported builds, checks common filenames directly
## @param folder_path: Absolute path to the directory to search
## @return: Full path to audio file, or empty string if none found
static func find_audio_file(folder_path: String) -> String:
	if not folder_path.ends_with("/"):
		folder_path += "/"
	
	# First check common audio filenames (works in both editor and export)
	for file_name in COMMON_AUDIO_FILES:
		var full_path = folder_path + file_name
		if ResourceLoader.exists(full_path):
			return full_path
	
	# Fall back to directory scanning (editor only)
	return find_file_by_extensions(folder_path, ["ogg", "opus", "mp3"])

## Find an image file in the given directory
## Searches for common image formats (.png, .jpg, .jpeg)
## In exported builds, checks common filenames directly
## @param folder_path: Absolute path to the directory to search
## @return: Full path to image file, or empty string if none found
static func find_image_file(folder_path: String) -> String:
	if not folder_path.ends_with("/"):
		folder_path += "/"
	
	# First check common image filenames (works in both editor and export)
	for file_name in COMMON_IMAGE_FILES:
		var full_path = folder_path + file_name
		if ResourceLoader.exists(full_path):
			return full_path
	
	# Fall back to directory scanning (editor only)
	return find_file_by_extensions(folder_path, ["png", "jpg", "jpeg"])

## Find a chart file in the given directory
## Searches for supported chart formats (.chart, .mid, .midi)
## @param folder_path: Absolute path to the directory to search
## @return: Full path to chart file, or empty string if none found
static func find_chart_file(folder_path: String) -> String:
	if not folder_path.ends_with("/"):
		folder_path += "/"
	
	# Check common chart filenames first (works in both editor and export)
	var common_chart_files = ["notes.chart", "notes.mid", "notes.midi", "song.chart", "song.mid", "song.midi"]
	for file_name in common_chart_files:
		var full_path = folder_path + file_name
		if ResourceLoader.exists(full_path):
			return full_path
	
	# Fall back to directory scanning (editor only)
	return find_file_by_extensions(folder_path, ["chart", "mid", "midi"])

## Check if a file with the given extensions exists in a directory
## @param folder_path: Absolute path to the directory to search
## @param extensions: Array of file extensions to match
## @return: true if at least one matching file exists, false otherwise
static func has_file_with_extensions(folder_path: String, extensions: Array) -> bool:
	return not find_file_by_extensions(folder_path, extensions).is_empty()

## List all files in a directory matching the given extensions
## @param folder_path: Absolute path to the directory to search
## @param extensions: Array of file extensions to match
## @return: Array of full paths to matching files
static func list_files_by_extensions(folder_path: String, extensions: Array) -> Array:
	# Ensure folder_path ends with /
	if not folder_path.ends_with("/"):
		folder_path += "/"
	
	var results = []
	var dir = DirAccess.open(folder_path)
	if not dir:
		return results
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir():
			var extension = file_name.get_extension().to_lower()
			if extension in extensions:
				results.append(folder_path + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return results

## List all subdirectories in a directory
## In exported builds, falls back to reading song_manifest.json if directory scanning fails
## @param folder_path: Absolute path to the directory to search
## @return: Array of directory names (not full paths)
static func list_subdirectories(folder_path: String) -> Array:
	var results = []
	
	# Try directory scanning first (works in editor and sometimes in exports)
	var dir = DirAccess.open(folder_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				results.append(file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	
	# If we found results via DirAccess, return them
	if not results.is_empty():
		return results
	
	# Fall back to song manifest for Tracks folder (exported builds)
	if folder_path.contains("Assets/Tracks"):
		results = _load_song_manifest()
	
	return results

## Load song folder names from manifest file (for exported builds)
static func _load_song_manifest() -> Array:
	var manifest_path = "res://Assets/Tracks/song_manifest.json"
	if not ResourceLoader.exists(manifest_path):
		push_warning("FileSystemHelper: song_manifest.json not found")
		return []
	
	var file = FileAccess.open(manifest_path, FileAccess.READ)
	if not file:
		push_warning("FileSystemHelper: Failed to open song_manifest.json")
		return []
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("FileSystemHelper: Failed to parse song_manifest.json: " + json.get_error_message())
		return []
	
	var data = json.get_data()
	if data is Dictionary and data.has("songs"):
		return data["songs"]
	
	return []
