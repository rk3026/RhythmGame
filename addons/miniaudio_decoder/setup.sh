#!/bin/bash
# Setup script for MiniaudioDecoder GDExtension
# Run this script to download dependencies and prepare for building

set -e

echo "=== MiniaudioDecoder GDExtension Setup ==="
echo ""

# Check if godot-cpp exists
if [ ! -d "godot-cpp" ]; then
    echo "Cloning godot-cpp..."
    git clone https://github.com/godotengine/godot-cpp.git
    cd godot-cpp
    echo "Checking out Godot 4.3 branch..."
    git checkout 4.3
    cd ..
    echo "✓ godot-cpp cloned successfully"
else
    echo "✓ godot-cpp already exists"
fi

# Check if miniaudio files exist
if [ ! -f "src/miniaudio.h" ] || [ ! -f "src/miniaudio.c" ]; then
    echo ""
    echo "Downloading miniaudio library..."
    cd src
    curl -O https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h
    curl -O https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.c
    cd ..
    echo "✓ miniaudio downloaded successfully"
else
    echo "✓ miniaudio already exists"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Next steps:"
echo "1. Build godot-cpp:"
echo "   cd godot-cpp"
echo "   scons platform=<your_platform> target=template_debug"
echo "   scons platform=<your_platform> target=template_release"
echo "   cd .."
echo ""
echo "2. Build the extension:"
echo "   scons platform=<your_platform> target=template_debug"
echo "   scons platform=<your_platform> target=template_release"
echo ""
echo "Platforms: windows, linux, macos"
echo ""
echo "For detailed instructions, see BUILD.md"
