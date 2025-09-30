//
//  PawnPromotionView.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/7/25.
//

import SwiftUI

struct PawnPromotionView: View {
    let color: ChessColor
    let onSelection: (PieceType) -> Void
    let onCancel: () -> Void
    
    private let promotionPieces: [PieceType] = [.queen, .rook, .bishop, .knight]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Pawn Promotion", bundle: .main, comment: "Title for pawn promotion dialog")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityIdentifier("pawn_promotion_title")

            Text("Choose a piece to promote to:", bundle: .main, comment: "Instruction text in pawn promotion dialog")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 15) {
                ForEach(promotionPieces, id: \.self) { pieceType in
                    Button(action: {
                        onSelection(pieceType)
                    }) {
                        VStack(spacing: 8) {
                            Text(pieceType.symbol(for: color))
                                .font(.system(size: 40))

                            Text(pieceType.rawValue.capitalized)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                        .frame(width: 60, height: 80)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityIdentifier("promote_to_\(pieceType.rawValue)")
                }
            }
            
            Button(String(localized: "Cancel", comment: "Cancel button text"), action: onCancel)
                .buttonStyle(.bordered)
                .foregroundColor(.red)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}

#Preview {
    PawnPromotionView(
        color: .white,
        onSelection: { piece in
            logDebug("Pawn promotion selected: \(piece)", category: .ui)
        },
        onCancel: {
            logDebug("Pawn promotion cancelled", category: .ui)
        }
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}