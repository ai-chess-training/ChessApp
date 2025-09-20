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
        VStack(spacing: 15) {
            // Chess Coach Feedback
            CoachingFeedbackView(gameState: gameState)

            HStack(spacing: 20) {
                Button(String(localized: "Reset", comment: "Reset game button text")) {
                    resetTrigger.toggle()
                    gameState.resetGame()
                }
                .buttonStyle(.borderedProminent)
                .sensoryFeedback(.impact(weight: .light), trigger: resetTrigger)

                Button(String(localized: "Undo", comment: "Undo move button text")) {
                    undoTrigger.toggle()
                    let _ = gameState.undoLastMove()
                }
                .buttonStyle(.bordered)
                .disabled(!gameState.canUndo())
                .sensoryFeedback(.impact(weight: .medium), trigger: undoTrigger)

                Button(String(localized: "Resign", comment: "Resign game button text")) {
                    resignTrigger.toggle()
                    gameState.gameStatus = .checkmate(winner: gameState.currentPlayer == .white ? .black : .white)
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
                .sensoryFeedback(.impact(weight: .heavy), trigger: resignTrigger)
            }
            
            // Debug toggle (small and unobtrusive)
            HStack {
                Spacer()
                Button(action: {
                    gameState.isDebugMode.toggle()
                }) {
                    Text("Debug: \(gameState.isDebugMode ? String(localized: "ON") : String(localized: "OFF"))", bundle: .main, comment: "Debug mode toggle button text. %@ is ON or OFF")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
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
