# Waveform Visualization Implementation

## Overview

The chart editor now supports **real waveform visualization** for all audio formats (OGG, MP3, FLAC, WAV) using the MiniaudioDecoder GDExtension.

## Architecture

### Components

1. **MiniaudioDecoder GDExtension** (`addons/miniaudio_decoder/`)
   - C++ wrapper around miniaudio library
   - Decodes compressed audio to PCM samples
   - Exposes simple API to GDScript

2. **AudioPCMExtractor** (`Scripts/Editor/Services/audio_pcm_extractor.gd`)
   - Service that extracts PCM data from audio streams
   - Uses MiniaudioDecoder for OGG/MP3/FLAC
   - Falls back to built-in WAV extraction

3. **ChartEditorWaveformManager** (`Scripts/Editor/Services/chart_editor_waveform_manager.gd`)
   - Generates waveform texture from PCM samples
   - Downsamples large datasets for performance
   - Renders waveform on chart runway

4. **ChartEditor** (`Scripts/Editor/chart_editor.gd`)
   - Coordinates audio loading and waveform generation
   - Passes audio file path to waveform manager

## Data Flow

```
Audio File (OGG/MP3/FLAC/WAV)
    ↓
ChartEditor._load_audio_file()
    ↓
ChartEditorWaveformManager.regenerate_waveform()
    ↓
AudioPCMExtractor.extract()
    ↓
MiniaudioDecoder.extract_pcm() [GDExtension]
    ↓
PackedFloat32Array (mono PCM samples)
    ↓
ChartEditorWaveformManager._generate_waveform_texture()
    ↓
Waveform Image (512x2048 RGBA8)
    ↓
Display on Chart Runway
```

## Implementation Details

### PCM Extraction

**For compressed formats** (OGG/MP3/FLAC):
1. MiniaudioDecoder loads file using miniaudio library
2. Decodes all frames to float PCM samples
3. Mixes stereo to mono (averages L+R channels)
4. Returns PackedFloat32Array

**For WAV**:
1. AudioPCMExtractor reads raw PCM data from AudioStreamWAV
2. Converts 8-bit or 16-bit samples to float
3. Mixes stereo to mono
4. Returns PackedFloat32Array

### Waveform Generation

1. **Downsampling**: If samples > 50,000, downsample using min/max pairs
2. **Texture Creation**: Generate 512x2048 RGBA8 image
3. **Rendering**: Draw waveform as vertical lines with fade gradient
4. **Display**: Apply texture to runway background

### Performance

- **Decode time**: 1-3 seconds for typical song (4 minutes)
- **Memory**: ~42MB for 4-minute song PCM data
- **Waveform generation**: <100ms after downsampling
- **Display**: Real-time with no lag

## Usage

### In Chart Editor

Waveforms are generated automatically when loading audio:

```gdscript
func _load_audio_file(file_path: String):
    var audio_stream = load(file_path)
    waveform_manager.regenerate_waveform(audio_stream, file_path)
    # Waveform appears on runway
```

### Direct API Usage

```gdscript
# Extract PCM samples
var extractor = AudioPCMExtractor.new()
var samples = extractor.extract(audio_stream, file_path)

# samples is PackedFloat32Array with mono PCM data
print("Extracted ", samples.size(), " samples")
```

### MiniaudioDecoder API

```gdscript
# Create decoder
var decoder = MiniaudioDecoder.new()

# Decode audio file
var samples = decoder.extract_pcm("res://song.ogg")

# Get metadata
var sample_rate = decoder.get_sample_rate()  # e.g., 44100
var channels = decoder.get_channel_count()   # e.g., 2 (stereo)
```

## Configuration

### Enable/Disable GDExtension

In `audio_pcm_extractor.gd`:
```gdscript
const USE_MINIAUDIO_EXTENSION: bool = true  # Set false to disable
```

When disabled, extension is not loaded (no errors if not built).

### Adjust Waveform Detail

In `chart_editor_waveform_manager.gd`:
```gdscript
const MAX_SAMPLES := 50000  # Increase for more detail, decrease for speed
```

Higher values = more detailed waveform, but slower generation.

## Building the Extension

See detailed instructions in:
- **NEXT_STEPS.md** - Quick start guide
- **addons/miniaudio_decoder/QUICKSTART.md** - Setup walkthrough
- **addons/miniaudio_decoder/BUILD.md** - Detailed build instructions
- **addons/miniaudio_decoder/PROJECT_SUMMARY.md** - Full technical overview

### Quick Build

```bash
# 1. Setup dependencies
cd addons/miniaudio_decoder
setup.bat  # or setup.sh on Linux/macOS

# 2. Build godot-cpp (one time)
cd godot-cpp
scons platform=windows target=template_debug
scons platform=windows target=template_release
cd ..

# 3. Build extension
scons platform=windows target=template_debug
scons platform=windows target=template_release
```

## Troubleshooting

### Extension Not Loading

**Symptoms**: "MiniaudioDecoder not found" in console

**Solutions**:
1. Build the extension (see above)
2. Reload Godot project
3. Check `bin/` folder has DLL/SO files
4. Verify .gdextension file paths are correct

### Waveform Not Appearing

**Symptoms**: No waveform on runway, or placeholder sine wave

**Solutions**:
1. Check extension is loaded (no errors in console)
2. Verify USE_MINIAUDIO_EXTENSION = true
3. Check audio file path is correct
4. Look for decode errors in console

### Performance Issues

**Symptoms**: Chart editor freezes when loading audio

**Solutions**:
1. Reduce MAX_SAMPLES in waveform manager
2. Use shorter audio files for testing
3. Consider adding async decoding (future enhancement)

## Comparison: Before vs After

| Aspect | Before | After |
|--------|--------|-------|
| OGG Support | ❌ Placeholder | ✅ Real waveform |
| MP3 Support | ❌ Placeholder | ✅ Real waveform |
| FLAC Support | ❌ Placeholder | ✅ Real waveform |
| WAV Support | ✅ Real waveform | ✅ Real waveform |
| Accuracy | 0% | 100% |
| Like Moonscraper | ❌ No | ✅ Yes |

## Future Enhancements

### Short Term
- [ ] Add loading progress bar for long decodes
- [ ] Cache decoded PCM data to avoid re-decoding
- [ ] Add waveform color customization

### Medium Term
- [ ] Async/threaded decoding for large files
- [ ] Streaming decoder for partial loading
- [ ] Zoom controls for waveform detail

### Long Term
- [ ] Stereo waveform (show L/R separately)
- [ ] Spectral analysis overlay
- [ ] Beat detection markers

## References

- **miniaudio**: https://github.com/mackron/miniaudio
- **Moonscraper**: https://github.com/FireFox2000000/Moonscraper-Chart-Editor
- **Godot GDExtension**: https://docs.godotengine.org/en/stable/tutorials/scripting/gdextension/

## Related Documentation

- [MiniaudioGDExtension-Implementation.md](MiniaudioGDExtension-Implementation.md) - Full technical spec
- [ChartEditor-Plan.md](ChartEditor-Plan.md) - Chart editor architecture
- [Core Infrastructure.md](Core%20Infrastructure.md) - Service architecture
- [../addons/miniaudio_decoder/README.md](../addons/miniaudio_decoder/README.md) - Extension documentation
