# Next Steps - Building Your MiniaudioDecoder GDExtension

## Implementation Status: ✅ Code Complete

All implementation files have been created. You now need to:
1. Download dependencies (automated)
2. Build the extension (15 minutes)
3. Test in your chart editor

---

## Step 1: Run Setup Script (2 minutes)

Open **Command Prompt** or **PowerShell** in your project root:

```bash
cd addons\miniaudio_decoder
setup.bat
```

This automatically:
- Clones godot-cpp repository
- Downloads miniaudio.h and miniaudio.c
- Verifies all dependencies

**Linux/macOS**: Use `bash setup.sh` instead

---

## Step 2: Build godot-cpp (5-10 minutes)

⚠️ **IMPORTANT FOR WINDOWS**: You MUST use **"x64 Native Tools Command Prompt for VS"**
- Search for it in Start Menu
- Regular Command Prompt will NOT work

```bash
cd godot-cpp
scons platform=windows target=template_debug
scons platform=windows target=template_release
cd ..
```

**What's happening**: Compiling Godot's C++ bindings. This is slow but only done once.

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

---

## Step 3: Build the Extension (1-2 minutes)

In the same command prompt:

```bash
scons platform=windows target=template_debug
scons platform=windows target=template_release
```

**Expected output**: 
```
Compiling src/miniaudio_decoder.cpp ...
Compiling src/register_types.cpp ...
Compiling src/miniaudio.c ...
Linking bin/windows/libminiaudio_decoder.windows.template_debug.x86_64.dll
```

---

## Step 4: Verify Build

Check that these files exist:

**Windows**:
```
addons/miniaudio_decoder/bin/windows/
  ├── libminiaudio_decoder.windows.template_debug.x86_64.dll
  └── libminiaudio_decoder.windows.template_release.x86_64.dll
```

**Linux**:
```
addons/miniaudio_decoder/bin/linux/
  ├── libminiaudio_decoder.linux.template_debug.x86_64.so
  └── libminiaudio_decoder.linux.template_release.x86_64.so
```

**macOS**:
```
addons/miniaudio_decoder/bin/macos/
  ├── libminiaudio_decoder.macos.template_debug.framework/
  └── libminiaudio_decoder.macos.template_release.framework/
```

If these files exist, **you're done building**! 🎉

---

## Step 5: Test in Godot (1 minute)

1. **Open your Godot project**

2. **Reload the project**: Project → Reload Current Project

3. **Check if extension loaded**: Look in Output console for:
   ```
   [Loaded extension: MiniaudioDecoder]
   ```

4. **Test with a script**:
   ```gdscript
   func _ready():
       var decoder = MiniaudioDecoder.new()
       if decoder:
           print("✓ MiniaudioDecoder is working!")
       else:
           print("✗ Extension failed to load")
   ```

---

## Step 6: Test Real Waveform

1. Open your **Chart Editor**
2. Load a song with **OGG, MP3, or FLAC** format
3. The waveform should now display **real audio data** instead of placeholder sine waves

**What to look for**:
- Waveform matches the actual audio peaks and valleys
- Console prints: `"Decoded X samples (44100 Hz, 2 channels) from song.ogg"`
- No errors in console

---

## Troubleshooting

### "Extension not loading in Godot"

**Check Godot console** for specific error messages.

**Common fixes**:
1. Wrong command prompt (must use VS Developer Command Prompt)
2. godot-cpp version mismatch (checkout 4.3 branch)
3. Missing files (run setup.bat again)

### "scons: command not found"

```bash
pip install scons
```

### "Cannot find godot-cpp"

```bash
cd addons/miniaudio_decoder
git clone https://github.com/godotengine/godot-cpp.git
cd godot-cpp
git checkout 4.3
```

### Build errors

**Clean and rebuild**:
```bash
scons -c
cd godot-cpp
scons -c
cd ..
# Then rebuild from Step 2
```

### Extension loads but decoding fails

- Verify audio file is valid (play it in another app)
- Check file path is correct
- Look for error messages in Godot console

---

## If You Get Stuck

### Quick Checklist
- [ ] Ran setup.bat/setup.sh
- [ ] Used correct command prompt (VS Developer on Windows)
- [ ] godot-cpp built successfully (no errors)
- [ ] Extension built successfully (DLL/SO files exist)
- [ ] Reloaded Godot project
- [ ] No errors in Godot console

### Detailed Help
- See **QUICKSTART.md** for common issues
- See **BUILD.md** for detailed troubleshooting
- See **PROJECT_SUMMARY.md** for architecture overview

---

## After Success

Once working, you can:

### 1. Test All Formats
- Load OGG files
- Load MP3 files
- Load FLAC files
- Verify waveforms look correct

### 2. Adjust Settings
In `audio_pcm_extractor.gd`:
```gdscript
const USE_MINIAUDIO_EXTENSION: bool = true  # Set false to disable
```

### 3. Optimize Performance
In `chart_editor_waveform_manager.gd`, adjust downsampling:
```gdscript
const MAX_SAMPLES := 50000  # Increase for more detail
```

### 4. Commit Your Changes
```bash
git add addons/miniaudio_decoder
git add Scripts/Editor/Services/audio_pcm_extractor.gd
git commit -m "Add MiniaudioDecoder GDExtension for real waveforms"
```

⚠️ **Don't commit**: `godot-cpp/` and `bin/` folders (add to .gitignore)

---

## Distribution

### For Other Developers
Share the source code - they build it themselves:
- Commit `addons/miniaudio_decoder/src/`
- Commit setup scripts and documentation
- Don't commit `godot-cpp/` or `bin/`

### For End Users (Game Release)
Include pre-built binaries:
- Commit `addons/miniaudio_decoder/bin/` with all platform DLLs/SOs
- Users don't need to build anything
- Extension loads automatically

---

## Summary

✅ **What you have**: Complete GDExtension source code ready to build

⏭️ **What to do**: Run `setup.bat`, build godot-cpp, build extension, test

⏱️ **How long**: ~15 minutes total

🎯 **End result**: Real waveforms for OGG/MP3/FLAC like Moonscraper

---

## Ready to Start?

```bash
cd addons\miniaudio_decoder
setup.bat
```

Then follow Steps 2-6 above. Good luck! 🚀
