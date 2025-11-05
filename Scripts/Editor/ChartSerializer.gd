extends RefCounted
class_name ChartSerializer
## Chart Serializer
## Handles saving and loading chart data to/from .rgchart files (JSON format)

const FILE_VERSION = "1.0"
const FILE_EXTENSION = ".rgchart"

static func save_chart(chart_data: ChartDataModel, file_path: String) -> Error:
	"""Save chart data to a .rgchart file"""
	if not file_path.ends_with(FILE_EXTENSION):
		file_path += FILE_EXTENSION
	
	var save_data = _serialize_chart(chart_data)
	var json_string = JSON.stringify(save_data, "\t")
	
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var error = FileAccess.get_open_error()
		push_error("Failed to save chart to %s: %s" % [file_path, error_string(error)])
		return error
	
	file.store_string(json_string)
	file.close()
	
	print("Chart saved to: ", file_path)
	return OK

static func load_chart(file_path: String) -> ChartDataModel:
	"""Load chart data from a .rgchart file"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var error = FileAccess.get_open_error()
		push_error("Failed to load chart from %s: %s" % [file_path, error_string(error)])
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		push_error("Failed to parse chart JSON at line %d: %s" % [json.get_error_line(), json.get_error_message()])
		return null
	
	var data = json.get_data()
	if not _validate_chart_data(data):
		push_error("Invalid chart data structure in file: %s" % file_path)
		return null
	
	var chart_data = _deserialize_chart(data)
	print("Chart loaded from: ", file_path)
	return chart_data

static func _serialize_chart(chart_data: ChartDataModel) -> Dictionary:
	"""Convert ChartDataModel to Dictionary for JSON serialization"""
	var data = {
		"version": FILE_VERSION,
		"metadata": chart_data.get_all_metadata(),
		"resolution": chart_data.resolution,
		"bpm_changes": [],
		"time_signatures": [],
		"charts": {}
	}
	
	# Serialize BPM changes
	for bpm_change in chart_data.bpm_changes:
		data["bpm_changes"].append({
			"tick": bpm_change["tick"],
			"bpm": bpm_change["bpm"]
		})
	
	# Serialize time signatures
	for time_sig in chart_data.time_signatures:
		data["time_signatures"].append({
			"tick": time_sig["tick"],
			"numerator": time_sig["numerator"],
			"denominator": time_sig["denominator"]
		})
	
	# Serialize charts (instrument/difficulty/notes)
	for instrument in chart_data.charts:
		data["charts"][instrument] = {}
		for difficulty in chart_data.charts[instrument]:
			var chart = chart_data.charts[instrument][difficulty]
			data["charts"][instrument][difficulty] = {
				"notes": [],
				"events": []
			}
			
			# Serialize notes
			for note in chart.notes:
				data["charts"][instrument][difficulty]["notes"].append({
					"id": note["id"],
					"tick": note["tick"],
					"lane": note["lane"],
					"type": note["type"],
					"length": note["length"]
				})
			
			# Serialize events
			for event in chart.events:
				data["charts"][instrument][difficulty]["events"].append(event.duplicate())
	
	return data

static func _deserialize_chart(data: Dictionary) -> ChartDataModel:
	"""Convert Dictionary from JSON to ChartDataModel"""
	var chart_data = ChartDataModel.new()
	
	# Restore metadata
	if "metadata" in data:
		for key in data["metadata"]:
			chart_data.set_metadata(key, data["metadata"][key])
	
	# Restore resolution
	if "resolution" in data:
		chart_data.resolution = data["resolution"]
	
	# Restore BPM changes
	chart_data.bpm_changes.clear()
	if "bpm_changes" in data:
		for bpm_change in data["bpm_changes"]:
			chart_data.bpm_changes.append({
				"tick": bpm_change["tick"],
				"bpm": bpm_change["bpm"]
			})
	
	# Restore time signatures
	chart_data.time_signatures.clear()
	if "time_signatures" in data:
		for time_sig in data["time_signatures"]:
			chart_data.time_signatures.append({
				"tick": time_sig["tick"],
				"numerator": time_sig["numerator"],
				"denominator": time_sig["denominator"]
			})
	
	# Restore charts
	if "charts" in data:
		for instrument in data["charts"]:
			for difficulty in data["charts"][instrument]:
				chart_data.create_chart(instrument, difficulty)
				var chart = chart_data.get_chart(instrument, difficulty)
				
				# Restore notes
				if "notes" in data["charts"][instrument][difficulty]:
					for note_data in data["charts"][instrument][difficulty]["notes"]:
						var note = {
							"id": note_data["id"],
							"tick": note_data["tick"],
							"lane": note_data["lane"],
							"type": note_data["type"],
							"length": note_data["length"]
						}
						chart.add_note(note)
						# Update next_note_id to avoid conflicts
						if note_data["id"] >= chart_data._next_note_id:
							chart_data._next_note_id = note_data["id"] + 1
				
				# Restore events
				if "events" in data["charts"][instrument][difficulty]:
					for event_data in data["charts"][instrument][difficulty]["events"]:
						chart.events.append(event_data.duplicate())
	
	return chart_data

static func _validate_chart_data(data: Variant) -> bool:
	"""Validate chart data structure"""
	if not data is Dictionary:
		return false
	
	# Check required fields
	if not data.has("version"):
		push_error("Chart data missing 'version' field")
		return false
	
	if not data.has("metadata"):
		push_error("Chart data missing 'metadata' field")
		return false
	
	if not data.has("charts"):
		push_error("Chart data missing 'charts' field")
		return false
	
	# Validate version compatibility
	if data["version"] != FILE_VERSION:
		push_warning("Chart version %s may not be fully compatible with current version %s" % [data["version"], FILE_VERSION])
	
	return true

static func export_to_chart_format(_chart_data: ChartDataModel, _file_path: String) -> Error:
	"""Export to .chart format (Guitar Hero/Clone Hero format)"""
	# TODO: Implement .chart format export
	push_error("Export to .chart format not yet implemented")
	return ERR_UNAVAILABLE

static func import_from_chart_format(_file_path: String) -> ChartDataModel:
	"""Import from .chart format (Guitar Hero/Clone Hero format)"""
	# TODO: Implement .chart format import
	push_error("Import from .chart format not yet implemented")
	return null
