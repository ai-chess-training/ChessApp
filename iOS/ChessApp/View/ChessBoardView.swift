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
        .allowsHitTesting(!gameState.isAnalyzingMove)
        .overlay(
            // Coaching analysis overlay
            Group {
                if gameState.isAnalyzingMove {
                    CoachingAnalysisOverlay()
                        .transition(.opacity.combined(with: .scale(scale: 0.9)))
                }
            }
        )
    }
}

// MARK: - Coaching Analysis Overlay

struct CoachingAnalysisOverlay: View {
    @State private var rotation: Double = 0
    @State private var pulseScale: Double = 1.0

    var body: some View {
        ZStack {
            // Very light transparent background
            Rectangle()
                .fill(.black.opacity(0.1))
                .background(.ultraThinMaterial.opacity(0.5))

            VStack(spacing: 16) {
                // Animated chess brain icon
                ZStack {
                    Circle()
                        .fill(.blue.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                pulseScale = 1.2
                            }
                        }

                    Image(systemName: "brain")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.blue)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                }

                VStack(spacing: 4) {
                    Text("Analyzing Move...")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text("Chess Coach is reviewing your move")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.3), value: pulseScale)
    }
}

#Preview {
    ChessBoardView(gameState: ChessGameState())
}

#Preview("Analysis Overlay") {
    ZStack {
        Rectangle()
            .fill(.gray.opacity(0.3))
            .frame(width: 300, height: 300)

        CoachingAnalysisOverlay()
    }
    .frame(width: 300, height: 300)
}
