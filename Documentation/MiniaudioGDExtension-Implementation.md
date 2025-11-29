# Miniaudio GDExtension Implementation Plan

## Overview
This document outlines the implementation of a GDExtension that wraps the miniaudio library to provide PCM extraction for OGG, MP3, FLAC, and WAV audio files in Godot 4.

## Motivation
Godot 4 doesn't expose raw PCM data for compressed audio formats (AudioStreamOggVorbis, AudioStreamMP3). To generate real waveform visualizations in the chart editor for all audio formats, we need external decoding capabilities.

## Solution Architecture

### What is miniaudio?
- **Single-header C audio library** (miniaudio.h + miniaudio.c)
- **Built-in decoders** for WAV, FLAC, MP3, and OGG Vorbis
- **Public domain license** (or MIT-0) - very permissive
- **Cross-platform** (Windows, macOS, Linux)
- **Designed for audio playback and decoding**

### GDExtension Approach
We'll create a GDExtension that:
1. Wraps miniaudio's decoder API (`ma_decoder`)
2. Exposes a simple GDScript interface: `MiniaudioDecoder.extract_pcm(path: String) -> PackedFloat32Array`
3. Handles all format detection and decoding internally
4. Returns normalized float PCM samples ready for waveform generation

## Project Structure

```
RhythmGame/
├── addons/
│   └── miniaudio_decoder/          # GDExtension addon
│       ├── bin/                     # Compiled binaries
│       │   ├── windows/
│       │   │   └── libminiaudio_decoder.windows.x86_64.dll
│       │   ├── linux/
│       │   │   └── libminiaudio_decoder.linux.x86_64.so
│       │   └── macos/
│       │       └── libminiaudio_decoder.macos.universal.dylib
│       ├── src/                     # C++ source code
│       │   ├── miniaudio.h          # From mackron/miniaudio
│       │   ├── miniaudio.c          # From mackron/miniaudio
│       │   ├── register_types.h
│       │   ├── register_types.cpp
│       │   ├── miniaudio_decoder.h
│       │   └── miniaudio_decoder.cpp
│       ├── miniaudio_decoder.gdextension  # Extension config
│       ├── SConstruct                # SCons build file
│       └── README.md
├── Scripts/
│   └── Editor/
│       └── Services/
│           └── audio_pcm_extractor.gd  # Updated to use GDExtension
```

## Implementation Steps

### Step 1: Create GDExtension Project Structure
```bash
mkdir -p addons/miniaudio_decoder/bin/{windows,linux,macos}
mkdir -p addons/miniaudio_decoder/src
```

### Step 2: Download miniaudio Library
Download from: https://github.com/mackron/miniaudio
- Copy `miniaudio.h` to `addons/miniaudio_decoder/src/`
- Copy `miniaudio.c` to `addons/miniaudio_decoder/src/`

### Step 3: Create GDExtension Configuration
**File: `addons/miniaudio_decoder/miniaudio_decoder.gdextension`**
```ini
[configuration]
entry_symbol = "miniaudio_decoder_library_init"
compatibility_minimum = "4.2"

[libraries]
windows.x86_64 = "res://addons/miniaudio_decoder/bin/windows/libminiaudio_decoder.windows.x86_64.dll"
linux.x86_64 = "res://addons/miniaudio_decoder/bin/linux/libminiaudio_decoder.linux.x86_64.so"
macos.universal = "res://addons/miniaudio_decoder/bin/macos/libminiaudio_decoder.macos.universal.dylib"
```

### Step 4: Implement MiniaudioDecoder Class

**API Design:**
```cpp
class MiniaudioDecoder : public RefCounted {
    GDCLASS(MiniaudioDecoder, RefCounted);
    
public:
    // Extract all PCM samples from audio file
    PackedFloat32Array extract_pcm(const String& file_path);
    
    // Get format information
    int get_sample_rate() const;
    int get_channel_count() const;
    String get_format() const;
    
protected:
    static void _bind_methods();
    
private:
    ma_decoder decoder;
    bool is_initialized = false;
};
```

