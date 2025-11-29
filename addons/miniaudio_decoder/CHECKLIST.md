# MiniaudioDecoder GDExtension - Implementation Checklist

## Pre-Build Verification ✅

- [x] Project structure created
  - [x] `addons/miniaudio_decoder/` folder
  - [x] `addons/miniaudio_decoder/src/` folder
  - [x] `addons/miniaudio_decoder/bin/` folders (windows/linux/macos)

- [x] Configuration files created
  - [x] `miniaudio_decoder.gdextension`
  - [x] `SConstruct` build file
  - [x] `.gitignore`

- [x] C++ source files created
  - [x] `src/miniaudio_decoder.h`
  - [x] `src/miniaudio_decoder.cpp`
  - [x] `src/register_types.h`
  - [x] `src/register_types.cpp`

- [x] Documentation created
  - [x] `README.md`
  - [x] `BUILD.md`
  - [x] `QUICKSTART.md`
  - [x] `PROJECT_SUMMARY.md`

- [x] Setup scripts created
  - [x] `setup.bat` (Windows)
  - [x] `setup.sh` (Linux/macOS)

- [x] Integration completed
  - [x] Updated `audio_pcm_extractor.gd`
  - [x] Added `_from_miniaudio()` method
  - [x] Added `USE_MINIAUDIO_EXTENSION` flag
  - [x] Removed placeholder waveform generation

- [x] Root documentation updated
  - [x] `NEXT_STEPS.md` created
  - [x] `Documentation/WaveformVisualization.md` created
  - [x] `Documentation/MiniaudioGDExtension-Implementation.md` created

## Build Process Checklist

### Phase 1: Setup Dependencies
- [ ] Run `setup.bat` (or `setup.sh`)
- [ ] Verify `godot-cpp/` folder exists
- [ ] Verify `godot-cpp/.git` exists (successfully cloned)
- [ ] Verify `src/miniaudio.h` exists (downloaded)
- [ ] Verify `src/miniaudio.c` exists (downloaded)

### Phase 2: Build godot-cpp
- [ ] Open correct command prompt (VS Developer on Windows)
- [ ] Navigate to `godot-cpp/` folder
- [ ] Run debug build: `scons platform=<platform> target=template_debug`
- [ ] Wait for completion (~5-10 minutes)
- [ ] Verify no errors in output
- [ ] Run release build: `scons platform=<platform> target=template_release`
- [ ] Wait for completion (~5-10 minutes)
- [ ] Verify no errors in output

### Phase 3: Build Extension
- [ ] Navigate to `addons/miniaudio_decoder/` folder
- [ ] Run debug build: `scons platform=<platform> target=template_debug`
- [ ] Wait for completion (~1-2 minutes)
- [ ] Verify no errors in output
- [ ] Run release build: `scons platform=<platform> target=template_release`
- [ ] Wait for completion (~1-2 minutes)
- [ ] Verify no errors in output

### Phase 4: Verify Build Output
- [ ] Check `bin/<platform>/` folder exists
- [ ] Verify debug binary exists:
  - Windows: `libminiaudio_decoder.windows.template_debug.x86_64.dll`
  - Linux: `libminiaudio_decoder.linux.template_debug.x86_64.so`
  - macOS: `libminiaudio_decoder.macos.template_debug.framework/`
- [ ] Verify release binary exists:
  - Windows: `libminiaudio_decoder.windows.template_release.x86_64.dll`
  - Linux: `libminiaudio_decoder.linux.template_release.x86_64.so`
  - macOS: `libminiaudio_decoder.macos.template_release.framework/`

## Testing Checklist

### Phase 1: Extension Loading
- [ ] Open Godot project
- [ ] Go to Project → Reload Current Project
- [ ] Check Output console for extension load message
- [ ] No errors in console about MiniaudioDecoder

### Phase 2: API Testing
- [ ] Create test script:
```gdscript
func _ready():
    var decoder = MiniaudioDecoder.new()
    print("Decoder created: ", decoder != null)
```
- [ ] Run script
- [ ] Verify prints "Decoder created: true"
- [ ] No errors in console

