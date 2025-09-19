//
//  ChessSquare.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import SwiftUI

struct ChessSquareView: View {

    // MARK: - Constants

    private struct SquareConstants {
        static let availableMoveDotSize: CGFloat = 12
        static let selectionBorderWidth: CGFloat = 3
        static let pieceFontScale: CGFloat = 0.7
        static let shadowRadius: CGFloat = 1
        static let shadowOpacity: Double = 0.3
        static let squareShadowRadius: CGFloat = 1
        static let squareShadowOpacity: Double = 0.1
    }

    // MARK: - Properties

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
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: SquareConstants.selectionBorderWidth)
                    )
                    .shadow(color: Color.black.opacity(SquareConstants.squareShadowOpacity), radius: SquareConstants.squareShadowRadius, x: 0, y: 1)
                
                // Show dot for available moves
                if gameState.isSquareAvailable(position: position) && piece == nil {
                    Circle()
                        .fill(Color.green.opacity(0.6))
                        .frame(width: SquareConstants.availableMoveDotSize, height: SquareConstants.availableMoveDotSize)
                }
                
                if let piece = piece {
                    GeometryReader { geometry in
                        let squareSize = geometry.size.width //we know it is a square, only one is needed for width and height
                        let customFont = Font.system(size: squareSize * SquareConstants.pieceFontScale)
                        
                        Text(piece.type.symbol(for: piece.color))
                            .font(customFont)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .shadow(color: .black.opacity(SquareConstants.shadowOpacity), radius: SquareConstants.shadowRadius, x: 0, y: 1)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func handleSquareTap() {
        if let selectedSquare = gameState.selectedSquare {
            handleTapWithSelection(selectedSquare)
        } else {
            handleTapWithoutSelection()
        }
    }

    private func handleTapWithSelection(_ selectedSquare: ChessPosition) {
        if selectedSquare == position {
            deselectSquare()
        } else {
            attemptMoveOrDeselect(from: selectedSquare)
        }
    }

    private func handleTapWithoutSelection() {
        if let piece = piece, piece.color == gameState.currentPlayer {
            selectSquare()
        }
    }

    private func deselectSquare() {
        gameState.selectedSquare = nil
    }

    private func selectSquare() {
        gameState.selectSquare(position)
    }

    private func attemptMoveOrDeselect(from selectedSquare: ChessPosition) {
        let moveSuccessful = gameState.attemptMove(from: selectedSquare, to: position)
        if !moveSuccessful {
            deselectSquare()
        }
    }
}

#Preview {
    ChessSquareView(position: ChessPosition(row: 0, col: 0), piece: ChessGameState().board[0][0],
                    isSelected: false,
                    gameState: ChessGameState())
    .frame(width: 150, height: 150)
}
