# Chess App - iOS

A SwiftUI-based Chess application for iOS/macOS with AI coaching, game analysis, and multiplayer support.

## Quick Start

### First Time Setup

1. **Clone the repo:**
   ```bash
   git clone <repository-url>
   cd ChessApp/iOS
   ```

2. **Set up API credentials in Xcode:**
   - Open `ChessApp.xcodeproj`
   - Select **Product** > **Scheme** > **Edit Scheme**
   - Go to **Run** > **Arguments** > **Environment Variables**
   - Click **+** and add:
     - **Name:** `CHESS_COACH_API_KEY`
     - **Value:** (get from backend team)
   - Click **Close**

3. **Build and run:**
   - Press `Cmd+B` to build
   - Press `Cmd+R` to run

For detailed setup instructions and troubleshooting, see [SETUP.md](SETUP.md)

## Project Overview

This is a SwiftUI-based Chess application for iOS/macOS. The app features:
- Visual chess board with piece movement and full chess rules
- AI coaching with move analysis
- Game state management and move history
- Google Sign-In authentication with guest mode support
- Production backend integration

## Build and Development Commands

### Building the Project
- Open `ChessApp.xcodeproj` in Xcode to build and run the application
- Built with Xcode 15+ and Swift 6.0
- Use Cmd+B to build, Cmd+R to run
- Uses Swift Package Manager for GoogleSignIn dependency

### Testing
- Use Cmd+U in Xcode to run tests (when test files are added)
- Currently no test files exist in the project

## Architecture Overview

### Core Components

**GameManager.swift** (`ChessApp/Model/GameManager.swift`)
- Contains the main game logic with `ChessGameState` class
- Uses `@Observable` macro for SwiftUI state management
- Manages board state, piece positions, game status, and move history
- Key classes: `ChessGameState`, `ChessPosition`, `ChessPiece`, `PieceType`, `ChessColor`, `GameStatus`

**AuthenticationManager.swift** (`ChessApp/Model/AuthenticationManager.swift`)
- Handles Google Sign-In integration and guest mode
- Uses `@MainActor @Observable` for SwiftUI state management
- Implements Swift 6 concurrency patterns with Sendable types
- Key types: `AppUser` (Sendable wrapper for user data), `AuthenticationManager`

**View Layer** (`ChessApp/View/`)
- **ContentView.swift**: Main app container with navigation
- **LoginView.swift**: Authentication screen with Google Sign-In and guest mode
- **SignInSection.swift**: Refactored sign-in UI component
- **ChessBoardView.swift**: Renders the 8x8 chess board grid
- **ChessSquareView.swift**: Individual square component with piece display and tap handling
- **GameStatusView.swift**: Displays current player, game status (checkmate, draw, etc.)
- **GameControlsView.swift**: New game, undo, resign buttons and captured pieces display

### State Management
- Uses SwiftUI's `@Observable` and `@Bindable` for reactive state updates
- Single source of truth in `ChessGameState` class for game state
- `AuthenticationManager` manages user authentication state
- State flows down through view hierarchy via binding
- Swift 6 concurrency with `@MainActor` isolation for UI-related classes

### Current Implementation Status
- Basic board setup and piece display working
- Placeholder move logic (pieces can be moved but no chess rules enforced)
- UI for game controls exists but undo functionality not implemented
- No chess rule validation (legal moves, check detection, etc.)

## Code Patterns

### SwiftUI Conventions
- Uses `@Bindable` for passing mutable state down view hierarchy
- Views are broken into focused, single-responsibility components
- Preview providers included for SwiftUI canvas
- Follows Swift 6 concurrency patterns with proper actor isolation
- Custom `Sendable` types for safe data transfer across actor boundaries

### File Organization
- Model layer in `Model/` directory
- View components in `View/` directory  
- Main app entry point at root level

## Development Notes

### Authentication
- Google Sign-In integration fully implemented with proper Swift 6 concurrency
- Guest mode available for users who don't want to sign in
- User data managed through `AppUser` Sendable struct

### Chess Game
- The chess game currently has basic UI but lacks full chess rule implementation
- Move validation, check/checkmate detection, and proper game logic need to be implemented
- The project structure supports easy addition of AI opponent logic in the future

### Swift 6 Migration
- Project upgraded to Swift 6.0 for enhanced concurrency safety
- All concurrency warnings resolved using modern async/await patterns
- Proper actor isolation with `@MainActor` for UI components
