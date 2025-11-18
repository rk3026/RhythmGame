# Limit Break Feature - Implementation Summary

## Overview
The "Limit Break" feature (inspired by FF7) has been successfully implemented in your rhythm game. This feature allows players to charge up a meter by hitting notes, then activate a special mode that multiplies their score for a limited time.

## What Was Implemented

### 1. Core Logic (`Scripts/LimitBreakManager.gd`)
- **Charging System**: Accumulates charge based on hit grades (Perfect: 4.0, Great: 2.5, Good: 1.5)
- **Activation**: Triggers when fully charged and activated by player
- **Duration**: Active for 10 seconds by default
- **Score Multiplier**: 2x score while active
- **Signals**: Emits events for charge changes, activation, deactivation, and ready state

### 2. Settings Integration (`Scripts/settings_manager.gd`)
- Added `limit_break_key` setting (default: SPACE)
- Per-profile setting (saved with profile data)
- Validation and migration support
- Getter/setter methods: `set_limit_break_key()`

### 3. UI Components
- **Charge Meter** (`Scenes/Components/limit_break_ui.tscn`): Shows current charge level
- **Ready Indicator**: Pulsing text when meter is full
- **Active Overlay**: Visual effect when Limit Break is active
- **Timer Display**: Shows remaining time during activation
- **UI Script** (`Scripts/UI/LimitBreakUI.gd`): Handles animations and updates

### 4. Gameplay Integration (`Scripts/gameplay.gd`)
- LimitBreakManager instantiated as child node
- Connected to note hit events for charging
- Applies score multiplier to ScoreManager
- Handles activation input (Space key by default)
- Updates UI in real-time

### 5. Visual Effects (`Scripts/gameplay_vfx_manager.gd`)
- **Activation Effects**: 
  - Intense camera shake
  - Orange/red screen flash
  - Particle burst across all lanes
- **Deactivation Effects**:
  - Light camera shake
  - Fade out effect

### 6. Score System (`Scripts/ScoreManager.gd`)
- Updated `add_hit()` to accept optional `score_multiplier` parameter
- Multiplies base score by Limit Break multiplier when active

### 7. Settings UI (`Scripts/settings.gd`)
- Logic for rebinding Limit Break key
- Automatic loading/saving of keybind
- Visual feedback during rebind process

## Configuration (in LimitBreakManager)

You can adjust these exported properties:
```gdscript
@export var max_charge: float = 100.0
@export var charge_per_perfect: float = 4.0
@export var charge_per_great: float = 2.5
@export var charge_per_good: float = 1.5
@export var duration: float = 10.0
@export var score_multiplier: float = 2.0
```

## Settings UI - Manual Addition Required

**IMPORTANT**: You need to manually add the Limit Break keybind UI to `Scenes/settings.tscn`. 

Add this node structure under `InputSection/InputMargin/InputContent/LaneKeys`:

```
[node name="LimitBreakKey" type="HBoxContainer" parent="..."]
custom_minimum_size = Vector2(0, 42)
layout_mode = 2

[node name="Label" type="Label" parent=".../LimitBreakKey"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 20
text = "Limit Break"

[node name="KeybindDisplay" type="PanelContainer" parent=".../LimitBreakKey"]
custom_minimum_size = Vector2(120, 0)
layout_mode = 2
script = ExtResource("3")  # KeybindDisplay script
key_text = "Space"
```

Or use the Godot Editor to:
1. Open `Scenes/settings.tscn`
2. Navigate to `InputSection/InputMargin/InputContent/LaneKeys`
3. Duplicate one of the Lane nodes (e.g., Lane0)
4. Rename to "LimitBreakKey"
5. Change the Label text to "Limit Break"
6. Change the KeybindDisplay key_text to "Space"

## How It Works (Player Experience)

1. **Charging**: Hit notes to fill the Limit Break meter
   - Perfect hits charge fastest
   - Great and Good hits charge slower
   - Misses don't charge the meter

2. **Ready State**: When meter is full
   - "READY! Press SPACE to activate!" message appears
   - Message pulses to draw attention

3. **Activation**: Press Space (or configured key)
   - Screen flashes orange/red
   - Particles burst across lanes
   - Timer appears showing remaining duration
   - Orange overlay indicates active state

4. **Active Mode**: For 10 seconds
   - All scores are doubled
   - Visual overlay remains
   - Timer counts down

5. **Deactivation**: After 10 seconds
   - Meter empties
   - Visual effects fade
   - Returns to normal scoring

## Testing Checklist

- [ ] Meter charges when hitting notes
- [ ] Meter fills faster on Perfect hits
- [ ] Ready indicator appears when full
- [ ] Space key activates Limit Break
- [ ] Score is doubled during activation
- [ ] Timer displays correctly
- [ ] Visual effects trigger on activation
- [ ] Feature deactivates after 10 seconds
- [ ] Settings UI allows rebinding the key
- [ ] Key binding persists across game sessions

## Files Modified

1. `Scripts/LimitBreakManager.gd` (NEW)
2. `Scripts/UI/LimitBreakUI.gd` (NEW)
3. `Scenes/Components/limit_break_ui.tscn` (NEW)
4. `Scripts/settings_manager.gd` (MODIFIED)
5. `Scripts/settings.gd` (MODIFIED)
6. `Scripts/gameplay.gd` (MODIFIED)
7. `Scripts/gameplay_vfx_manager.gd` (MODIFIED)
8. `Scripts/ScoreManager.gd` (MODIFIED)

## Customization Ideas

- Adjust charge rates for different hit grades
- Change the score multiplier (2x, 3x, etc.)
- Modify duration
- Add charge decay when not hitting notes
- Add cooldown period after use
- Create different visual themes
- Add sound effects for activation/deactivation
- Trigger different effects at different charge levels
