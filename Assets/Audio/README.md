# Audio Assets Directory Structure

This directory contains all audio files for the rhythm game.

## Structure

- **SFX/** - Sound effects
  - **Hits/** - Note hit sounds (perfect, great, good, bad)
  - **Misses/** - Note miss sounds
  - **Combo/** - Combo milestone sounds (50, 100, full combo)
  - **Ambient/** - Countdown, pause, and ambient effects
- **UI/** - User interface sounds (click, hover, back, select)
- **Music/** - Background music tracks (currently in Assets/Tracks/)

## File Format

All sound effects should be in **OGG Vorbis** format for optimal compression and compatibility.
- Sample rate: 44.1 kHz or 48 kHz recommended
- Bit depth: 16-bit or higher
- Keep files small (<100KB each for short effects)

## Adding New Sounds

1. Place the audio file in the appropriate subfolder
2. Update `Scripts/SoundEffectManager.gd` SOUND_LIBRARY dictionary
3. Ensure the file path matches the dictionary entry
4. Test in-game with `SoundEffectManager.play_sfx("sound_name")`

## Placeholder Files

Currently using placeholder entries. Replace with actual sound files:
- perfect_01.ogg, perfect_02.ogg (variations)
- great_01.ogg
- good_01.ogg
- bad_01.ogg
- miss_01.ogg
- combo_50.ogg, combo_100.ogg, combo_fc.ogg
- countdown_tick.ogg, countdown_go.ogg
- pause_in.ogg, pause_out.ogg
- ui_click.ogg, ui_hover.ogg, ui_back.ogg, ui_select.ogg

## Volume Guidelines

- Hit sounds: -6dB to 0dB (prominent)
- Miss sounds: -3dB to 0dB (attention-grabbing)
- Combo sounds: -10dB to -6dB (celebratory but not overwhelming)
- UI sounds: -12dB to -8dB (subtle)
- Ambient: -15dB to -10dB (background)

## Sources for Free Sound Effects

- Freesound.org (CC0 and CC-BY licensed)
- OpenGameArt.org
- Kenney.nl (public domain game assets)
- SFXR/Bfxr (generate your own retro sounds)
