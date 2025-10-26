extends Node

## SoundEffectManager.gd - Singleton for managing all sound effects in the game
## Provides centralized audio playback with pooling, bus management, and volume control
## Following the project's singleton pattern (autoload)

# Sound categories for organization and bus routing
enum SoundCategory {
	HIT_PERFECT,
	HIT_GREAT,
	HIT_GOOD,
	HIT_BAD,
	MISS,
	COMBO_MILESTONE,  # Every 50/100 combo
	UI_CLICK,
	UI_HOVER,
	UI_BACK,
	UI_SELECT,
	COUNTDOWN,
	SONG_START,
	SONG_END,
	PAUSE_IN,
	PAUSE_OUT,
	GENERIC_SFX
}

# Audio bus names (must match project settings)
const BUS_MASTER := "Master"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const BUS_SFX_HITS := "SFX/Hits"
const BUS_SFX_MISSES := "SFX/Misses"
const BUS_SFX_IMPACTS := "SFX/Impacts"
const BUS_UI := "UI"

# Sound file paths (relative to res://Assets/Audio/)
const SOUND_LIBRARY := {
	"perfect": "SFX/Hits/perfect_01.ogg",
	"perfect_2": "SFX/Hits/perfect_02.ogg",  # Variation
	"great": "SFX/Hits/great_01.ogg",
	"good": "SFX/Hits/good_01.ogg",
	"bad": "SFX/Hits/bad_01.ogg",
	"miss": "SFX/Misses/miss_01.ogg",
	"combo_50": "SFX/Combo/combo_50.ogg",
	"combo_100": "SFX/Combo/combo_100.ogg",
	"combo_fc": "SFX/Combo/combo_fc.ogg",
	"countdown_tick": "SFX/Ambient/countdown_tick.ogg",
	"countdown_go": "SFX/Ambient/countdown_go.ogg",
	"ui_click": "UI/click.ogg",
	"ui_hover": "UI/hover.ogg",
	"ui_back": "UI/back.ogg",
	"ui_select": "UI/select.ogg",
	"pause_in": "SFX/Ambient/pause_in.ogg",
	"pause_out": "SFX/Ambient/pause_out.ogg",
}

# Category to bus mapping
const CATEGORY_BUS_MAP := {
	SoundCategory.HIT_PERFECT: BUS_SFX_HITS,
	SoundCategory.HIT_GREAT: BUS_SFX_HITS,
	SoundCategory.HIT_GOOD: BUS_SFX_HITS,
	SoundCategory.HIT_BAD: BUS_SFX_HITS,
	SoundCategory.MISS: BUS_SFX_MISSES,
	SoundCategory.COMBO_MILESTONE: BUS_SFX_IMPACTS,
	SoundCategory.UI_CLICK: BUS_UI,
	SoundCategory.UI_HOVER: BUS_UI,
	SoundCategory.UI_BACK: BUS_UI,
	SoundCategory.UI_SELECT: BUS_UI,
	SoundCategory.COUNTDOWN: BUS_SFX,
	SoundCategory.SONG_START: BUS_SFX,
	SoundCategory.SONG_END: BUS_SFX,
	SoundCategory.PAUSE_IN: BUS_SFX,
	SoundCategory.PAUSE_OUT: BUS_SFX,
	SoundCategory.GENERIC_SFX: BUS_SFX,
}

# Pooling system
var player_pools: Dictionary = {}  # {bus_name: AudioPlayerPool}
var cached_sounds: Dictionary = {}  # {sound_name: AudioStream}

# Settings
var sfx_enabled: bool = true
var hit_sounds_enabled: bool = true
var ui_sounds_enabled: bool = true
var combo_sounds_enabled: bool = true

# Variation tracking (to avoid repetition)
var last_played_variations: Dictionary = {}  # {base_name: [variation_index]}

# Signals
signal sound_played(sound_name: String, category: SoundCategory)
signal bus_volume_changed(bus_name: String, volume: float)

# ============================================================================
# Initialization
# ============================================================================

func _ready():
	print("SoundEffectManager: Initializing audio system...")
	_initialize_audio_buses()
	_create_player_pools()
	_load_settings_from_manager()
	print("SoundEffectManager: Ready with ", player_pools.size(), " player pools")

