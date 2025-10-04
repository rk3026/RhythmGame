# Godot Rhythm Game

## Overview
I want to create a 3D style rhythm game using the Godot 4 game engine.

## Similar Games
- Guitar Hero
- Fortnite Festival
- Bang Dream! Girls Band Party (Mobile)
- Clone Hero

## Platforms
- Desktop and Mobile (use Godot to build versions for each platform)

## Features

### Main Menu
- Access to song library and settings

### Song Library
- Browse and select songs

### Gameplay
- When beginning a song, countdown 3, 2, 1 to give time to prepare
- Notes spawn in different lanes; player presses key/touches at correct time to hit the note
- Hit Judging: Miss, Good, Great, Perfect
- Pause during playing the song (if solo)
- Unpause has countdown as well
- Results screen after finishing song

### Customizable Settings
- Note speed, sizing, colors of the boards, etc.

### Chart Creation
#### Manual Chart Creation
- Users can create charts for a song
- A song will have a main audio file
- Multiple charts per song based on difficulty
- In-game system to create a chart for the song, with playback for testing, etc.

#### Automatic Chart Creation
- Possibly use AI detection/libraries to take a song audio and create a chart for it

### Account System
- Keeps track of stats (songs played, high scores, etc.)
- Customize features of an account (icons, bio, etc.)

## Design Considerations
- Note Charts should be .chart files (the format that Clone Hero uses, see [text](<Core Infrastructure.md>))
- Note hit detection should be timing-based (NOT hitbox-based) for better performance
- Note runway is 3D, moving
- Notes come toward the screen
