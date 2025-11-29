# Miniaudio Decoder GDExtension - Build Instructions

## Prerequisites

### All Platforms
- Python 3.6+
- SCons: `pip install scons`
- Git

### Windows
- Visual Studio 2019 or later (MSVC)
- Open "x64 Native Tools Command Prompt for VS" to build

### Linux
- GCC or Clang
- Make
- Install: `sudo apt install build-essential scons`

### macOS
- Xcode Command Line Tools: `xcode-select --install`
- SCons: `pip3 install scons`

## Setup Steps

### 1. Clone godot-cpp

```bash
cd addons/miniaudio_decoder
git clone https://github.com/godotengine/godot-cpp.git
cd godot-cpp
git checkout 4.3  # Match your Godot version (check project.godot)
cd ..
```

### 2. Download miniaudio

Visit https://github.com/mackron/miniaudio and download:
- `miniaudio.h`
- `miniaudio.c`

Place both files in `src/` directory.

Or use curl/wget:
```bash
cd src
curl -O https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h
curl -O https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.c
cd ..
```

### 3. Build godot-cpp

**Windows** (from Visual Studio Developer Command Prompt):
```bash
cd godot-cpp
scons platform=windows target=template_debug
scons platform=windows target=template_release
cd ..
```

**Linux**:
```bash
cd godot-cpp
scons platform=linux target=template_debug
scons platform=linux target=template_release
cd ..
```

**macOS**:
```bash
cd godot-cpp
scons platform=macos target=template_debug arch=universal
scons platform=macos target=template_release arch=universal
cd ..
```

### 4. Build the Extension

**Windows**:
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

## Verify Installation

After building, check that binaries exist:

**Windows**:
- `bin/windows/libminiaudio_decoder.windows.template_debug.x86_64.dll`
- `bin/windows/libminiaudio_decoder.windows.template_release.x86_64.dll`

**Linux**:
- `bin/linux/libminiaudio_decoder.linux.template_debug.x86_64.so`
- `bin/linux/libminiaudio_decoder.linux.template_release.x86_64.so`

**macOS**:
- `bin/macos/libminiaudio_decoder.macos.template_debug.framework/`
- `bin/macos/libminiaudio_decoder.macos.template_release.framework/`

## Testing in Godot

1. Open your Godot project
2. Go to Project > Reload Current Project
3. Try the extension:

```gdscript
var decoder = MiniaudioDecoder.new()
if decoder:
    print("MiniaudioDecoder loaded successfully!")
    var samples = decoder.extract_pcm("res://path/to/audio.ogg")
    print("Extracted ", samples.size(), " samples")
else:
    print("Failed to load MiniaudioDecoder")
```

## Troubleshooting

### "Cannot find godot-cpp"
- Ensure godot-cpp is cloned in `addons/miniaudio_decoder/godot-cpp`
- Check Git clone was successful

### "scons: command not found"
- Install SCons: `pip install scons`
- On macOS, try: `pip3 install scons`

### Build errors on Windows
- Must use "x64 Native Tools Command Prompt for VS"
- Verify Visual Studio is installed with C++ tools

### Extension not loading in Godot
- Check `miniaudio_decoder.gdextension` file paths
- Verify binary exists in `bin/` folder
- Check Godot console for error messages
- Ensure Godot version matches godot-cpp checkout

### "Undefined reference" errors
- Ensure miniaudio.c is in src/ folder
- Verify SConstruct includes .c files in sources
- Try clean rebuild: `scons -c` then build again

## Clean Build

To rebuild from scratch:

```bash
# Clean extension
scons -c

# Clean godot-cpp
cd godot-cpp
scons -c
cd ..

# Rebuild everything
# (follow build steps above)
```

## Cross-Compilation

You can build for different platforms if you have the right toolchain:

```bash
# On Linux, build for Windows (requires mingw)
scons platform=windows target=template_release

# Build for different architectures
scons platform=linux target=template_release arch=arm64
```

## Distribution

When distributing your game, include:
- `addons/miniaudio_decoder/miniaudio_decoder.gdextension`
- `addons/miniaudio_decoder/bin/` (with appropriate platform binaries)

Users don't need to build anything - the compiled binaries are included.
