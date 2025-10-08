# Unity Game Development Project Structure Example

## Recommended for: Unity 3D/2D games

```
my-unity-game/
├── README.md                          # Project overview
├── .context/                          # AI/developer guidance
│   ├── README.md
│   ├── project-context.md
│   ├── ai-coordination-strategy.md
│   └── development-tracking.md
├── .env.example                       # Environment template (if needed)
├── .gitignore                         # Use gitignore-unity.txt
│
├── Assets/                            # Unity assets folder
│   ├── Scenes/                        # Game scenes
│   │   ├── MainMenu.unity
│   │   ├── Level1.unity
│   │   └── GameOver.unity
│   │
│   ├── Scripts/                       # C# scripts
│   │   ├── Player/
│   │   │   ├── PlayerController.cs
│   │   │   ├── PlayerHealth.cs
│   │   │   └── PlayerInventory.cs
│   │   ├── Enemies/
│   │   │   ├── EnemyAI.cs
│   │   │   └── EnemySpawner.cs
│   │   ├── Managers/
│   │   │   ├── GameManager.cs
│   │   │   ├── UIManager.cs
│   │   │   └── AudioManager.cs
│   │   └── Utils/
│   │       └── HelperFunctions.cs
│   │
│   ├── Prefabs/                       # Reusable game objects
│   │   ├── Player.prefab
│   │   ├── Enemy.prefab
│   │   └── Collectible.prefab
│   │
│   ├── Materials/                     # Material assets
│   │   └── PlayerMaterial.mat
│   │
│   ├── Textures/                      # Texture files
│   │   └── PlayerTexture.png
│   │
│   ├── Audio/                         # Sound effects & music
│   │   ├── SFX/
│   │   │   ├── Jump.wav
│   │   │   └── Hit.wav
│   │   └── Music/
│   │       └── BackgroundMusic.mp3
│   │
│   ├── Sprites/                       # 2D sprites (for 2D games)
│   │   └── PlayerSprite.png
│   │
│   ├── Animations/                    # Animation files
│   │   ├── PlayerWalk.anim
│   │   └── PlayerJump.anim
│   │
│   ├── Fonts/                         # Font files
│   │   └── GameFont.ttf
│   │
│   ├── UI/                            # UI elements
│   │   └── MainMenuCanvas.prefab
│   │
│   └── Resources/                     # Dynamically loaded assets
│       └── Config.json
│
├── Packages/                          # Unity package manager
│   └── manifest.json                  # Package dependencies
│
├── ProjectSettings/                   # Unity project settings
│   ├── ProjectSettings.asset
│   ├── TagManager.asset
│   └── InputManager.asset
│
├── UserSettings/                      # User-specific settings (gitignored)
│
├── docs/                              # Additional documentation (optional)
│   ├── game-design-document.md
│   ├── architecture-diagrams/
│   └── level-design-notes.md
│
└── Tests/                             # Unit tests (Unity Test Framework)
    ├── PlayMode/
    │   └── PlayerTests.cs
    └── EditMode/
        └── GameManagerTests.cs
```

## Unity-Specific Best Practices

### Script Organization Patterns

#### Singleton Manager Pattern
```csharp
// GameManager.cs - Central game controller
public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }
    
    void Awake()
    {
        if (Instance == null)
        {
            Instance = this;
            DontDestroyOnLoad(gameObject);
        }
        else
        {
            Destroy(gameObject);
        }
    }
}
```

#### Component-Based Architecture
```
Assets/Scripts/
├── Core/                          # Core game systems
│   ├── GameManager.cs
│   └── EventManager.cs
├── Gameplay/                      # Gameplay mechanics
│   ├── PlayerController.cs
│   └── CombatSystem.cs
├── UI/                            # UI controllers
│   ├── MenuController.cs
│   └── HUDController.cs
└── Data/                          # ScriptableObjects & data
    ├── WeaponData.cs
    └── LevelData.cs
```

### Asset Organization Tips

1. **Prefabs**: Store reusable game objects
2. **ScriptableObjects**: Store data configurations
3. **Resources**: Only for dynamically loaded assets (use sparingly)
4. **StreamingAssets**: For external files that need to be accessed at runtime

### Common Unity Packages

Add to `Packages/manifest.json`:
```json
{
  "dependencies": {
    "com.unity.textmeshpro": "3.0.6",
    "com.unity.cinemachine": "2.9.7",
    "com.unity.inputsystem": "1.7.0",
    "com.unity.test-framework": "1.1.33"
  }
}
```

## Getting Started

### Opening the Project
1. Open Unity Hub
2. Click "Add" and select this project folder
3. Open with Unity version specified in `ProjectSettings/ProjectVersion.txt`

### Building the Game
```
File → Build Settings
- Select target platform (PC, Mac, WebGL, etc.)
- Click "Build" or "Build and Run"
```

### Running Tests
```
Window → General → Test Runner
- Run PlayMode tests for gameplay
- Run EditMode tests for editor functionality
```

## Common Unity Folder Purposes

- **Scenes/**: Contains all game scenes (.unity files)
- **Scripts/**: All C# code for game logic
- **Prefabs/**: Reusable game object templates
- **Materials/**: Visual material properties
- **Textures/**: Image files for 3D models
- **Sprites/**: 2D image assets
- **Audio/**: Sound effects and music
- **Animations/**: Animation clips and controllers
- **Fonts/**: Text rendering fonts
- **Resources/**: Runtime-loaded assets (use sparingly)
- **StreamingAssets/**: External files accessible at runtime
- **Editor/**: Editor-only scripts (not included in builds)
