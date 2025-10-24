# Profile Editor Implementation

**Date:** October 23, 2025  
**Feature:** Profile Editor (CRUD - Update Operation)

---

## Overview

The Profile Editor completes the CRUD operations for the profile system by implementing the **Update** functionality. Players can now modify their profile information including avatar, display name, bio, and theme colors.

---

## Files Created

### 1. Scenes/profile_editor.tscn
Complete UI layout for the profile editor screen following single responsibility principle.

**UI Structure:**
- **NavigationBar**: Cancel and Save buttons
- **HeaderLabel**: "Edit Profile" title
- **AvatarSection**: 
  - Current avatar preview (120x120)
  - Avatar grid with all available avatars (6 columns, 64x64 each)
- **DisplayNameSection**: 
  - LineEdit for display name (3-20 characters)
  - Help text explaining the field
- **BioSection**: 
  - TextEdit for bio (max 200 characters)
  - Character counter with color coding
- **ColorSection**: 
  - Primary color picker
  - Accent color picker
- **ErrorLabel**: Validation/success message display

**Features:**
- All UI elements defined in scene with unique_name_in_owner flags
- Proper spacing and layout using VBoxContainer and HSeparators
- ScrollContainer for responsiveness on different screen sizes
- Theme overrides for consistent styling

### 2. Scripts/profile_editor.gd
Logic-only script for profile editing (no UI building).

**Key Features:**
- **Avatar Selection**: 
  - Dynamically loads all .svg files from Assets/Profiles/Avatars/
  - Creates TextureButton for each avatar
  - Updates current avatar preview on selection
  - Hover effects on avatar buttons
  
- **Input Validation**:
  - Display name: 3-20 characters, alphanumeric + spaces/underscores/hyphens only
  - Bio: Max 200 characters with live character counter
  - Color-coded character count (green → yellow → red)
  
- **Data Management**:
  - Loads current profile data on startup
  - Tracks original data for unsaved changes detection
  - Updates ProfileManager on save
  - Validates all inputs before saving
  
- **Navigation**:
  - Cancel button returns to profile_view
  - Save button validates, saves, shows success, then navigates back
  - Uses SceneSwitcher for scene transitions

**Methods:**
- `_ready()`: Initialize UI, load avatars, connect signals, load profile data
- `_load_available_avatars()`: Scan and load all avatar files
- `_populate_avatar_grid()`: Create avatar selection buttons
- `_load_profile_data()`: Load current profile into editor
- `_on_avatar_selected(path)`: Handle avatar button clicks
- `_on_display_name_changed()`: Clear errors on input
- `_on_bio_changed()`: Enforce character limit and update counter
- `_update_bio_char_count()`: Update character counter with color coding
- `_on_save_pressed()`: Validate and save all changes
- `_validate_inputs()`: Check all inputs meet requirements
- `_has_unsaved_changes()`: Detect if changes were made
- `_show_error()/success()`: Display validation messages
- `_navigate_back()`: Return to profile_view

### 3. Scripts/profile_editor.gd.uid
Godot UID reference file for the script.

**UID:** `uid://b4j7buwu6mq4o`

---

## Integration Changes

### Scripts/profile_view.gd
**Changed:** `_on_edit_pressed()` method

**Before:**
```gdscript
func _on_edit_pressed():
	"""Open profile editor."""
	# TODO: Implement when profile_editor.tscn is created (Step 8)
	print("Profile editor not yet implemented")
	# SceneSwitcher.push_scene("res://Scenes/profile_editor.tscn")
```

**After:**
```gdscript
func _on_edit_pressed():
	"""Open profile editor."""
	SceneSwitcher.switch_to("res://Scenes/profile_editor.tscn")
```

**Result:** Edit button now navigates to the profile editor screen.

---

## ProfileManager Integration

The profile editor uses the following ProfileManager APIs:

### Data Access
- `ProfileManager.current_profile`: Dictionary with all profile data
- `ProfileManager.current_profile_id`: Active profile ID
- Access to validation constants:
  - `MIN_USERNAME_LENGTH` (3)
  - `MAX_USERNAME_LENGTH` (20)
  - `MAX_BIO_LENGTH` (200)

### Data Updates
- `ProfileManager.update_profile_field(field, value)`: Update single field
- `ProfileManager.save_profile()`: Persist changes to disk

### Fields Updated
- `display_name`: Player's display name
- `bio`: Profile bio text
- `avatar`: Path to selected avatar SVG
- `profile_color_primary`: Hex color string
- `profile_color_accent`: Hex color string

---

## Available Avatars

The editor dynamically loads all avatars from `Assets/Profiles/Avatars/`:

1. bass.svg
2. crown.svg
3. default.svg
4. drum.svg
5. flame.svg
6. guitar.svg
7. lightning.svg
8. mic.svg
9. mystery.svg
10. star_bronze.svg
11. star_gold.svg
12. star_silver.svg

**Total:** 12 avatars

---

## Validation Rules

### Display Name
- **Minimum Length:** 3 characters
- **Maximum Length:** 20 characters
- **Allowed Characters:** Letters, numbers, spaces, underscores (_), hyphens (-)
- **Cannot be empty**

### Bio
- **Maximum Length:** 200 characters
- **Can be empty**
- **Real-time enforcement:** Input is truncated if exceeding limit
- **Character counter:** Color-coded based on usage
  - Green: < 80% (< 160 chars)
  - Yellow: 80-100% (160-200 chars)
  - Red: At limit (200 chars)

