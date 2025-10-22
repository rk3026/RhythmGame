class_name FileSystemHelper
extends RefCounted

## FileSystemHelper - Static utility methods for file system operations
## Eliminates duplicate directory traversal code across the codebase

## Find the first file in a directory matching any of the given extensions
## @param folder_path: Absolute path to the directory to search
## @param extensions: Array of file extensions to match (e.g., ["ogg", "mp3"])
## @return: Full path to the first matching file, or empty string if none found
static func find_file_by_extensions(folder_path: String, extensions: Array) -> String:
	# Ensure folder_path ends with /
	if not folder_path.ends_with("/"):
		folder_path += "/"
	
	var dir = DirAccess.open(folder_path)
	if not dir:
		return ""
	
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
## @param folder_path: Absolute path to the directory to search
## @return: Full path to audio file, or empty string if none found
static func find_audio_file(folder_path: String) -> String:
	return find_file_by_extensions(folder_path, ["ogg"])

## Find an image file in the given directory
## Searches for common image formats (.png, .jpg, .jpeg)
## @param folder_path: Absolute path to the directory to search
## @return: Full path to image file, or empty string if none found
static func find_image_file(folder_path: String) -> String:
	return find_file_by_extensions(folder_path, ["png", "jpg", "jpeg"])

## Find a chart file in the given directory
## Searches for supported chart formats (.chart, .mid, .midi)
## @param folder_path: Absolute path to the directory to search
## @return: Full path to chart file, or empty string if none found
static func find_chart_file(folder_path: String) -> String:
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
## @param folder_path: Absolute path to the directory to search
## @return: Array of directory names (not full paths)
static func list_subdirectories(folder_path: String) -> Array:
	var results = []
	var dir = DirAccess.open(folder_path)
	if not dir:
		return results
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			results.append(file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return results
