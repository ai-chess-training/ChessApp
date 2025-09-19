//
//  ChessboardView.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import SwiftUI

struct ChessBoardView: View {
    @Bindable var gameState: ChessGameState
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<8, id: \.self) { col in
                        ChessSquareView(
                            position: ChessPosition(row: row, col: col),
                            piece: gameState.board[row][col],
                            isSelected: gameState.selectedSquare == ChessPosition(row: row, col: col),
                            gameState: gameState
                        )
                        .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
        }
        .cornerRadius(8)
    }
}

#Preview {
    ChessBoardView(gameState: ChessGameState())
}
