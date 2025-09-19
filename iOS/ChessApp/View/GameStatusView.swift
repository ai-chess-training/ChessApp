//
//  View.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//
import SwiftUI

struct GameStatusView: View {
    @Bindable var gameState: ChessGameState
    
    var body: some View {
        HStack {
            Text("Current Player:", bundle: .main, comment: "Label for current player display")
                .font(.headline)
            
            Text(gameState.currentPlayer.displayName)
                .font(.headline)
                .foregroundColor(.primary)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(gameState.currentPlayer == .white ?
                              Color(.systemBackground) :
                                Color(.secondarySystemBackground))
                        .stroke(Color.primary, lineWidth: 1)
                )
            
            
            Spacer()
            
            
            switch gameState.gameStatus {
            case .inProgress:
                if gameState.isKingInCheck(color: gameState.currentPlayer) {
                    Text("Check!", bundle: .main, comment: "Alert message when king is in check")
                        .font(.title3)
                        .foregroundColor(.red)
                        .fontWeight(.bold)
                }
            case .checkmate(let winner):
                Text("Checkmate! \(winner.displayName) wins!", bundle: .main, comment: "Alert message when game ends in checkmate. %@ is the winning player name")
                    .font(.title2)
                    .foregroundColor(.green)
                    .fontWeight(.bold)
            case .stalemate:
                Text("Stalemate!", bundle: .main, comment: "Alert message when game ends in stalemate")
                    .font(.title2)
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
            case .draw:
                Text("Draw!", bundle: .main, comment: "Alert message when game ends in draw")
                    .font(.title2)
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(Color(.systemGroupedBackground))
        .cornerRadius(12)
    }
}

#Preview {
    GameStatusView(gameState: ChessGameState())
}