**GDScript Usage:**
```gdscript
var decoder = MiniaudioDecoder.new()
var pcm_samples: PackedFloat32Array = decoder.extract_pcm("res://song.ogg")
print("Sample rate: ", decoder.get_sample_rate())
print("Channels: ", decoder.get_channel_count())
print("Total samples: ", pcm_samples.size())
```

### Step 5: Build System Setup

**File: `addons/miniaudio_decoder/SConstruct`**
Uses SCons with godot-cpp for building across platforms.

Build commands:
```bash
# Windows (from Visual Studio command prompt)
scons platform=windows target=template_debug

# Linux
scons platform=linux target=template_debug

# macOS
scons platform=macos target=template_debug arch=universal
```

### Step 6: Integration with AudioPCMExtractor

Update `audio_pcm_extractor.gd` to use the GDExtension:

```gdscript
const MiniaudioDecoder = preload("res://addons/miniaudio_decoder/miniaudio_decoder.gdextension")

func extract(audio_stream: AudioStream, source_path: String) -> PackedFloat32Array:
    # Try GDExtension for compressed formats
    if source_path.ends_with(".ogg") or source_path.ends_with(".mp3") or source_path.ends_with(".flac"):
        return _from_miniaudio(source_path)
    
    # Fall back to built-in WAV extraction
    if audio_stream.get_class() == "AudioStreamWAV":
        return _from_wav(audio_stream)
    
    # Unsupported
    push_error("Unsupported audio format")
    return PackedFloat32Array()

func _from_miniaudio(file_path: String) -> PackedFloat32Array:
    var decoder = MiniaudioDecoder.new()
    var samples = decoder.extract_pcm(file_path)
    
    if samples.size() == 0:
        push_error("Failed to decode audio file: " + file_path)
        return PackedFloat32Array()
    
    print("Decoded %d samples from %s" % [samples.size(), file_path])
    return samples
```

## Implementation Details

### Miniaudio Decoder Flow
1. **Initialize decoder**: `ma_decoder_init_file(path, NULL, &decoder)`
2. **Get frame count**: `ma_decoder_get_length_in_pcm_frames(&decoder)`
3. **Allocate buffer**: Create PackedFloat32Array for all samples
4. **Read PCM frames**: `ma_decoder_read_pcm_frames(&decoder, buffer, frame_count)`
5. **Mix to mono**: Average stereo channels if needed
6. **Cleanup**: `ma_decoder_uninit(&decoder)`

### Memory Management
- miniaudio handles format detection automatically
- Use Godot's PackedFloat32Array for efficient memory transfer
- Decoder lifetime managed by RefCounted

### Error Handling
- Check `ma_result` return codes
- Report errors via Godot's `ERR_PRINT`
- Return empty array on failure

## Dependencies

### Required Tools
- **SCons**: Build system (`pip install scons`)
- **godot-cpp**: GDExtension bindings (git submodule or download)
- **C++ Compiler**: 
  - Windows: MSVC (Visual Studio)
  - Linux: GCC or Clang
  - macOS: Xcode Command Line Tools

### Runtime Dependencies
- None! miniaudio is statically linked into the extension

## Build Instructions

### Initial Setup
```bash
cd addons/miniaudio_decoder

# Clone godot-cpp (if not already present)
git clone https://github.com/godotengine/godot-cpp.git
cd godot-cpp
git checkout 4.3  # Match your Godot version
cd ..

# Download miniaudio
# Visit https://github.com/mackron/miniaudio
# Download miniaudio.h and miniaudio.c to src/
```

### Windows Build
```bash
# Open Visual Studio Developer Command Prompt
cd addons/miniaudio_decoder
scons platform=windows target=template_debug
scons platform=windows target=template_release
```

### Linux Build
```bash
cd addons/miniaudio_decoder
scons platform=linux target=template_debug
scons platform=linux target=template_release
```

### macOS Build
```bash
cd addons/miniaudio_decoder
scons platform=macos target=template_debug arch=universal
scons platform=macos target=template_release arch=universal
```

## Testing Strategy