### Colors
- **Format:** Hex color codes (automatically handled by ColorPickerButton)
- **Default Primary:** #4CAF50 (Green)
- **Default Accent:** #F44336 (Red)

---

## User Flow

1. **Navigate to Profile View**
   - From main menu or profile selection
   
2. **Click "Edit Profile" Button**
   - Transitions to profile_editor scene
   
3. **Edit Profile Data**
   - Select new avatar from grid
   - Update display name
   - Update bio text
   - Adjust primary/accent colors
   
4. **Save or Cancel**
   - **Save Changes**: Validates inputs → Updates ProfileManager → Shows success → Returns to profile_view
   - **Cancel**: Returns to profile_view (changes discarded)

---

## Error Handling

### Validation Errors
- Display name too short/long
- Display name contains invalid characters
- Display name is empty
- Bio exceeds maximum length (enforced during typing)

**Display:** Red error message at bottom of editor

### Missing Profile
If no profile is loaded when editor opens:
- Shows error message
- Waits 2 seconds
- Automatically returns to profile_view

---

## Design Principles

### Single Responsibility
- **Scene (.tscn)**: Defines complete UI structure, layout, and styling
- **Script (.gd)**: Handles logic, data loading, validation, and saving only
- **No UI building in script**: All nodes created in scene file

### Component Reuse
- Uses existing ProfileManager for data operations
- Integrates with SceneSwitcher for navigation
- Follows same architecture as profile_select and profile_view

### User Experience
- Real-time validation feedback
- Character counter for bio
- Visual avatar preview
- Hover effects on avatar buttons
- Clear error messages
- Success confirmation before navigation

---

## Testing Checklist

### Basic Functionality
- [ ] Scene loads without errors
- [ ] All avatars display in grid (12 avatars)
- [ ] Current profile data loads correctly
- [ ] Avatar selection updates preview
- [ ] Display name input works
- [ ] Bio input works with character limit
- [ ] Color pickers work
- [ ] Save button validates and saves
- [ ] Cancel button returns to profile_view

### Validation Testing
- [ ] Cannot save with empty display name
- [ ] Cannot save with display name < 3 chars
- [ ] Cannot save with display name > 20 chars
- [ ] Cannot save with invalid characters in display name
- [ ] Bio is limited to 200 characters
- [ ] Character counter updates in real-time
- [ ] Character counter color changes correctly

### Data Persistence
- [ ] Changes are saved to ProfileManager
- [ ] Changes persist after returning to profile_view
- [ ] Changes persist after restarting game
- [ ] Avatar change reflects in profile_view
- [ ] Display name change reflects in profile_view
- [ ] Bio change reflects in profile_view
- [ ] Color changes are saved (when used)

### Navigation
- [ ] Edit button in profile_view opens editor
- [ ] Cancel button returns to profile_view
- [ ] Save button returns to profile_view after saving
- [ ] No errors when navigating between scenes

### Edge Cases
- [ ] Handles missing avatar files gracefully
- [ ] Handles empty bio correctly
- [ ] Handles special characters in bio
- [ ] Prevents duplicate saves
- [ ] Handles rapid button clicks

---

## Future Enhancements

### Potential Additions
1. **Unsaved Changes Dialog**: Warn user when clicking Cancel with unsaved changes
2. **Theme Preview**: Show how colors look in real-time on profile card
3. **Avatar Upload**: Allow custom avatar uploads
4. **More Customization**: Title selection, badges, profile borders
5. **Undo/Redo**: Allow reverting changes before saving
6. **Preview Mode**: See changes before saving
7. **Profile Stats**: Display profile stats in editor
8. **Social Features**: Add social media links, friend codes

---

## CRUD Operations Status

### Profile System CRUD Operations
✅ **Create** - Profile creation in profile_select screen  
✅ **Read** - Profile viewing in profile_view screen  
✅ **Update** - Profile editing in profile_editor screen (NEW)  
✅ **Delete** - Profile deletion in profile_select screen  

**Status:** Profile CRUD operations are now **COMPLETE**!

---

## Next Steps

### Immediate
1. Test profile editor in-game
2. Fix any bugs discovered during testing
3. Add unsaved changes confirmation dialog

### High Priority
**Score History Integration (Step 19)** - CRITICAL
- Migrate ScoreHistoryManager to profile-specific storage
- Change from `user://score_history.cfg` to `user://profiles/[profile_id]/scores.cfg`
- Update song_select.gd to load current profile's scores
- Required for true multi-profile support

### Nice to Have
- Profile export/import
- Profile comparison view
- Activity feed
- Social features
- Advanced customization options

---

## Summary

The Profile Editor successfully implements the Update operation for the profile system, completing all CRUD operations. It follows the single responsibility principle established in earlier refactoring work, with the scene handling UI and the script handling logic only.

**Key Features:**
- ✅ Avatar selection from 12 available avatars
- ✅ Display name editing with validation
- ✅ Bio editing with character limit
- ✅ Profile color customization
- ✅ Real-time validation feedback
- ✅ Integration with ProfileManager
- ✅ Clean navigation flow

**Code Quality:**
- ✅ No compilation errors
- ✅ Follows project architecture
- ✅ Comprehensive validation
- ✅ Good error handling
- ✅ Clean, maintainable code
- ✅ Proper signal connections

**Result:** Players can now fully manage their profiles with Create, Read, Update, and Delete operations!
