//
//  ChessboardView.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import SwiftUI

struct ChessBoardView: View {
    @Bindable var gameState: ChessGameState

    // MARK: - Animation State

    @Namespace private var pieceAnimation
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { col in
                        let position = ChessPosition(row: row, col: col)
                        let piece = gameState.board[row][col]

                        ChessSquareView(
                            position: position,
                            piece: piece,
                            isSelected: gameState.selectedSquare == position,
                            gameState: gameState,
                            pieceAnimationNamespace: pieceAnimation
                        )
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.3), value: gameState.moveCount)
    }
}

#Preview {
    ChessBoardView(gameState: ChessGameState())
}
