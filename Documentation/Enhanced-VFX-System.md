# Enhanced Visual Effects System

## Overview

This document describes the new enhanced visual effects (VFX) system inspired by Fortnite Festival and other modern rhythm games. The system includes:

- **Lane Lighting Effects**: Dynamic light strips that illuminate when notes are hit
- **GPU Particle System**: High-performance particle bursts using GPUParticles3D
- **Camera Shake**: Impact feedback for hits and combos
- **Post-Processing**: Bloom/glow effects and screen flashes
- **Note Trail Effects**: Glowing trails behind notes for better visibility

## System Architecture

### Core Components

1. **GameplayVFXManager** - Central coordinator for all VFX
2. **LaneLightingEffect** - Individual lane light strips
3. **EnhancedHitEffect** - GPU-based particle effects
4. **CameraShake** - Camera trauma system for shake effects
5. **PostProcessingManager** - Screen-space effects manager
6. **NoteTrailEffect** - Trailing glow behind notes

## Integration Guide

### Step 1: Add to Gameplay Scene

1. Open `Scenes/gameplay.tscn`
2. Add the following nodes to the scene tree:

```
Gameplay (Node3D)
├── Camera3D
├── WorldEnvironment  (if not already present)
├── GameplayVFXManager (Node)
│   ├── CameraShake (Node)
│   └── PostProcessingManager (Node)
└── ... (existing nodes)
```

### Step 2: Configure Scripts

1. Add `GameplayVFXManager.gd` script to the GameplayVFXManager node
2. Add `CameraShake.gd` script to the CameraShake node
3. Add `PostProcessingManager.gd` script to the PostProcessingManager node

### Step 3: Set Up References

In the **GameplayVFXManager** inspector:
- Set `Camera Shake` → Reference to CameraShake node
- Set `Post Processing` → Reference to PostProcessingManager node

In the **CameraShake** inspector:
- Set `Target Camera` → Reference to Camera3D

In the **PostProcessingManager** inspector:
- Set `World Environment` → Reference to WorldEnvironment

### Step 4: Configure WorldEnvironment

The PostProcessingManager will automatically configure bloom/glow, but you can adjust:
- `Glow Intensity`: Base brightness of bloom (default 0.5)
- `Glow Strength`: Strength of bloom spread (default 0.7)
- Enable/disable in settings as needed

### Step 5: Integrate with Gameplay Code

In your `gameplay.gd` or note hit detection code:

```gdscript
# Get reference to VFX manager
@onready var vfx_manager: GameplayVFXManager = $GameplayVFXManager

# When a note is hit:
func on_note_hit(lane_index: int, judgement: String, note_color: Color):
    # Trigger all VFX for this hit
    vfx_manager.trigger_note_hit(lane_index, judgement, note_color)
    
    # Existing hit logic...
    score_manager.add_hit(judgement)
    # etc.

# For combo milestones:
func on_combo_milestone(combo: int):
    vfx_manager.trigger_combo_milestone(combo, Color.GOLD)

# For sustain notes:
func on_sustain_tick(lane_index: int, position: Vector3, color: Color):
    vfx_manager.trigger_sustain_particle(lane_index, color, position)
```

### Step 6: Add Note Trails (Optional)

To add glowing trails behind notes:

```gdscript
# In your note script (note.gd):
var trail_effect: NoteTrailEffect

func _ready():
    # Create trail effect
    trail_effect = preload("res://Scripts/note_trail_effect.gd").new()
    add_child(trail_effect)
    trail_effect.set_color(note_color)
    trail_effect.enable_trail(true)

func _process(delta):
    # Update trail based on movement
    var velocity = abs(global_position.z - previous_position.z) / delta
    trail_effect.update_trail(velocity)
    previous_position = global_position
```

## Customization

### Adjusting Effect Intensity

In **GameplayVFXManager** inspector, you can adjust:

**Intensity Settings:**
- Enable/disable individual effect types
- Useful for performance tuning or accessibility

**Camera Shake Settings:**
- `Light Hit Shake`: 0.08 (good/okay hits)
- `Medium Hit Shake`: 0.12 (great hits)
- `Heavy Hit Shake`: 0.18 (perfect hits)
- `Combo Milestone Shake`: 0.15 (every 25/50/100 combo)

**Flash Settings:**
- `Perfect Hit Flash Intensity`: 1.2
- `Good Hit Flash Intensity`: 0.8
- `Okay Hit Flash Intensity`: 0.5

