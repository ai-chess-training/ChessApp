//
//  View.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//
import SwiftUI

struct GameStatusView: View {
    @Bindable var gameState: ChessGameState

    var shouldShowContent: Bool {
        switch gameState.gameStatus {
        case .inProgress:
            return gameState.isKingInCheck(color: gameState.currentPlayer)
        case .checkmate, .stalemate, .draw:
            return true
        }
    }

    var body: some View {
        if shouldShowContent {
            HStack {
                switch gameState.gameStatus {
                case .inProgress:
                    Text("Check!", bundle: .main, comment: "Alert message when king is in check")
                        .font(.title3)
                        .foregroundColor(.red)
                case .checkmate(let winner):
                    Text("Checkmate! \(winner.displayName) wins!", bundle: .main, comment: "Alert message when game ends in checkmate. %@ is the winning player name")
                        .font(.title2)
                        .foregroundColor(.green)
                case .stalemate:
                    Text("Stalemate!", bundle: .main, comment: "Alert message when game ends in stalemate")
                        .font(.title2)
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                case .draw:
                    Text("Draw!", bundle: .main, comment: "Alert message when game ends in draw")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .fontWeight(.bold)
            .background(Color(.systemGroupedBackground))
            .cornerRadius(12)
        }
    }
}

#Preview {
    GameStatusView(gameState: ChessGameState())
}
