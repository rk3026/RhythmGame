# Miniaudio Decoder GDExtension

A Godot 4 GDExtension that provides PCM extraction for audio files using the miniaudio library.

## Features

- **Multi-format support**: OGG, MP3, FLAC, WAV
- **Simple API**: Single function call to extract PCM data
- **Cross-platform**: Windows, Linux, macOS
- **Public domain**: miniaudio is public domain (or MIT-0)

## Installation

### Prerequisites

- **SCons**: `pip install scons`
- **godot-cpp**: Clone into this directory
- **C++ Compiler**:
  - Windows: Visual Studio 2019+ (MSVC)
  - Linux: GCC or Clang
  - macOS: Xcode Command Line Tools

### Setup

1. Clone godot-cpp:
```bash
cd addons/miniaudio_decoder
git clone https://github.com/godotengine/godot-cpp.git
cd godot-cpp
git checkout 4.3  # Match your Godot version
cd ..
```

2. Download miniaudio:
   - Visit https://github.com/mackron/miniaudio
   - Download `miniaudio.h` and `miniaudio.c`
   - Place them in `src/` directory

3. Build the extension:

**Windows** (from Visual Studio Developer Command Prompt):
```bash
scons platform=windows target=template_debug
scons platform=windows target=template_release
```

**Linux**:
```bash
scons platform=linux target=template_debug
scons platform=linux target=template_release
```

**macOS**:
```bash
scons platform=macos target=template_debug arch=universal
scons platform=macos target=template_release arch=universal
```

## Usage

```gdscript
# Create decoder instance
var decoder = MiniaudioDecoder.new()

# Extract PCM samples from audio file
var samples: PackedFloat32Array = decoder.extract_pcm("res://path/to/song.ogg")

# Get audio metadata
print("Sample rate: ", decoder.get_sample_rate())
print("Channels: ", decoder.get_channel_count())
print("Format: ", decoder.get_format())
print("Total samples: ", samples.size())
```

## API Reference

### MiniaudioDecoder

#### Methods

- `extract_pcm(file_path: String) -> PackedFloat32Array`
  - Decodes audio file and returns all PCM samples as floats
  - Automatically detects format (OGG, MP3, FLAC, WAV)
  - Returns mono PCM data (stereo is mixed to mono)
  - Returns empty array on failure

- `get_sample_rate() -> int`
  - Returns the sample rate of the last decoded file (e.g., 44100)

- `get_channel_count() -> int`
  - Returns the original channel count before mono mixing (1 or 2)

- `get_format() -> String`
  - Returns the detected format: "wav", "mp3", "flac", "vorbis", or "unknown"

## Integration with Chart Editor

This extension is designed to work with the AudioPCMExtractor service:

```gdscript
# In audio_pcm_extractor.gd
func _from_miniaudio(file_path: String) -> PackedFloat32Array:
    var decoder = MiniaudioDecoder.new()
    var samples = decoder.extract_pcm(file_path)
    
    if samples.size() == 0:
        push_error("Failed to decode: " + file_path)
    
    return samples
```

## License

### miniaudio
- Public Domain or MIT-0 (your choice)
- Copyright 2023 David Reid
- https://github.com/mackron/miniaudio

### This GDExtension
- MIT License
- Part of RhythmGame project

## Troubleshooting

**Extension not loading:**
- Check Godot version matches godot-cpp checkout
- Verify binary exists in `bin/` directory
- Check Godot console for error messages

**Decoding fails:**
- Verify file is valid audio format
- Check file path is correct
- Try with a different audio file

**Build errors:**
- Ensure godot-cpp is properly cloned
- Verify compiler is in PATH
- Check SCons version (3.0+)

## Credits

- **miniaudio**: David Reid (mackron)
- **godot-cpp**: Godot Engine contributors
