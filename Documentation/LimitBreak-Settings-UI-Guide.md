# Quick Guide: Adding Limit Break Key to Settings UI

## Option 1: Using Godot Editor (Recommended)

1. Open `Scenes/settings.tscn` in the Godot Editor
2. In the Scene tree, navigate to:
   ```
   Margin → VBox → Scroll → CenterContainer → OptionsContainer → InputSection → InputMargin → InputContent → LaneKeys
   ```
3. Right-click on `Lane0` (or any lane node) and select "Duplicate"
4. Rename the duplicated node to `LimitBreakKey`
5. Drag it to be positioned after `Lane5` (at the end of the lane keys list)
6. Select the `LimitBreakKey` node
7. In the Inspector, find the child `Label` node and change its `text` property to: `"Limit Break"`
8. Find the child `KeybindDisplay` node and change its `key_text` property to: `"Space"`
9. Save the scene (Ctrl+S)

## Option 2: Manual TSCN Edit (Advanced)

Add this after the `Lane5` node in `Scenes/settings.tscn`:

```gdscene
[node name="LimitBreakKey" type="HBoxContainer" parent="Margin/VBox/Scroll/CenterContainer/OptionsContainer/InputSection/InputMargin/InputContent/LaneKeys"]
custom_minimum_size = Vector2(0, 42)
layout_mode = 2

[node name="Label" type="Label" parent="Margin/VBox/Scroll/CenterContainer/OptionsContainer/InputSection/InputMargin/InputContent/LaneKeys/LimitBreakKey"]
layout_mode = 2
size_flags_horizontal = 3
theme_override_font_sizes/font_size = 20
text = "Limit Break"

[node name="KeybindDisplay" type="PanelContainer" parent="Margin/VBox/Scroll/CenterContainer/OptionsContainer/InputSection/InputMargin/InputContent/LaneKeys/LimitBreakKey"]
custom_minimum_size = Vector2(120, 0)
layout_mode = 2
script = ExtResource("3")
key_text = "Space"
```

**Note**: Make sure ExtResource("3") matches the same resource used for other KeybindDisplay nodes in your settings.tscn file.

## Testing

After adding the UI element:

1. Run the game
2. Go to Settings
3. Scroll to the "Input" section
4. You should see "Limit Break" with a "Space" key display
5. Click on the key display
6. Press a new key to rebind
7. The new binding should save automatically

## Verification

The feature will work even without the UI element added - the default Space key will be used. The UI element just allows players to customize the keybind.

To verify the feature is working:
1. Start a song in gameplay
2. Hit notes to see the Limit Break meter (orange bar) fill up
3. When it's full, press Space
4. You should see an orange overlay and 2x score multiplier

## Troubleshooting

If the Limit Break meter doesn't appear:
- Check that `Scenes/Components/limit_break_ui.tscn` exists
- Check console for any errors during gameplay startup

If the Space key doesn't activate:
- Check that SettingsManager.limit_break_key is set correctly
- Try restarting the game to reload settings
