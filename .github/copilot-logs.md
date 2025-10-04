# Godot Rhythm Game

## Description
This is a rhythm game project developed using the Godot engine. The game plays music tracks and requires players to hit notes in time with the music. Notes are spawned based on the song's beat and player's input. The game features multiple songs, difficulties, and customizable controls.

## Features
- Multiple song support: Add your own songs by placing them in the `Assets/Tracks` directory.
- Difficulty levels: Each song can have multiple difficulty levels defined in separate files.
- Customizable controls: Remap the note keys and other controls in the settings menu.
- Timing adjustments: Fine-tune the note timing to your preference.
- Audio and visual feedback: Notes provide feedback when hit or missed, and the game tracks your score and combo.

## Installation
1. Clone the repository or download the project files.
2. Open the project in Godot 4.
3. Ensure all dependencies are installed (Godot should prompt you to install any missing ones).
4. Configure the project settings as needed, such as window size and input mappings.
5. Add your own songs to the `Assets/Tracks` directory, following the provided examples.

## How to Play
- Use the `D`, `F`, `J`, `K`, `L`, and `;` keys to hit the notes as they reach the hit zone.
- The game will display `Perfect`, `Great`, `Good`, or `Miss` based on your timing.
- Try to achieve the highest score and combo by hitting the notes accurately.
- Use the settings menu to adjust the note speed, volume, and controls to your liking.

## Adding Songs
To add your own songs to the game:
1. Place the song's audio file (e.g., `song.ogg`) in the `Assets/Tracks/YourSongFolder` directory.
2. Create a `.chart` file in the same folder to define the notes and timing.
3. Optionally, create a `song.ini` file for additional metadata like artist and title.
4. Restart the game or reload the song select menu to see your new song.

## Notes
- Ensure your audio files are in a supported format (OGG, WAV).
- Use the provided example songs and charts as a reference for creating your own.
- For best results, follow the recommended song and chart structure.

## Troubleshooting
- If the game crashes or behaves unexpectedly, check the Godot console for error messages.
- Common issues include missing audio files, incorrect file paths, and syntax errors in chart files.
- Ensure all resources are correctly placed and named according to the project structure.

## Contributing
Contributions are welcome! If you have suggestions or improvements, feel free to submit a pull request or open an issue.

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments
- Thanks to the Godot community for their support and resources.
- Inspired by rhythm games like Elite Beat Agents, Ouendan, and Dance Dance Revolution.

Enjoy the game and have fun creating your own levels!
