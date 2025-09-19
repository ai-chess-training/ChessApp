//
//  ChessSquare.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import SwiftUI

struct ChessSquareView: View {
    let position: ChessPosition
    let piece: ChessPiece?
    let isSelected: Bool
    @Bindable var gameState: ChessGameState
    
    private var squareColor: Color {
        // Priority order: King in check (highest) > Available moves > Base color (lowest)

        // Highest priority: King in check
        if gameState.isKingInCheckAt(position: position) {
            return .red.opacity(0.6)
        }

        // Medium priority: Available moves
        if gameState.isSquareAvailable(position: position) {
            return .green.opacity(0.4)
        }

        // Default: Chess board pattern
        let isLightSquare = (position.row + position.col) % 2 == 0
        return isLightSquare ? .brown.opacity(0.05) : .brown.opacity(0.8)
    }
    
    var body: some View {
        Button(action: {
            // Don't handle taps during pawn promotion
            if !gameState.showingPawnPromotion {
                handleSquareTap()
            }
        }) {
            ZStack {
                Rectangle()
                    .fill(squareColor)
                    .overlay(
                        Rectangle()
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                    .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
                
                // Show dot for available moves
                if gameState.isSquareAvailable(position: position) && piece == nil {
                    Circle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: 12, height: 12)
                }
                
                if let piece = piece {
                    GeometryReader { geometry in
                        let squareSize = geometry.size.width //we know it is a square, only one is needed for width and height
                        let customFont = Font.system(size: squareSize * 0.7)
                        
                        Text(piece.type.symbol(for: piece.color))
                            .font(customFont)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func handleSquareTap() {
        if let selectedSquare = gameState.selectedSquare {
            if selectedSquare == position {
                // Deselect current square
                gameState.selectedSquare = nil
            } else {
                // Attempt to move piece with validation
                let moveSuccessful = gameState.attemptMove(from: selectedSquare, to: position)
                if !moveSuccessful {
                    // If move failed, deselect the piece
                    gameState.selectedSquare = nil
                }
            }
        } else {
            // Select square if it has a piece of current player
            if let piece = piece, piece.color == gameState.currentPlayer {
                gameState.selectSquare(position)
            }
        }
    }
}

#Preview {
    ChessSquareView(position: ChessPosition(row: 0, col: 0), piece: ChessGameState().board[0][0],
                    isSelected: false,
                    gameState: ChessGameState())
    .frame(width: 150, height: 150)
}
