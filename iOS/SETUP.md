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

### 3. Configure Xcode Environment Variables

This is the recommended way to provide API keys to the app on macOS.

1. Open `ChessApp.xcodeproj` in Xcode
2. Select **Product** menu > **Scheme** > **Edit Scheme**
3. Select **Run** on the left sidebar
4. Go to the **Arguments** tab
5. Under **Environment Variables** section, click the **+** button
6. Add your API credentials:
   - **Name:** `CHESS_COACH_API_KEY`
   - **Value:** (paste the key from your backend team)
7. Click **Close**

### 4. Build and Run

1. Press `Cmd+B` to build the project
2. Press `Cmd+R` to run the app

The app will now have access to the API key via environment variables.

## How API Keys Are Read

The app uses a **priority system** to find the Chess Coach API key:

1. **Explicitly passed** parameter (for testing)
2. **User setting** from app Settings view (UserDefaults)
3. **Environment variable** `CHESS_COACH_API_KEY` (from Xcode scheme)

This means:
- Users can override the API key in the app's Settings
- Default API key comes from Xcode scheme environment variables
- Good for local development and testing

## For Production Builds

When building for production:

1. Set `CHESS_COACH_API_KEY` in your Xcode build configuration
2. Or set in CI/CD pipeline (GitHub Actions, etc.)
3. Backend URL: `https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com`

## For CI/CD Integration (GitHub Actions, etc.)

Store your API key as a repository secret, then inject it during build:

```yaml
- name: Build Chess App
  env:
    CHESS_COACH_API_KEY: ${{ secrets.CHESS_COACH_API_KEY }}
  run: |
    xcodebuild build -scheme ChessApp
```

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

1. Check that `CHESS_COACH_API_KEY` is set in Xcode scheme
2. Verify the API key is correct and hasn't expired
3. Confirm backend is reachable
4. Use Settings > "Test Connection" in the app to verify

### "No API key found" errors

Make sure you've:
1. Set `CHESS_COACH_API_KEY` in Xcode scheme (Product > Scheme > Edit Scheme > Arguments)
2. The value is not empty
3. Restarted Xcode or the app after adding it

### App shows nil API key in logs

1. Check Xcode scheme settings
2. Make sure you clicked **Close** after adding the environment variable
3. Rebuild the app (Cmd+B)

## For Teammates

When cloning this repo, they should:

1. Clone the repository
2. Ask you for the `CHESS_COACH_API_KEY`
3. Open `ChessApp.xcodeproj`
4. Set the API key in Xcode scheme (Product > Scheme > Edit Scheme > Arguments)
5. Build and run

No complex setup scripts or file generation needed!

## How Environment Variables Work

The app reads environment variables using:

```swift
ProcessInfo.processInfo.environment["CHESS_COACH_API_KEY"]
```

On macOS, the easiest way to provide environment variables to Xcode apps is via the Xcode scheme settings. This is consistent with how the Mixpanel analytics tokens are also configured.

Environment variables set in Xcode scheme are available to the running process via `ProcessInfo.processInfo.environment`.