func _initialize_audio_buses():
	"""Ensure all required audio buses exist and set default volumes."""
	var required_buses = [BUS_MUSIC, BUS_SFX, BUS_UI]
	
	for bus_name in required_buses:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx == -1:
			push_warning("SoundEffectManager: Audio bus '%s' not found in project settings" % bus_name)
		else:
			# Set default volumes (will be overridden by SettingsManager)
			var default_volume = 0.8 if bus_name != BUS_MUSIC else 1.0
			set_bus_volume(bus_name, default_volume)

func _create_player_pools():
	"""Create AudioStreamPlayer pools for each bus."""
	var buses_to_pool = [BUS_SFX, BUS_UI, BUS_MUSIC]
	
	for bus_name in buses_to_pool:
		var bus_idx = AudioServer.get_bus_index(bus_name)
		if bus_idx != -1:
			var pool = AudioPlayerPool.new(bus_name, 16)  # 16 players per pool
			pool.set_parent(self)  # Give pool reference to SoundEffectManager node
			player_pools[bus_name] = pool

func _load_settings_from_manager():
	"""Load audio settings from SettingsManager if available."""
	if not is_instance_valid(SettingsManager):
		push_warning("SoundEffectManager: SettingsManager not available, using defaults")
		return
	
	# Apply volume settings from SettingsManager
	# Since SoundEffectManager loads AFTER SettingsManager in autoload order,
	# we need to explicitly apply the volumes here
	set_bus_volume(BUS_MASTER, SettingsManager.master_volume)
	set_bus_volume(BUS_SFX, SettingsManager.sfx_volume)
	set_bus_volume(BUS_UI, SettingsManager.ui_volume)
	set_bus_volume(BUS_MUSIC, SettingsManager.music_volume)
	
	print("SoundEffectManager: Applied volume settings from SettingsManager")
	print("  Master: ", SettingsManager.master_volume)
	print("  SFX: ", SettingsManager.sfx_volume)
	print("  UI: ", SettingsManager.ui_volume)
	print("  Music: ", SettingsManager.music_volume)

# ============================================================================
# Public API - Sound Playback
# ============================================================================

