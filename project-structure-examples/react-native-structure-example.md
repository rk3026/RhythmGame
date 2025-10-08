# React Native Mobile App Project Structure Example

## Recommended for: Cross-platform mobile apps (iOS & Android)

```
my-mobile-app/
├── README.md                          # Project overview
├── .context/                          # AI/developer guidance
│   ├── README.md
│   ├── project-context.md
│   ├── ai-coordination-strategy.md
│   └── development-tracking.md
├── .env.example                       # Environment template
├── .gitignore                         # Use gitignore-react-native.txt
├── package.json                       # Dependencies & scripts
├── app.json                           # Expo configuration (if using Expo)
├── babel.config.js                    # Babel configuration
├── metro.config.js                    # Metro bundler config
│
├── src/                              # Source code
│   ├── App.tsx or App.jsx           # Root app component
│   ├── navigation/                   # Navigation setup
│   │   ├── AppNavigator.tsx
│   │   ├── AuthNavigator.tsx
│   │   └── TabNavigator.tsx
│   │
│   ├── screens/                      # Screen components
│   │   ├── HomeScreen.tsx
│   │   ├── ProfileScreen.tsx
│   │   ├── LoginScreen.tsx
│   │   └── SettingsScreen.tsx
│   │
│   ├── components/                   # Reusable components
│   │   ├── Button.tsx
│   │   ├── Card.tsx
│   │   ├── Input.tsx
│   │   └── Header.tsx
│   │
│   ├── services/                     # API services
│   │   ├── api.ts
│   │   ├── authService.ts
│   │   └── dataService.ts
│   │
│   ├── hooks/                        # Custom React hooks
│   │   ├── useAuth.ts
│   │   └── useData.ts
│   │
│   ├── context/                      # React Context (state management)
│   │   ├── AuthContext.tsx
│   │   └── ThemeContext.tsx
│   │
│   ├── utils/                        # Helper functions
│   │   ├── validation.ts
│   │   └── formatting.ts
│   │
│   ├── constants/                    # App constants
│   │   ├── colors.ts
│   │   └── config.ts
│   │
│   ├── types/                        # TypeScript types
│   │   └── index.ts
│   │
│   └── assets/                       # Images, fonts, etc.
│       ├── images/
│       │   └── logo.png
│       └── fonts/
│           └── CustomFont.ttf
│
├── android/                          # Android native code
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/
│   └── gradle.properties
│
├── ios/                              # iOS native code
│   ├── MyApp/
│   │   └── Info.plist
│   ├── MyApp.xcodeproj/
│   └── Podfile
│
├── __tests__/                        # Test files
│   ├── components/
│   │   └── Button.test.tsx
│   └── screens/
│       └── HomeScreen.test.tsx
│
└── docs/                             # Additional documentation (optional)
    ├── architecture-diagrams/
    └── design-mockups/
```

## Navigation Patterns

### Stack Navigator Example
```typescript
// navigation/AppNavigator.tsx
import { createStackNavigator } from '@react-navigation/stack';

const Stack = createStackNavigator();

export function AppNavigator() {
  return (
    <Stack.Navigator>
      <Stack.Screen name="Home" component={HomeScreen} />
      <Stack.Screen name="Profile" component={ProfileScreen} />
    </Stack.Navigator>
  );
}
```

### Bottom Tab Navigator Example
```typescript
// navigation/TabNavigator.tsx
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';

const Tab = createBottomTabNavigator();

export function TabNavigator() {
  return (
    <Tab.Navigator>
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="Search" component={SearchScreen} />
      <Tab.Screen name="Profile" component={ProfileScreen} />
    </Tab.Navigator>
  );
}
```

## State Management Patterns

### React Context (Simple)
```typescript
// context/AuthContext.tsx
import React, { createContext, useState, useContext } from 'react';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  
  return (
    <AuthContext.Provider value={{ user, setUser }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
```

### Redux (Complex)
```
src/
├── store/
│   ├── index.ts                    # Store configuration
│   ├── slices/
│   │   ├── authSlice.ts
│   │   └── dataSlice.ts
│   └── hooks.ts                    # Typed hooks
```

## Platform-Specific Code

### Conditional Platform Rendering
```typescript
import { Platform } from 'react-native';

const styles = StyleSheet.create({
  container: {
    padding: Platform.OS === 'ios' ? 20 : 15,
  }
});
```

### Platform-Specific Files
```
components/
├── Button.tsx                      # Shared code
├── Button.ios.tsx                  # iOS-specific
└── Button.android.tsx              # Android-specific
```

## Installation & Setup

### Expo Project (Recommended for beginners)
```bash
# Install dependencies
npm install

# Start development server
npm start

# Run on iOS simulator
npm run ios

# Run on Android emulator
npm run android
```

### Bare React Native Project
```bash
# Install dependencies
npm install

# iOS setup (macOS only)
cd ios && pod install && cd ..

# Run on iOS
npm run ios

# Run on Android
npm run android
```

## Dependencies (package.json example)

```json
{
  "name": "my-mobile-app",
  "version": "1.0.0",
  "scripts": {
    "start": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "test": "jest"
  },
  "dependencies": {
    "react": "18.2.0",
    "react-native": "0.73.0",
    "@react-navigation/native": "^6.1.9",
    "@react-navigation/stack": "^6.3.20",
    "@react-navigation/bottom-tabs": "^6.5.11",
    "axios": "^1.6.0",
    "react-native-dotenv": "^3.4.9"
  },
  "devDependencies": {
    "@types/react": "^18.2.45",
    "@types/react-native": "^0.73.0",
    "typescript": "^5.3.3",
    "jest": "^29.7.0",
    "@testing-library/react-native": "^12.4.0"
  }
}
```

## Testing

### Component Testing
```typescript
// __tests__/components/Button.test.tsx
import { render, fireEvent } from '@testing-library/react-native';
import Button from '../../src/components/Button';

test('button press calls onPress', () => {
  const onPress = jest.fn();
  const { getByText } = render(<Button title="Press Me" onPress={onPress} />);
  
  fireEvent.press(getByText('Press Me'));
  expect(onPress).toHaveBeenCalled();
});
```

## Build & Deployment

### iOS Build
```bash
# Build for TestFlight/App Store
cd ios
xcodebuild -workspace MyApp.xcworkspace -scheme MyApp -configuration Release
```

### Android Build
```bash
# Build APK for testing
cd android
./gradlew assembleRelease

# Build AAB for Play Store
./gradlew bundleRelease
```

## Common React Native Libraries

- **Navigation**: @react-navigation/native, @react-navigation/stack
- **UI**: react-native-paper, react-native-elements
- **State**: redux, @reduxjs/toolkit, zustand
- **Forms**: formik, react-hook-form
- **API**: axios, @tanstack/react-query
- **Storage**: @react-native-async-storage/async-storage
- **Icons**: react-native-vector-icons
- **Animations**: react-native-reanimated