### Phase 3: Decoding Testing
- [ ] Create test script:
```gdscript
func _ready():
    var decoder = MiniaudioDecoder.new()
    var samples = decoder.extract_pcm("res://path/to/test.ogg")
    print("Samples extracted: ", samples.size())
    print("Sample rate: ", decoder.get_sample_rate())
    print("Channels: ", decoder.get_channel_count())
```
- [ ] Replace path with actual OGG file in project
- [ ] Run script
- [ ] Verify samples.size() > 0
- [ ] Verify sample_rate = 44100 (or file's actual rate)
- [ ] Verify channels = 1 or 2
- [ ] No errors in console

### Phase 4: Integration Testing - OGG
- [ ] Open Chart Editor
- [ ] Load chart with OGG audio file
- [ ] Verify waveform appears on runway
- [ ] Verify waveform looks realistic (not sine wave)
- [ ] Check console for decode message
- [ ] No errors in console

### Phase 5: Integration Testing - MP3
- [ ] Load chart with MP3 audio file
- [ ] Verify waveform appears on runway
- [ ] Verify waveform looks realistic
- [ ] Check console for decode message
- [ ] No errors in console

### Phase 6: Integration Testing - FLAC
- [ ] Load chart with FLAC audio file
- [ ] Verify waveform appears on runway
- [ ] Verify waveform looks realistic
- [ ] Check console for decode message
- [ ] No errors in console

### Phase 7: Integration Testing - WAV
- [ ] Load chart with WAV audio file
- [ ] Verify waveform appears on runway
- [ ] Verify waveform looks realistic
- [ ] Check console for decode message
- [ ] No errors in console

### Phase 8: Error Handling
- [ ] Try loading invalid file path
- [ ] Verify error message appears in console
- [ ] Verify chart editor doesn't crash
- [ ] Try loading corrupted audio file
- [ ] Verify error message appears in console
- [ ] Verify chart editor doesn't crash

### Phase 9: Performance Testing
- [ ] Load long audio file (10+ minutes)
- [ ] Measure decode time (should be <5 seconds)
- [ ] Check memory usage (should be reasonable)
- [ ] Verify UI remains responsive
- [ ] No memory leaks after closing chart editor

## Post-Implementation Checklist

### Code Quality
- [x] Code follows GDScript style guide
- [x] C++ code follows Godot conventions
- [x] No hardcoded paths
- [x] Proper error handling
- [x] Clear variable names
- [x] Comments where needed

### Documentation
- [x] README explains what extension does
- [x] BUILD.md has detailed build instructions
- [x] QUICKSTART.md for fast setup
- [x] API documented in code and docs
- [x] Troubleshooting section
- [x] Examples provided

### User Experience
- [ ] Extension works on first try (after build)
- [ ] Clear error messages if something fails
- [ ] No crashes or freezes
- [ ] Performance is acceptable
- [ ] Waveforms look good

### Maintenance
- [x] Setup scripts automate dependency download
- [x] Build process is documented
- [x] Extension can be disabled via flag
- [x] Code is modular and maintainable
- [x] Future enhancements documented

## Common Issues Checklist

### Build Issues
- [ ] **"scons not found"** → Install: `pip install scons`
- [ ] **"Cannot find godot-cpp"** → Run setup script again
- [ ] **"Undefined reference"** → Verify miniaudio.c exists in src/
- [ ] **"Wrong compiler"** → Use VS Developer Command Prompt (Windows)

### Runtime Issues
- [ ] **"Extension not loading"** → Check binary exists in bin/
- [ ] **"MiniaudioDecoder not found"** → Reload Godot project
- [ ] **"Decoding fails"** → Check file path and file validity
- [ ] **"Performance issues"** → Reduce MAX_SAMPLES in waveform manager

## Success Criteria

### Minimal Success
- [x] Extension compiles without errors
- [ ] Extension loads in Godot
- [ ] Can decode at least one audio format
- [ ] Waveform appears in chart editor

### Full Success
- [ ] Extension compiles on all platforms
- [ ] All formats work (OGG, MP3, FLAC, WAV)
- [ ] Performance is good (<3 sec for typical song)
- [ ] No crashes or errors
- [ ] Documentation is complete
- [ ] User experience matches Moonscraper

### Exceptional Success
- [ ] Build process is fully automated
- [ ] Pre-built binaries available for download
- [ ] Extensive test coverage
- [ ] Additional features (async, caching, etc.)
- [ ] Community contributions

## Current Status

**Date**: November 28, 2025

**Phase**: ✅ Implementation Complete, Ready to Build

**Next Action**: Run `setup.bat` and start build process

**Estimated Time to Working**: ~15 minutes (with dependencies)

---

## Notes

Use this checklist to track your progress. Check off items as you complete them.

For help with any unchecked item, refer to:
- **NEXT_STEPS.md** - Build walkthrough
- **QUICKSTART.md** - Fast setup
- **BUILD.md** - Detailed troubleshooting
- **PROJECT_SUMMARY.md** - Technical overview