## Play a sound effect by name
## @param sound_name: Key from SOUND_LIBRARY or direct file path
## @param category: SoundCategory enum value for bus routing
## @param volume_db: Volume adjustment in decibels (0.0 = no change)
## @param pitch_scale: Pitch multiplier (1.0 = normal, 0.5-2.0 typical range)
## @return: AudioStreamPlayer instance that's playing the sound
func play_sfx(sound_name: String, category: SoundCategory = SoundCategory.GENERIC_SFX, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	# Check if sounds are enabled
	if not sfx_enabled:
		return null
	
	# Category-specific enable checks
	if category in [SoundCategory.HIT_PERFECT, SoundCategory.HIT_GREAT, SoundCategory.HIT_GOOD, SoundCategory.HIT_BAD] and not hit_sounds_enabled:
		return null
	
	if category in [SoundCategory.UI_CLICK, SoundCategory.UI_HOVER, SoundCategory.UI_BACK, SoundCategory.UI_SELECT] and not ui_sounds_enabled:
		return null
	
	if category == SoundCategory.COMBO_MILESTONE and not combo_sounds_enabled:
		return null
	
	# Load sound
	var sound = _get_or_load_sound(sound_name)
	if not sound:
		push_warning("SoundEffectManager: Failed to load sound '%s'" % sound_name)
		return null
	
	# Get bus for this category
	var bus_name = CATEGORY_BUS_MAP.get(category, BUS_SFX)
	
	# Get player from pool
	var player = _get_player_from_pool(bus_name)
	if not player:
		push_warning("SoundEffectManager: No available players in pool for bus '%s'" % bus_name)
		return null
	
	# Configure and play
	player.stream = sound
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	player.play()
	
	# Emit signal
	sound_played.emit(sound_name, category)
	
	return player

## Play an AudioStream directly (useful for dynamic sounds)
## @param stream: AudioStream to play
## @param category: SoundCategory for bus routing
## @param volume_db: Volume adjustment
## @param pitch_scale: Pitch multiplier
## @return: AudioStreamPlayer instance
func play_stream(stream: AudioStream, category: SoundCategory = SoundCategory.GENERIC_SFX, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	if not sfx_enabled or not stream:
		return null
	
	var bus_name = CATEGORY_BUS_MAP.get(category, BUS_SFX)
	var player = _get_player_from_pool(bus_name)
	
	if player:
		player.stream = stream
		player.volume_db = volume_db
		player.pitch_scale = pitch_scale
		player.play()
	
	return player

## Play a sound with random variation (e.g., "perfect" might play "perfect_01" or "perfect_02")
## @param base_name: Base sound name (without variation suffix)
## @param num_variations: Number of variations available
## @param category: SoundCategory
## @return: AudioStreamPlayer instance
func play_sfx_variation(base_name: String, num_variations: int = 2, category: SoundCategory = SoundCategory.GENERIC_SFX, volume_db: float = 0.0, pitch_scale: float = 1.0) -> AudioStreamPlayer:
	# Avoid playing the same variation twice in a row
	var last_variation = last_played_variations.get(base_name, -1)
	var variation_index = randi() % num_variations
	
	# Try to pick a different variation
	if num_variations > 1 and variation_index == last_variation:
		variation_index = (variation_index + 1) % num_variations
	
	last_played_variations[base_name] = variation_index
	
	# Build sound name with variation suffix
	var sound_name = base_name
	if variation_index > 0:
		sound_name = "%s_%d" % [base_name, variation_index + 1]
	
	return play_sfx(sound_name, category, volume_db, pitch_scale)

## Stop all sounds in a specific category
func stop_category(category: SoundCategory):
	var bus_name = CATEGORY_BUS_MAP.get(category, BUS_SFX)
	if player_pools.has(bus_name):
		player_pools[bus_name].stop_all()

## Stop all sounds across all pools
func stop_all():
	for pool in player_pools.values():
		pool.stop_all()

# ============================================================================
# Volume Control
# ============================================================================

## Set volume for an audio bus (0.0 to 1.0)
## @param bus_name: Name of the audio bus
## @param volume: Volume level (0.0 = silent, 1.0 = full)
func set_bus_volume(bus_name: String, volume: float):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		push_warning("SoundEffectManager: Bus '%s' not found" % bus_name)
		return
	
	# Clamp volume to valid range
	volume = clampf(volume, 0.0, 1.0)
	
	# Convert linear volume to decibels
	var volume_db = linear_to_db(volume) if volume > 0.0 else -80.0
	AudioServer.set_bus_volume_db(bus_idx, volume_db)
	
	bus_volume_changed.emit(bus_name, volume)

## Get volume for an audio bus (0.0 to 1.0)
func get_bus_volume(bus_name: String) -> float:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return 0.0
	
	var volume_db = AudioServer.get_bus_volume_db(bus_idx)
	return db_to_linear(volume_db) if volume_db > -79.0 else 0.0

## Mute/unmute a bus
func set_bus_mute(bus_name: String, mute: bool):
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		AudioServer.set_bus_mute(bus_idx, mute)

## Get mute state of a bus
func is_bus_muted(bus_name: String) -> bool:
	var bus_idx = AudioServer.get_bus_index(bus_name)
	if bus_idx == -1:
		return false
	return AudioServer.is_bus_mute(bus_idx)

# ============================================================================
# Settings Management
# ============================================================================

func set_sfx_enabled(enabled: bool):
	sfx_enabled = enabled
	if not enabled:
		stop_all()

func set_hit_sounds_enabled(enabled: bool):
	hit_sounds_enabled = enabled

func set_ui_sounds_enabled(enabled: bool):
	ui_sounds_enabled = enabled

func set_combo_sounds_enabled(enabled: bool):
	combo_sounds_enabled = enabled

# ============================================================================
# Preloading & Caching
# ============================================================================

## Preload a set of sounds for faster playback
## @param sound_names: Array of sound names from SOUND_LIBRARY
func preload_sounds(sound_names: Array):
	for sound_name in sound_names:
		_get_or_load_sound(sound_name)

## Preload all sounds in a category
func preload_category(category: SoundCategory):
	var sounds_to_load = []
	match category:
		SoundCategory.HIT_PERFECT, SoundCategory.HIT_GREAT, SoundCategory.HIT_GOOD, SoundCategory.HIT_BAD:
			sounds_to_load = ["perfect", "perfect_2", "great", "good", "bad"]
		SoundCategory.MISS:
			sounds_to_load = ["miss"]
		SoundCategory.COMBO_MILESTONE:
			sounds_to_load = ["combo_50", "combo_100", "combo_fc"]
		SoundCategory.UI_CLICK, SoundCategory.UI_HOVER, SoundCategory.UI_BACK, SoundCategory.UI_SELECT:
			sounds_to_load = ["ui_click", "ui_hover", "ui_back", "ui_select"]
		SoundCategory.COUNTDOWN:
			sounds_to_load = ["countdown_tick", "countdown_go"]
	
	preload_sounds(sounds_to_load)

## Clear cached sounds to free memory
func clear_cache():
	cached_sounds.clear()

# ============================================================================
# Internal Methods
# ============================================================================

func _get_or_load_sound(sound_name: String) -> AudioStream:
	"""Get sound from cache or load it."""
	# Check cache first
	if cached_sounds.has(sound_name):
		return cached_sounds[sound_name]
	
	# Get path from library
	var sound_path = SOUND_LIBRARY.get(sound_name, sound_name)
	
	# Ensure it's an absolute path
	if not sound_path.begins_with("res://"):
		sound_path = "res://Assets/Audio/" + sound_path
	
	# Check if file exists
	if not ResourceLoader.exists(sound_path):
		push_warning("SoundEffectManager: Sound file not found: %s" % sound_path)
		return null
	
	# Load the sound
	var sound = load(sound_path)
	if sound:
		cached_sounds[sound_name] = sound
	
	return sound

func _get_player_from_pool(bus_name: String) -> AudioStreamPlayer:
	"""Get an AudioStreamPlayer from the appropriate pool."""
	if not player_pools.has(bus_name):
		push_warning("SoundEffectManager: No pool for bus '%s'" % bus_name)
		return null
	
	return player_pools[bus_name].get_player()

# ============================================================================
# AudioPlayerPool Inner Class
# ============================================================================

class AudioPlayerPool:
	"""Object pool for AudioStreamPlayer instances on a specific bus."""
	
	var pool: Array[AudioStreamPlayer] = []
	var active_players: Array[AudioStreamPlayer] = []
	var bus_name: String
	var max_pool_size: int
	var parent_node: Node
	
	func _init(bus: String, max_size: int = 16):
		bus_name = bus
		max_pool_size = max_size
	
	func set_parent(node: Node):
		parent_node = node
	
	func get_player() -> AudioStreamPlayer:
		"""Get a player from the pool or create a new one."""
		var player: AudioStreamPlayer
		
		# Reuse finished players first
		for p in active_players:
			if not p.playing:
				return p
		
		# Try to get from inactive pool
		if not pool.is_empty():
			player = pool.pop_back()
			active_players.append(player)
			return player
		
		# Create new player if under limit
		if active_players.size() < max_pool_size:
			player = _create_player()
			active_players.append(player)
			return player
		
		# Pool exhausted - reuse oldest active player
		push_warning("AudioPlayerPool: Pool exhausted for bus '%s', reusing oldest player" % bus_name)
		return active_players[0]
	
	func _create_player() -> AudioStreamPlayer:
		"""Create a new AudioStreamPlayer configured for this pool."""
		var player = AudioStreamPlayer.new()
		player.bus = bus_name
		
		# Add to scene tree (required for playback)
		if parent_node:
			parent_node.add_child(player)
		
		# Connect finished signal to return to pool
		player.finished.connect(_on_player_finished.bind(player))
		
		return player
	
	func _on_player_finished(player: AudioStreamPlayer):
		"""Return player to inactive pool when finished."""
		if player in active_players:
			active_players.erase(player)
		
		if pool.size() < max_pool_size and player not in pool:
			pool.append(player)
	
	func stop_all():
		"""Stop all active players in this pool."""
		for player in active_players:
			if player.playing:
				player.stop()
	
	func clear():
		"""Clear the pool and free all players."""
		for player in pool:
			player.queue_free()
		for player in active_players:
			player.queue_free()
		pool.clear()
		active_players.clear()
