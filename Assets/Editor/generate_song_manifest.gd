@tool
extends EditorScript

## Run this script from the Godot editor (Script -> Run) to regenerate
## the song_manifest.json file with all song folders in Assets/Tracks

func _run():
	var tracks_path = "res://Assets/Tracks"
	var manifest_path = "res://Assets/Tracks/song_manifest.json"
	
	var songs = []
	var dir = DirAccess.open(tracks_path)
	
	if not dir:
		push_error("Failed to open Tracks directory: " + tracks_path)
		return
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and folder_name != "." and folder_name != "..":
			songs.append(folder_name)
		folder_name = dir.get_next()
	
	dir.list_dir_end()
	
	# Sort alphabetically
	songs.sort()
	
	# Create manifest JSON
	var manifest = {
		"version": 1,
		"generated": Time.get_datetime_string_from_system(),
		"songs": songs
	}
	
	var json_string = JSON.stringify(manifest, "  ")
	
	var file = FileAccess.open(manifest_path, FileAccess.WRITE)
	if not file:
		push_error("Failed to write manifest file: " + manifest_path)
		return
	
	file.store_string(json_string)
	file.close()
	
	print("Song manifest generated with ", songs.size(), " songs:")
	for song in songs:
		print("  - ", song)
	print("Saved to: ", manifest_path)
