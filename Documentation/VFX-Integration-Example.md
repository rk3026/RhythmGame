# Enhanced VFX Integration Example

This file shows how to integrate the new VFX system into your existing gameplay code.

## Example Integration in gameplay.gd

```gdscript
extends Node3D

# Existing references...
@onready var note_spawner = $NoteSpawner
@onready var score_manager = $ScoreManager

# NEW: VFX Manager reference
@onready var vfx_manager: GameplayVFXManager = $GameplayVFXManager

var current_combo: int = 0
var last_combo_milestone: int = 0

# Called when note hit detection occurs
func on_note_hit(note, judgement: String):
    var lane_index = note.lane_index
    var note_color = note.color  # or determine based on lane
    
    # Update score (existing logic)
    score_manager.process_hit(judgement)
    
    # NEW: Trigger VFX
    vfx_manager.trigger_note_hit(lane_index, judgement, note_color)
    
    # Handle combo
    if judgement in ["perfect", "great", "good"]:
        current_combo += 1
        
        # Check for combo milestones
        var milestone = int(current_combo / 25) * 25
        if milestone > last_combo_milestone and milestone > 0:
            last_combo_milestone = milestone
            # NEW: Trigger milestone VFX
            vfx_manager.trigger_combo_milestone(current_combo, Color.GOLD)
    else:
        current_combo = 0
        last_combo_milestone = 0
    
    # Update UI (existing logic)
    update_combo_display()

# For sustain/hold notes
func on_sustain_active(note, position: Vector3):
    # NEW: Trigger sustain particles
    vfx_manager.trigger_sustain_particle(note.lane_index, note.color, position)
```

## Example Lane Color Mapping

```gdscript
# Define colors for each lane (example)
const LANE_COLORS = [
    Color.GREEN,    # Lane 0
    Color.RED,      # Lane 1  
    Color.YELLOW,   # Lane 2
    Color.BLUE,     # Lane 3
]

func get_lane_color(lane_index: int) -> Color:
    if lane_index < LANE_COLORS.size():
        return LANE_COLORS[lane_index]
    return Color.WHITE
```

## Example Note Script Modification (for trails)

```gdscript
# In note.gd or similar
extends Node3D

@export var color: Color = Color.WHITE
@export var lane_index: int = 0
@export var enable_trail: bool = true

var trail_effect: Node3D
var previous_position: Vector3

func _ready():
    # NEW: Add trail effect
    if enable_trail:
        var NoteTrailEffect = preload("res://Scripts/note_trail_effect.gd")
        trail_effect = NoteTrailEffect.new()
        add_child(trail_effect)
        trail_effect.set_color(color)
        trail_effect.enable_trail(true)
    
    previous_position = global_position

func _process(delta):
    # Existing note movement...
    move_note(delta)
    
    # NEW: Update trail
    if trail_effect and enable_trail:
        var velocity = abs(global_position.z - previous_position.z) / delta
        trail_effect.update_trail(velocity)
    
    previous_position = global_position
```

## Setup Checklist

- [ ] Add GameplayVFXManager node to scene
- [ ] Add CameraShake child node to VFX manager
- [ ] Add PostProcessingManager child node to VFX manager  
- [ ] Add or configure WorldEnvironment in scene
- [ ] Assign all references in inspector
- [ ] Update gameplay.gd to call VFX manager methods
- [ ] (Optional) Add note trail effects to notes
- [ ] Test and tune effect parameters
- [ ] Adjust performance settings if needed

## Common Patterns

### Pattern 1: Simple Hit Integration
```gdscript
func on_hit(lane: int, quality: String, color: Color):
    vfx_manager.trigger_note_hit(lane, quality, color)
```

### Pattern 2: With Judgement Mapping
```gdscript
func on_hit(lane: int, timing_diff: float):
    var judgement = get_judgement(timing_diff)
    var color = LANE_COLORS[lane]
    vfx_manager.trigger_note_hit(lane, judgement, color)
```

### Pattern 3: With Combo Tracking
```gdscript
func on_hit(lane: int, judgement: String):
    vfx_manager.trigger_note_hit(lane, judgement, LANE_COLORS[lane])
    
    if is_good_hit(judgement):
        combo += 1
        if combo % 25 == 0:
            vfx_manager.trigger_combo_milestone(combo, Color.GOLD)
```

## Performance Tips

```gdscript
# In settings/pause menu
func set_graphics_quality(quality: int):
    match quality:
        0: # Low
            vfx_manager.enable_gpu_particles = false
            vfx_manager.enable_post_processing = false
        1: # Medium  
            vfx_manager.enable_gpu_particles = true
            vfx_manager.enable_post_processing = false
        2: # High
            vfx_manager.set_vfx_enabled(true)
```

## Testing the System

1. Run the game
2. Hit some notes
3. You should see:
   - Lane lights pulse on hits
   - Particle bursts at hit location
   - Subtle camera shake
   - Screen glow on good hits
   - (If implemented) Trails behind notes

4. Test combo milestones (25, 50, 100)
5. Adjust parameters in inspector as needed
