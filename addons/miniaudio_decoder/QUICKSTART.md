# Quick Start Guide - MiniaudioDecoder GDExtension

This guide will get you up and running with real audio waveforms in your chart editor.

## What You're Building

A GDExtension that uses the **miniaudio** library to decode OGG, MP3, FLAC, and WAV files into raw PCM data for waveform visualization.

## Prerequisites

- **Windows**: Visual Studio 2019+ with C++ tools
- **Python 3.6+** and **SCons**: `pip install scons`
- **Git**: For cloning dependencies

## Step-by-Step Setup (Windows)

### 1. Run Setup Script

Open PowerShell or Command Prompt in the project root:

```bash
cd addons\miniaudio_decoder
setup.bat
```

This will:
- Clone godot-cpp
- Download miniaudio.h and miniaudio.c

### 2. Build godot-cpp

**Important**: Use "x64 Native Tools Command Prompt for VS" (search in Start menu)

```bash
cd godot-cpp
scons platform=windows target=template_debug
scons platform=windows target=template_release
cd ..
```

This takes 5-10 minutes. You'll see many `.obj` files being compiled.

### 3. Build the Extension

Still in the same command prompt:

```bash
scons platform=windows target=template_debug
scons platform=windows target=template_release
```

This takes 1-2 minutes.

### 4. Verify Build

Check that these files exist:
```
addons/miniaudio_decoder/bin/windows/
  ├── libminiaudio_decoder.windows.template_debug.x86_64.dll
  └── libminiaudio_decoder.windows.template_release.x86_64.dll
```

### 5. Test in Godot

1. Open your Godot project
2. Go to **Project → Reload Current Project**
3. Open the Script editor and try:

```gdscript
func test_miniaudio():
    var decoder = MiniaudioDecoder.new()
    if decoder:
        print("✓ MiniaudioDecoder loaded!")
        var samples = decoder.extract_pcm("res://path/to/song.ogg")
        print("Extracted ", samples.size(), " samples")
        print("Sample rate: ", decoder.get_sample_rate())
    else:
        print("✗ MiniaudioDecoder failed to load")
```

### 6. Use in Chart Editor

The AudioPCMExtractor is already configured to use MiniaudioDecoder automatically.

Just load an OGG/MP3/FLAC file in your chart editor and the waveform should appear!

## Troubleshooting

### "Extension not loading"

**Check the Godot console** for errors. Common issues:

- **Wrong command prompt**: Must use "x64 Native Tools Command Prompt for VS"
- **Wrong Godot version**: godot-cpp checkout must match your Godot version
- **Missing files**: Verify miniaudio.h and miniaudio.c are in `src/`

### "scons: command not found"

Install SCons:
```bash
pip install scons
```

### "Cannot open include file: 'godot_cpp/...'"

godot-cpp wasn't built. Go to step 2.

### Build fails with "undefined reference"

Ensure `miniaudio.c` exists in `src/` (not just `.h`).

### Extension loads but decoding fails

- Verify the audio file is valid (try playing it in another app)
- Check file path is correct (`res://` or absolute path)
- Enable verbose logging: add `-v` to scons command

## If You Get Stuck

1. **Clean build**: 
   ```bash
   scons -c
   cd godot-cpp
   scons -c
   cd ..
   ```
   Then rebuild from step 2.

2. **Check BUILD.md** for detailed instructions

3. **Check Documentation/MiniaudioGDExtension-Implementation.md** for architecture details

## Next Steps

Once working:
- Test with various audio formats (OGG, MP3, FLAC)
- Check waveform quality in chart editor
- Adjust downsampling in `chart_editor_waveform_manager.gd` if needed

## Disabling the Extension

If you need to temporarily disable MiniaudioDecoder:

In `Scripts/Editor/Services/audio_pcm_extractor.gd`, change:
```gdscript
const USE_MINIAUDIO_EXTENSION: bool = false
```

This will skip GDExtension loading (no errors if extension isn't built).

## Success!

You should now have **real waveform visualization** for all your audio files, just like Moonscraper! 🎵
