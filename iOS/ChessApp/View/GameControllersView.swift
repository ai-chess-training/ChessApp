//
//  GameControllersView.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import SwiftUI

struct GameControlsView: View {
    @Bindable var gameState: ChessGameState

    // MARK: - Haptic Feedback State

    @State private var resetTrigger = false
    @State private var undoTrigger = false
    @State private var resignTrigger = false
    
    var body: some View {
        VStack {
            // Game Mode Selection
            if FeatureFlags.hasMultiplePlayMode {
                GameModeSelectionView(gameState: gameState)
            }

            GameActionButtonsView(
                gameState: gameState,
                resetTrigger: $resetTrigger,
                undoTrigger: $undoTrigger,
                resignTrigger: $resignTrigger
            )
            
            // Move History (Debug Mode Only)
            if gameState.isDebugMode && !gameState.moveHistory.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Move History (Debug)", bundle: .main, comment: "Title for move history section in debug mode")
                        .font(.caption)
                        .foregroundColor(.orange)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(gameState.moveHistory, id: \.self) { move in
                                Text(move)
                                    .font(.caption)
                                    .background(Color(.systemGray6))
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 30)
                }
            }
            
            // Captured Pieces
            if !gameState.capturedPieces.isEmpty {
                VStack(alignment: .leading) {
                    Text("Captured Pieces", bundle: .main, comment: "Title for captured pieces section")
                        .font(.headline)
                    
                    ForEach([ChessColor.white, ChessColor.black], id: \.self) { color in
                        CapturedPiecesRow(
                            color: color, 
                            pieces: gameState.capturedPieces.filter { $0.color == color }
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
        
        // Chess Coach Feedback
        CoachingFeedbackView(gameState: gameState)
    }
}

// MARK: - Captured Pieces Row Component
struct CapturedPiecesRow: View {
    let color: ChessColor
    let pieces: [ChessPiece]
    
    var body: some View {
        if !pieces.isEmpty {
            HStack(alignment: .center, spacing: 8) {
                Text("\(color.displayName):")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(width: 60, alignment: .leading)
                
                ForEach(pieces.indices, id: \.self) { index in
                    if let piece = pieces[safe: index] {
                        Text(piece.type.symbol(for: piece.color))
                            .font(.system(size: 20, weight: .regular, design: .default))
                            .foregroundColor(.primary)
                            .frame(width: 24, height: 24)
                            .multilineTextAlignment(.center)
                    }
                }
                
                Spacer()
            }
        }
    }
}

// MARK: - Game Action Buttons Component
struct GameActionButtonsView: View {
    @Bindable var gameState: ChessGameState
    @Binding var resetTrigger: Bool
    @Binding var undoTrigger: Bool
    @Binding var resignTrigger: Bool


    var body: some View {
        HStack(spacing: 20) {
            Button(String(localized: "Reset", comment: "Reset game button text")) {
                resetTrigger.toggle()
                gameState.resetGame()
            }
            .buttonStyle(.borderedProminent)
            .sensoryFeedback(.impact(weight: .light), trigger: resetTrigger)

            Button(String(localized: "Resign", comment: "Resign game button text")) {
                resignTrigger.toggle()
                gameState.gameStatus = .checkmate(winner: gameState.currentPlayer == .white ? .black : .white)
            }
            .buttonStyle(.bordered)
            .foregroundColor(.red)
            .sensoryFeedback(.impact(weight: .heavy), trigger: resignTrigger)
        }
    }
}

// MARK: - Game Mode Selection Component

struct GameModeSelectionView: View {
    @Bindable var gameState: ChessGameState
    @State private var showingModeChangeAlert = false
    @State private var pendingGameMode: GameMode?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Game Mode")
                .font(.headline)
                .fontWeight(.semibold)

            Picker("Game Mode", selection: $gameState.gameMode) {
                ForEach(GameMode.allCases, id: \.self) { mode in
                    Text(mode.displayName)
                        .tag(mode)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .onChange(of: gameState.gameMode) { oldMode, newMode in
                handleGameModeChange(from: oldMode, to: newMode)
            }

            // Current mode indicator
            HStack {
                Image(systemName: gameState.gameMode == .humanVsMachine ? "cpu" : "person.2")
                    .foregroundColor(gameState.gameMode == .humanVsMachine ? .orange : .blue)
                Text(gameState.gameMode.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if gameState.gameMode == .humanVsMachine {
                    Text("Skill: \(gameState.skillLevel.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert(alertTitle, isPresented: $showingModeChangeAlert) {
            Button("Cancel", role: .cancel) {
                // Revert to previous mode
                if let oldMode = pendingGameMode {
                    gameState.gameMode = oldMode == .humanVsMachine ? .humanVsHuman : .humanVsMachine
                }
                pendingGameMode = nil
            }
            Button("Reset & Switch", role: .destructive) {
                confirmModeChange()
            }
        } message: {
            Text(alertMessage)
        }
    }

    private func handleGameModeChange(from oldMode: GameMode, to newMode: GameMode) {
        // Check if switching modes with game in progress
        if oldMode != newMode && gameState.moveCount > 0 {
            Logger.debug("Switching game modes with game in progress - showing warning", category: Logger.ui)
            pendingGameMode = oldMode
            showingModeChangeAlert = true
            return
        }

        // Normal mode change (no game in progress)
        gameState.updateGameMode(newMode)
    }

    private func confirmModeChange() {
        Logger.debug("User confirmed mode change - resetting game and switching mode", category: Logger.ui)

        // Reset the game first
        gameState.resetGame()

        // Then update the mode to the intended new mode
        let targetMode: GameMode = pendingGameMode == .humanVsHuman ? .humanVsMachine : .humanVsHuman
        gameState.updateGameMode(targetMode)

        pendingGameMode = nil
    }

    // MARK: - Alert Content

    private var alertTitle: String {
        guard let oldMode = pendingGameMode else { return "Switch Game Mode?" }
        let newMode: GameMode = oldMode == .humanVsHuman ? .humanVsMachine : .humanVsHuman
        return "Switch to \(newMode.displayName)?"
    }

    private var alertMessage: String {
        guard let oldMode = pendingGameMode else { return "This will reset the current game." }

        if oldMode == .humanVsHuman {
            return "Switching to Human vs Machine mode requires resetting the game because the current moves are not synced with the AI server. This will start a fresh game against the computer."
        } else {
            return "Switching to Human vs Human mode will reset the current game against the computer. This will start a fresh game for two human players."
        }
    }

}
