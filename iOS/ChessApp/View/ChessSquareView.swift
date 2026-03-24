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
        static let pieceFontScale: CGFloat = 0.8
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
    let pieceAnimationNamespace: Namespace.ID
    @Environment(AppTheme.self) private var theme

    // MARK: - Haptic Feedback State

    @State private var pieceSelectedTrigger = false
    @State private var moveSuccessTrigger = false
    @State private var moveFailTrigger = false
    
    // MARK: - Engine Move Highlight
    
    @State private var engineMoveGlow: CGFloat = 0.8
    
    private var isEngineMoveSquare: Bool {
        position == gameState.engineMoveFrom || position == gameState.engineMoveTo
    }
    
    private var squareColor: Color {
        // Priority order: King in check (highest) > Engine move > Available moves > Base color (lowest)

        // Highest priority: King in check
        if gameState.isKingInCheckAt(position: position) {
            return .red.opacity(0.6)
        }
        
        // High priority: Engine move highlight
        if isEngineMoveSquare {
            let isOrigin = position == gameState.engineMoveFrom
            return .orange.opacity(isOrigin ? 0.4 : 0.6)
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
            // Don't handle taps during pawn promotion or when no backend session is established
            if !gameState.showingPawnPromotion && gameState.chessCoachAPI.isConnected {
                handleSquareTap()
            }
        }) {
            ZStack {
                Rectangle()
                    .fill(squareColor)
                    .overlay(
                        Rectangle()
                            .stroke(isSelected ? theme.primaryColor : Color.clear, lineWidth: SquareConstants.selectionBorderWidth)
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
                        let squareSize = geometry.size.width
                        let customFont = Font.system(size: squareSize * SquareConstants.pieceFontScale)
                        let isEngineDestination = position == gameState.engineMoveTo

                        Text(piece.type.symbol(for: piece.color))
                            .font(customFont)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .shadow(color: .black.opacity(SquareConstants.shadowOpacity), radius: SquareConstants.shadowRadius, x: 0, y: 1)
                            .scaleEffect(isEngineDestination ? 1.0 + (engineMoveGlow * 0.15) : 1.0)
                            .matchedGeometryEffect(id: "\(piece.type.rawValue)-\(piece.color.rawValue)-\(position.row)-\(position.col)", in: pieceAnimationNamespace)
                    }
                }
                
                // Pulsing border on engine move destination
                if position == gameState.engineMoveTo {
                    RoundedRectangle(cornerRadius: 2)
                        .stroke(Color.orange.opacity(engineMoveGlow), lineWidth: 3)
                        .padding(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .sensoryFeedback(.impact(weight: .light), trigger: pieceSelectedTrigger)
        .sensoryFeedback(.impact(weight: .medium), trigger: moveSuccessTrigger)
        .sensoryFeedback(.error, trigger: moveFailTrigger)
        .onChange(of: gameState.engineMoveTo) { _, newValue in
            if newValue != nil {
                // Start pulsing animation
                engineMoveGlow = 0.8
                withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                    engineMoveGlow = 0.3
                }
            } else {
                // Reset when cleared
                withAnimation(.easeOut(duration: 0.2)) {
                    engineMoveGlow = 0
                }
            }
        }
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
        pieceSelectedTrigger.toggle()
        gameState.selectSquare(position)
    }

    private func attemptMoveOrDeselect(from selectedSquare: ChessPosition) {
        let moveSuccessful = gameState.attemptMove(from: selectedSquare, to: position)

        if moveSuccessful {
            moveSuccessTrigger.toggle()
        } else {
            moveFailTrigger.toggle()
            deselectSquare()
        }
    }
}

#Preview {
    @Previewable @Namespace var testNamespace

    return ChessSquareView(
        position: ChessPosition(row: 0, col: 0),
        piece: ChessGameState().board[0][0],
        isSelected: false,
        gameState: ChessGameState(),
        pieceAnimationNamespace: testNamespace
    )
    .frame(width: 150, height: 150)
}
