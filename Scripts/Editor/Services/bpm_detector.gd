class_name BPMDetector
extends RefCounted

## BPMDetector - Analyzes audio files to detect BPM using onset detection
## Uses energy-based beat detection on audio PCM data

const AudioPCMExtractor = preload("res://Scripts/Editor/Services/audio_pcm_extractor.gd")

## Detect BPM from an audio file
## @param file_path: Path to the audio file (.ogg, .mp3, .wav)
## @param progress_callback: Optional callback for progress updates (takes float 0-1)
## @return: Detected BPM as float, or 0.0 if detection failed
static func detect_bpm(file_path: String, progress_callback: Callable = Callable()) -> float:
	# Extract PCM data from audio file
	if progress_callback.is_valid():
		progress_callback.call(0.1, "Extracting audio data...")
	
	var pcm_data = AudioPCMExtractor.extract_pcm(file_path)
	if pcm_data.is_empty():
		push_error("BPMDetector: Failed to extract PCM data from: " + file_path)
		return 0.0
	
	if progress_callback.is_valid():
		progress_callback.call(0.3, "Analyzing audio...")
	
	# Get sample rate
	var sample_rate: int = AudioPCMExtractor.get_last_sample_rate()
	if sample_rate == 0:
		sample_rate = 44100  # Default fallback
	
	# Detect BPM using onset detection
	var bpm = _detect_bpm_from_pcm(pcm_data, sample_rate, progress_callback)
	
	if progress_callback.is_valid():
		progress_callback.call(1.0, "BPM detection complete")
	
	return bpm

## Internal: Detect BPM from PCM samples using energy-based onset detection
static func _detect_bpm_from_pcm(samples: PackedFloat32Array, sample_rate: int, progress_callback: Callable) -> float:
	# Convert to mono if needed (average channels)
	var mono_samples = _convert_to_mono(samples)
	
	if progress_callback.is_valid():
		progress_callback.call(0.4, "Computing energy envelope...")
	
	# Compute energy envelope with windowing
	var hop_size = 512  # Samples between analysis windows
	var window_size = 2048  # Analysis window size
	var energy_envelope = _compute_energy_envelope(mono_samples, window_size, hop_size)
	
	if progress_callback.is_valid():
		progress_callback.call(0.6, "Detecting onsets...")
	
	# Detect onsets (peaks in energy)
	var onset_times = _detect_onsets(energy_envelope, hop_size, sample_rate)
	
	if onset_times.size() < 2:
		push_warning("BPMDetector: Not enough onsets detected")
		return 120.0  # Default fallback
	
	if progress_callback.is_valid():
		progress_callback.call(0.8, "Calculating tempo...")
	
	# Calculate inter-onset intervals (IOIs)
	var intervals: Array[float] = []
	for i in range(1, onset_times.size()):
		var interval = onset_times[i] - onset_times[i - 1]
		if interval > 0.2 and interval < 2.0:  # Filter out unrealistic intervals (30-300 BPM)
			intervals.append(interval)
	
	if intervals.is_empty():
		push_warning("BPMDetector: No valid intervals found")
		return 120.0
	
	# Find most common interval using autocorrelation of intervals
	var bpm = _estimate_bpm_from_intervals(intervals)
	
	# Ensure BPM is in reasonable range
	bpm = clampf(bpm, 60.0, 200.0)
	
	return bpm

## Convert stereo/multi-channel audio to mono by averaging
static func _convert_to_mono(samples: PackedFloat32Array) -> PackedFloat32Array:
	# Assume stereo for now (most common case)
	# If samples are already mono, this won't harm
	var mono = PackedFloat32Array()
	var channels = 2  # Assume stereo
	
	if samples.size() % channels == 0:
		mono.resize(samples.size() / channels)
		for i in range(mono.size()):
			var sum = 0.0
			for c in range(channels):
				sum += samples[i * channels + c]
			mono[i] = sum / float(channels)
	else:
		# Already mono or unknown channel count - use as is
		mono = samples
	
	return mono

