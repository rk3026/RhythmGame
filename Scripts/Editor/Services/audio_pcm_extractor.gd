extends RefCounted
class_name AudioPCMExtractor

# Flag to control whether to use MiniaudioDecoder GDExtension
# Set to false if GDExtension is not built/available yet
const USE_MINIAUDIO_EXTENSION: bool = true

func extract(audio_stream: AudioStream, source_path: String = "") -> PackedFloat32Array:
	if not audio_stream:
		return PackedFloat32Array()
	
	# Try MiniaudioDecoder for compressed formats if available
	if USE_MINIAUDIO_EXTENSION and source_path != "":
		var ext := source_path.get_extension().to_lower()
		if ext in ["ogg", "mp3", "flac"]:
			var result := _from_miniaudio(source_path)
			if result.size() > 0:
				return result
			# Fall through to other methods if miniaudio fails
	
	# Handle AudioStreamWAV - can extract real PCM data
	if audio_stream.get_class() == "AudioStreamWAV":
		return _from_wav(audio_stream)
	if source_path.to_lower().ends_with(".wav"):
		var wave_resource: Resource = load(source_path)
		if wave_resource and wave_resource.get_class() == "AudioStreamWAV":
			return _from_wav(wave_resource)
	
	# Unsupported format
	push_warning("AudioPCMExtractor: Unsupported audio stream type %s" % [audio_stream.get_class()])
	return PackedFloat32Array()

func _from_miniaudio(file_path: String) -> PackedFloat32Array:
	# Try to use MiniaudioDecoder GDExtension for OGG/MP3/FLAC decoding
	# Check if the class exists (GDExtension is loaded)
	if not ClassDB.class_exists("MiniaudioDecoder"):
		push_warning("MiniaudioDecoder GDExtension not found. Build the extension or set USE_MINIAUDIO_EXTENSION to false.")
		return PackedFloat32Array()
	
	# Create decoder instance
	var MiniaudioDecoder = ClassDB.instantiate("MiniaudioDecoder")
	if not MiniaudioDecoder:
		push_error("Failed to instantiate MiniaudioDecoder")
		return PackedFloat32Array()
	
	# Extract PCM samples
	var samples: PackedFloat32Array = MiniaudioDecoder.extract_pcm(file_path)
	
	if samples.size() == 0:
		push_error("MiniaudioDecoder failed to extract PCM from: " + file_path)
		return PackedFloat32Array()
	
	# Success - log info
	var sample_rate: int = MiniaudioDecoder.get_sample_rate()
	var channels: int = MiniaudioDecoder.get_channel_count()
	print("AudioPCMExtractor: Decoded %d samples (%d Hz, %d channels) from %s" % [
		samples.size(),
		sample_rate,
		channels,
		file_path.get_file()
	])
	
	return samples

func _from_wav(stream) -> PackedFloat32Array:
	if not stream:
		return PackedFloat32Array()
	var channel_count := 2 if stream.stereo else 1
	return _convert_bytes_to_floats(stream.data, stream.format, channel_count)

func _convert_bytes_to_floats(raw_bytes: PackedByteArray, format: int, channel_count: int) -> PackedFloat32Array:
	var samples := PackedFloat32Array()
	if raw_bytes.is_empty() or channel_count <= 0:
		return samples
	# AudioStreamWAV format constants: FORMAT_8_BITS = 0, FORMAT_16_BITS = 1
	match format:
		0:  # FORMAT_8_BITS
			samples = _convert_8bit(raw_bytes, channel_count)
		1:  # FORMAT_16_BITS
			samples = _convert_16bit(raw_bytes, channel_count)
		_:
			push_warning("AudioPCMExtractor: Unsupported PCM format %s" % [str(format)])
	return samples

func _convert_8bit(raw_bytes: PackedByteArray, channel_count: int) -> PackedFloat32Array:
	var frames := raw_bytes.size() / channel_count
	var result := PackedFloat32Array()
	result.resize(frames)
	var byte_index := 0
	for frame in range(frames):
		var accumulator := 0.0
		for _channel in range(channel_count):
			var sample_value := (raw_bytes[byte_index] - 128) / 128.0
			accumulator += sample_value
			byte_index += 1
		result[frame] = accumulator / float(channel_count)
	return result

func _convert_16bit(raw_bytes: PackedByteArray, channel_count: int) -> PackedFloat32Array:
	var bytes_per_sample := 2
	var frames := raw_bytes.size() / (bytes_per_sample * channel_count)
	var result := PackedFloat32Array()
	result.resize(frames)
	var byte_index := 0
	for frame in range(frames):
		var accumulator := 0.0
		for _channel in range(channel_count):
			if byte_index + 1 >= raw_bytes.size():
				break
			var low := raw_bytes[byte_index]
			var high := raw_bytes[byte_index + 1]
			var combined := int16((high << 8) | low)
			accumulator += combined / 32768.0
			byte_index += bytes_per_sample
		result[frame] = accumulator / float(channel_count)
	return result

func int16(value: int) -> int:
	if value & 0x8000:
		return value - 0x10000
	return value
