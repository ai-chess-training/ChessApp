# Privacy Policy

## Overview
Chess Mentor is committed to protecting your privacy. This Privacy Policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application.

## 1. Information We Collect

### User Authentication
- **Authentication Method**: We support Sign in with Apple Sign-In for user authentication
- **Data Collected**: Email address, user name, and authentication credentials (managed by Apple)
- **Guest Mode**: You can use the app as a guest without providing any personal information

### Gameplay Data
- **Move History**: We store your chess moves and game history to provide game analysis and coaching feedback
- **Game Statistics**: Game results, skill level selections, and coaching preferences
- **User Preferences**: Game mode preferences, skill level settings, and coaching defaults

### API Communication
- **Chess Coach API**: When coaching features are enabled, game data is sent to our Chess Coach API backend for analysis
- **Backend Server**: Configured via settings (production or local development server)

## 2. How We Use Your Information

We use collected information to:
- Provide chess coaching and analysis feedback
- Display your game history and statistics
- Improve game experience and features
- Personalize coaching recommendations based on skill level
- Enable move analysis and suggestions

## 3. Third-Party Services

### Authentication Providers
- **Apple**: For "Sign in with Apple" authentication

Apple handle their own privacy policies for authentication data.

### Chess Coach API
- Game data is sent to our backend server for analysis
- The server URL is configurable in Settings (can be local development or production)
- Only data necessary for move analysis is transmitted

## 4. Data Storage

- **Local Storage**: Game history and preferences are stored locally on your device using UserDefaults
- **App Settings**: Theme preferences, skill level, and coaching settings are saved locally
- **No Cloud Sync**: By default, your data is not synced to cloud services unless you explicitly configure a backend server

## 5. Data Security

- Authentication credentials are handled by Apple and Google's secure systems
- API communication should use secure connections (HTTPS recommended)
- Local data is stored in the app's secure sandbox

## 6. Your Privacy Rights

### Guest Users
- Use the app completely anonymously
- No personal information is collected or stored
- Game data is stored only locally on your device

### Signed-In Users
- You can view and manage your authentication in the app settings
- You can sign out at any time to stop using authenticated features
- Contact us for data deletion requests (see contact information below)

## 7. Data Retention

- Game history is retained locally until you manually delete it or uninstall the app
- Authentication data is managed by Apple/Google according to their policies
- API data transmission logs may be retained on the backend server according to server policy

## 8. Children's Privacy

Chess Mentor does not knowingly collect information from children under 13. If we become aware that a child under 13 has provided us with personal information, we will take steps to delete such information.

## 9. Changes to This Policy

We may update this Privacy Policy from time to time. We will notify users of significant changes through app updates or notifications.

## 10. Contact Us

If you have questions about this Privacy Policy or our privacy practices, please contact:

- **Email**: cynthiazw@gmail.com
- **Project Repository**: https://github.com/ai-chess-training/ChessApp/tree/main/iOS

## 11. Developer Configuration

### API Configuration
Users can configure the Chess Coach API endpoint in Settings:
- Production: `https://ai-chess-coach-backend-ed3d4b2641bc.herokuapp.com`
- Local Development: `http://localhost:8000`

This configuration affects what server receives your game data for analysis.

### Settings Management
All user preferences and settings are managed through the app's Settings screen and stored locally.

---

**Last Updated**: November 2025

**Version**: 1.0