## Compute energy envelope of audio signal
static func _compute_energy_envelope(samples: PackedFloat32Array, window_size: int, hop_size: int) -> PackedFloat32Array:
	var envelope = PackedFloat32Array()
	var num_frames = (samples.size() - window_size) / hop_size + 1
	
	if num_frames <= 0:
		return envelope
	
	envelope.resize(num_frames)
	
	for frame_idx in range(num_frames):
		var start = frame_idx * hop_size
		var energy = 0.0
		
		# Calculate RMS energy in this window
		for i in range(window_size):
			if start + i < samples.size():
				var sample = samples[start + i]
				energy += sample * sample
		
		envelope[frame_idx] = sqrt(energy / float(window_size))
	
	return envelope

## Detect onset times from energy envelope using peak picking
static func _detect_onsets(envelope: PackedFloat32Array, hop_size: int, sample_rate: int) -> Array[float]:
	var onsets: Array[float] = []
	
	if envelope.size() < 3:
		return onsets
	
	# Calculate derivative (rate of energy change)
	var flux = PackedFloat32Array()
	flux.resize(envelope.size() - 1)
	
	for i in range(flux.size()):
		var diff = envelope[i + 1] - envelope[i]
		flux[i] = maxf(0.0, diff)  # Only positive changes (onsets)
	
	# Find mean and standard deviation for threshold
	var mean = 0.0
	for val in flux:
		mean += val
	mean /= float(flux.size())
	
	var std_dev = 0.0
	for val in flux:
		std_dev += (val - mean) * (val - mean)
	std_dev = sqrt(std_dev / float(flux.size()))
	
	# Threshold for onset detection
	var threshold = mean + (std_dev * 1.5)
	
	# Find peaks above threshold with minimum spacing
	var min_spacing = int(0.1 * sample_rate / hop_size)  # At least 100ms between onsets
	var last_onset_frame = -min_spacing
	
	for i in range(1, flux.size() - 1):
		# Check if this is a local maximum above threshold
		if flux[i] > threshold and flux[i] > flux[i - 1] and flux[i] > flux[i + 1]:
			if i - last_onset_frame >= min_spacing:
				var time = float(i * hop_size) / float(sample_rate)
				onsets.append(time)
				last_onset_frame = i
	
	return onsets

## Estimate BPM from inter-onset intervals using histogram
static func _estimate_bpm_from_intervals(intervals: Array[float]) -> float:
	# Create histogram of intervals
	var histogram: Dictionary = {}
	var bin_size = 0.01  # 10ms bins
	
	for interval in intervals:
		var bin = int(interval / bin_size)
		if not histogram.has(bin):
			histogram[bin] = 0
		histogram[bin] += 1
	
	# Find the bin with maximum count
	var max_count = 0
	var best_bin = 0
	
	for bin in histogram.keys():
		if histogram[bin] > max_count:
			max_count = histogram[bin]
			best_bin = bin
	
	# Convert bin back to interval
	var most_common_interval = float(best_bin) * bin_size
	
	# Convert interval to BPM
	var bpm = 60.0 / most_common_interval
	
	# Handle tempo multiples/halves (common detection error)
	# If detected BPM is too fast or slow, adjust by factors of 2
	while bpm > 200.0:
		bpm /= 2.0
	while bpm < 60.0:
		bpm *= 2.0
	
	return bpm

## Quick BPM detection (analyzes only first 30 seconds for speed)
static func detect_bpm_quick(file_path: String) -> float:
	var pcm_data = AudioPCMExtractor.extract_pcm(file_path)
	if pcm_data.is_empty():
		return 120.0
	
	var sample_rate = AudioPCMExtractor.get_last_sample_rate()
	if sample_rate == 0:
		sample_rate = 44100
	
	# Limit analysis to first 30 seconds
	var max_samples = sample_rate * 30 * 2  # 30 seconds, stereo
	if pcm_data.size() > max_samples:
		pcm_data.resize(max_samples)
	
	return _detect_bpm_from_pcm(pcm_data, sample_rate, Callable())