### Lane Lighting Customization

In **LaneLightingEffect** (per-lane):
- `Light Length`: How far forward/backward the light extends (default: 8.0)
- `Light Width`: Width of light strip, should match lane width (default: 0.8)
- `Pulse Duration`: How long the light pulse lasts (default: 0.4s)
- `Emission Strength`: Brightness multiplier (default: 3.0)

### GPU Particle Customization

In **EnhancedHitEffect**:
- `Effect Lifetime`: How long particles exist (default: 0.6s)
- `Explosion Power`: Initial burst velocity (default: 2.5)
- `Particle Count`: Number of particles per burst (default: 20)
- `Spread Angle`: Cone angle of particle spread (default: 30 degrees)

### Post-Processing Customization

In **PostProcessingManager**:
- `Flash Duration`: Length of screen flash (default: 0.15s)
- `Flash Intensity`: Brightness of flash effect (default: 0.3)
- Adjust base glow via `set_glow_intensity(float)` method

## Performance Considerations

### Optimization Tips

1. **Particle Pooling**: The system uses object pooling for particles and lights
2. **LOD**: Reduce `Particle Count` on lower-end hardware
3. **Disable Effects**: Use the enable flags to turn off expensive effects
4. **GPU Particles**: Much more efficient than CPU particles for 20+ particles

### Performance Settings

Add to your settings/options:
```gdscript
func set_vfx_quality(quality: String):
    match quality:
        "Low":
            vfx_manager.enable_gpu_particles = false
            vfx_manager.enable_post_processing = false
            vfx_manager.enable_camera_shake = true
            vfx_manager.enable_lane_lighting = true
        "Medium":
            vfx_manager.enable_gpu_particles = true
            vfx_manager.enable_post_processing = false
            vfx_manager.enable_camera_shake = true
            vfx_manager.enable_lane_lighting = true
        "High":
            vfx_manager.set_vfx_enabled(true)
```

## Comparison to Original System

### Before (hit_effect.gd):
- Simple quad meshes with fading
- CPU-based animation
- ~12 particles per hit
- No lane lighting
- No camera shake
- No post-processing

### After (Enhanced System):
- GPU-accelerated particles
- Dynamic lane lighting
- Screen-space bloom/glow
- Camera shake feedback
- Note trail effects
- Coordinated multi-layer effects
- Performance-friendly pooling

## Technical Details

### Rendering Pipeline

1. **3D Scene Rendering**: Notes, particles, lane lights
2. **Emissive Materials**: Glow from particles and lights
3. **Post-Processing**: WorldEnvironment applies bloom to emissive areas
4. **Camera Shake**: Applied to camera transform in _process()

### Effect Layering

Effects are triggered in this order for maximum impact:
1. Lane lighting (fast pulse)
2. GPU particle burst (explosive)
3. Camera shake (immediate trauma)
4. Screen flash (quick bloom spike)
5. Trail effects (continuous)

### Color System

All effects use the note color for consistency:
- Lane lights: Full saturation
- Particles: Full saturation with additive blending
- Screen flash: Tinted glow boost
- Trails: Slightly desaturated for subtlety

## Troubleshooting

### Lane lights not visible
- Check `enable_lane_lighting` is true
- Verify lane positions match your note lanes
- Increase `Emission Strength` parameter

### Particles not showing
- Ensure `enable_gpu_particles` is true
- Check particle pool isn't exhausted (increase `max_pool_size`)
- Verify particle color isn't transparent

### No bloom/glow
- Check WorldEnvironment exists in scene
- Enable `Glow Enabled` in Environment
- Increase `Glow Intensity` and `Glow Strength`
- Ensure materials have emission enabled

### Camera shake too strong/weak
- Adjust shake intensity values in GameplayVFXManager
- Modify `trauma_decay_rate` in CameraShake for faster/slower recovery
- Reduce `max_shake_offset` and `max_shake_rotation` for subtler effect

## Future Enhancements

Potential additions for the VFX system:
- Combo streak visual effects (screen borders, colors)
- Miss effect (different particle type, red flash)
- Difficulty-based VFX intensity
- Custom per-song VFX themes
- Beat-synced environment pulsing
- FC (Full Combo) celebration effects

## Credits

System designed based on research of:
- Fortnite Festival (Epic Games)
- Guitar Hero series
- Rock Band series
- Godot 4 documentation (Context7)