### Unit Tests (GDUnit4)
Create `test/test_miniaudio_decoder.gd`:
```gdscript
func test_extract_ogg():
    var decoder = MiniaudioDecoder.new()
    var samples = decoder.extract_pcm("res://Assets/Tracks/test_song/song.ogg")
    assert_gt(samples.size(), 0, "Should extract samples from OGG")

func test_extract_mp3():
    var decoder = MiniaudioDecoder.new()
    var samples = decoder.extract_pcm("res://Assets/Tracks/test_song/song.mp3")
    assert_gt(samples.size(), 0, "Should extract samples from MP3")

func test_get_metadata():
    var decoder = MiniaudioDecoder.new()
    decoder.extract_pcm("res://Assets/Tracks/test_song/song.ogg")
    assert_gt(decoder.get_sample_rate(), 0, "Should return valid sample rate")
    assert_gt(decoder.get_channel_count(), 0, "Should return valid channel count")
```

### Integration Tests
- Load various audio formats in chart editor
- Verify waveforms display correctly
- Check memory usage doesn't leak
- Test with very long audio files (10+ minutes)

## Performance Considerations

### Optimization Strategies
1. **Lazy Loading**: Only decode when waveform needed
2. **Caching**: Cache decoded PCM data to avoid re-decoding
3. **Downsampling**: Reduce sample count for waveform display (already implemented)
4. **Background Threading**: Consider async decoding for large files (future enhancement)

### Expected Performance
- **OGG (5MB, 4 min)**: ~1-2 seconds decode time
- **MP3 (5MB, 4 min)**: ~1-2 seconds decode time
- **FLAC (30MB, 4 min)**: ~2-3 seconds decode time
- **Memory**: Proportional to audio length (44.1kHz stereo = ~176KB per second)

## Alternative Approaches Considered

### 1. FFmpeg Preprocessing ❌
- **Pros**: No GDExtension needed
- **Cons**: External dependency, slower (disk I/O), extra files

### 2. stb_vorbis Only ❌
- **Pros**: Simpler, smaller
- **Cons**: Only OGG support, need separate libs for MP3/FLAC

### 3. AudioEffectCapture ❌
- **Pros**: Pure GDScript
- **Cons**: Must play audio in real-time, complex setup, slower

### 4. Miniaudio GDExtension ✅ **CHOSEN**
- **Pros**: All formats, single dependency, fast, clean API
- **Cons**: Requires compilation

## License Compliance

### miniaudio License
- **Public Domain** or **MIT-0** (user's choice)
- No attribution required (but appreciated)
- Commercial use allowed
- Can be statically linked without issues

### Your Project
- Include miniaudio license in your distribution
- No other obligations

## Future Enhancements

1. **Async Decoding**: Use Godot's WorkerThreadPool for background decoding
2. **Streaming**: Support partial decoding for very large files
3. **Format Info**: Expose bitrate, codec, tags/metadata
4. **Resampling**: Built-in resampling to target sample rate
5. **Effects**: Optional filters during decode (normalization, EQ)

## Troubleshooting

### Common Issues

**"Cannot find godot-cpp"**
- Ensure godot-cpp is cloned in the correct location
- Check SConstruct paths

**"Undefined reference to ma_decoder_init_file"**
- Ensure miniaudio.c is compiled (not just .h)
- Add `#define MINIAUDIO_IMPLEMENTATION` before including miniaudio.h in one .cpp file

**"Extension not loading in Godot"**
- Check .gdextension file paths
- Verify binary compiled for correct platform/architecture
- Check Godot console for load errors

**"Decoding fails for certain files"**
- Check file is not corrupted
- Verify format is actually OGG/MP3/FLAC (not mislabeled)
- Check miniaudio version supports format variant

## References

- [miniaudio GitHub](https://github.com/mackron/miniaudio)
- [miniaudio Documentation](https://miniaud.io/docs/)
- [Godot GDExtension Docs](https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/index.html)
- [godot-cpp GitHub](https://github.com/godotengine/godot-cpp)

## Summary

This GDExtension will provide robust, performant multi-format audio decoding for your rhythm game chart editor, enabling real waveform visualization like Moonscraper for OGG, MP3, FLAC, and WAV files.

**Next Steps**: Begin with Step 1 (project structure) and proceed sequentially through the implementation steps.
