@echo off
REM Setup script for MiniaudioDecoder GDExtension (Windows)
REM Run this script to download dependencies and prepare for building

echo === MiniaudioDecoder GDExtension Setup ===
echo.

REM Check if godot-cpp exists
if not exist "godot-cpp" (
    echo Cloning godot-cpp...
    git clone https://github.com/godotengine/godot-cpp.git
    cd godot-cpp
    echo Checking out Godot 4.3 branch...
    git checkout 4.3
    cd ..
    echo [OK] godot-cpp cloned successfully
) else (
    echo [OK] godot-cpp already exists
)

REM Check if miniaudio files exist
if not exist "src\miniaudio.h" (
    echo.
    echo Downloading miniaudio library...
    cd src
    curl -O https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h
    curl -O https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.c
    cd ..
    echo [OK] miniaudio downloaded successfully
) else (
    if not exist "src\miniaudio.c" (
        echo.
        echo Downloading miniaudio.c...
        cd src
        curl -O https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.c
        cd ..
        echo [OK] miniaudio.c downloaded successfully
    ) else (
        echo [OK] miniaudio already exists
    )
)

echo.
echo === Setup Complete ===
echo.
echo Next steps:
echo 1. Open "x64 Native Tools Command Prompt for VS"
echo 2. Navigate to this directory
echo 3. Build godot-cpp:
echo    cd godot-cpp
echo    scons platform=windows target=template_debug
echo    scons platform=windows target=template_release
echo    cd ..
echo.
echo 4. Build the extension:
echo    scons platform=windows target=template_debug
echo    scons platform=windows target=template_release
echo.
echo For detailed instructions, see BUILD.md
echo.
pause
