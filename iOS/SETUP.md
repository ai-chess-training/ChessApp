# Setup Guide

This guide explains how to set up the Chess App project for development.

## Prerequisites

- Xcode 15.0 or later
- macOS 13.0 or later
- Git

## Initial Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd ChessApp/iOS
```

### 2. Get API Credentials

Ask your backend team for:
- `CHESS_COACH_API_KEY` - Production API key for Chess Coach backend

### 3. Configure Environment Variables (.env file - Recommended)

The easiest way to provide API keys for development and testing.

1. Create a `.env` file in the `iOS/` directory:
   ```bash
   cp .env.example .env
   ```

2. Edit `.env` and add your API key:
   ```
   CHESS_COACH_API_KEY=your_actual_key_here
   ```

3. **Important:** The `.env` file is ignored by git (see `.gitignore`), so your secrets are safe

4. **Add to Xcode Build Phase**: Add the `.env` file to Xcode's **Copy Bundle Resources** build phase so it gets bundled with the app

5. **Build and Run**: The app will automatically load variables from the .env file

**Note:** The `.env` file must be in the iOS directory (same level as ChessApp folder) and added to the Copy Bundle Resources build phase.

### 4. Build and Run

1. Press `Cmd+B` to build the project
2. Press `Cmd+R` to run the app

The app will now have access to the API key via environment variables.

## How API Keys Are Read

The app uses a **priority system** to find the Chess Coach API key:

1. **Explicitly passed** parameter (for testing/programmatic use)
2. **User setting** from app Settings view (UserDefaults)
3. **.env file** - `CHESS_COACH_API_KEY`

This means:
- Users can override the API key in the app's Settings view
- Default API key comes from `.env` file
- Works for both development and release/TestFlight builds
- Settings are persistent and will be used even after app restarts

### Changing API Settings at Runtime

Users can change both the API backend URL and API key in the app:
1. Open **Settings**
2. Modify **API Base URL** (or use Production/Local Dev quick presets)
3. Modify **API Key** if needed
4. Click **Test Connection** to verify
5. Click **Save** to apply changes

The ChessCoachAPI instance will be automatically updated with the new settings.

## For Production Builds (Release/TestFlight)

When building for TestFlight or App Store release, create the `.env` file in your CI/CD pipeline:

```yaml
- name: Create .env file
  run: |
    echo "CHESS_COACH_API_KEY=${{ secrets.CHESS_COACH_API_KEY }}" > iOS/.env

- name: Build Chess App
  run: |
    xcodebuild build -scheme ChessApp
```

The same `.env` approach works for release builds with no code changes:
- Your CI/CD pipeline creates the `.env` file before building
- Xcode bundles it automatically
- App reads it via `DotEnv.shared.get()` (same as development)

**Notes:**
- Users can always override the API key in the app's Settings if needed
- Backend URL: `https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com`

## Important Notes

### Security

- **Never hardcode API keys** in Swift files
- **Use Xcode scheme** for development
- **Use CI/CD secrets** for production/automated builds
- **Users can override** API key in Settings for testing

### Development vs Production

- **Development**: Set API key in Xcode scheme (per developer)
- **Production**: Inject via CI/CD secrets at build time
- **Testing**: Users can set in app Settings UI

## Troubleshooting

### API calls fail with 401/403 Unauthorized

1. Check that `CHESS_COACH_API_KEY` is set in `.env` file or environment variables
2. Verify the API key is correct and hasn't expired
3. Confirm backend is reachable
4. Use Settings > "Test Connection" in the app to verify

### "No API key found" errors

Make sure you've:
1. Created `.env` file from `.env.example` (`cp .env.example .env`)
2. Added your actual API key to the `.env` file
3. The `.env` file is in the iOS directory (same level as ChessApp folder)
4. Added `.env` to Xcode's **Copy Bundle Resources** build phase
5. Restarted Xcode and rebuilt the app (`Cmd+B`)

### .env file not being loaded

1. Make sure the `.env` file is in the iOS directory (not in ChessApp subfolder)
2. Check that it's named exactly `.env` (no extension, no other characters)
3. Rebuild the app and the changes should take effect
4. Check Xcode's console output for any .env loading messages

### For Release/TestFlight builds

If the API key is missing in TestFlight builds:
1. The `.env` file is not included in release builds
2. Make sure you set the API key via environment variables in your CI/CD pipeline
3. Verify the environment variable is correctly set before building
4. Users can also set the API key manually in the app's Settings

## For Teammates

When cloning this repo, they should:

1. Clone the repository
2. Ask you for the `CHESS_COACH_API_KEY`
3. Create `.env` file: `cp .env.example .env`
4. Add the API key to `.env`
5. Add `.env` to Xcode's **Copy Bundle Resources** build phase
6. Build and run

No complex setup scripts needed!

## How Environment Variables Work

The app reads environment variables from the `.env` file using the `DotEnv` utility:

```swift
DotEnv.shared.get("CHESS_COACH_API_KEY")
```

The `.env` file is parsed at app startup and loaded into memory. This approach works for both development and release builds.
