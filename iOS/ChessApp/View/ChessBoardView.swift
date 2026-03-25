//
//  ChessboardView.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import SwiftUI

struct ChessBoardView: View {
    @Bindable var gameState: ChessGameState

    // MARK: - Constants
    
    private static let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
    private static let ranks = ["8", "7", "6", "5", "4", "3", "2", "1"] // row 0 = rank 8, row 7 = rank 1
    private static let labelSize: CGFloat = 16

    // MARK: - Animation State

    @Namespace private var pieceAnimation

    var body: some View {
        VStack(spacing: 0) {
            // File labels (top)
            fileLabelsRow
            
            // Board rows with rank labels on both sides
            HStack(spacing: 0) {
                // Rank labels (left side)
                rankLabelsColumn
                
                // Chess board grid
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
                .aspectRatio(1, contentMode: .fit)
                .cornerRadius(8)
                .overlay(
                    // Coaching analysis overlay
                    Group {
                        if gameState.isAnalyzingMove {
                            CoachingAnalysisOverlay(gameMode: gameState.gameMode, isWaitingForEngine: gameState.isWaitingForEngineMove)
                                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                        }
                    }
                )
                
                // Rank labels (right side)
                rankLabelsColumn
            }
            
            // File labels (bottom)
            fileLabelsRow
        }
        .frame(maxWidth: .infinity)
        .animation(.easeInOut(duration: 0.3), value: gameState.moveCount)
        .allowsHitTesting(!gameState.isAnalyzingMove)
    }
    
    // MARK: - Label Views
    
    private var rankLabelsColumn: some View {
        VStack(spacing: 0) {
            ForEach(0..<8, id: \.self) { row in
                Text(Self.ranks[row])
                    .font(.caption2.monospaced())
                    .foregroundColor(.secondary)
                    .frame(width: Self.labelSize)
                    .frame(maxHeight: .infinity)
            }
        }
    }
    
    private var fileLabelsRow: some View {
        HStack(spacing: 0) {
            // Spacer to align with rank label column
            Color.clear
                .frame(width: Self.labelSize, height: Self.labelSize)
            
            ForEach(0..<8, id: \.self) { col in
                Text(Self.files[col])
                    .font(.caption2.monospaced())
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.labelSize)
            }
            
            // Spacer to align with right rank label column
            Color.clear
                .frame(width: Self.labelSize, height: Self.labelSize)
        }
    }
}

// MARK: - Coaching Analysis Overlay

struct CoachingAnalysisOverlay: View {
    let gameMode: GameMode
    let isWaitingForEngine: Bool
    @State private var rotation: Double = 0
    @State private var pulseScale: Double = 1.0
    @Environment(AppTheme.self) private var theme

    var body: some View {
        ZStack {
            // Very light transparent background
            Rectangle()
                .fill(.black.opacity(0.1))
                .background(.ultraThinMaterial.opacity(0.5))

            VStack(spacing: 16) {
                // Animated icon based on state
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulseScale)
                        .onAppear {
                            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                                pulseScale = 1.2
                            }
                        }

                    Image(systemName: iconName)
                        .font(.title.weight(.medium))
                        .foregroundColor(iconColor)
                        .rotationEffect(.degrees(rotation))
                        .onAppear {
                            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                                rotation = 360
                            }
                        }
                }

                VStack(spacing: 4) {
                    Text(titleText)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(subtitleText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .cornerRadius(8)
        .animation(.easeInOut(duration: 0.3), value: pulseScale)
    }

    // MARK: - Dynamic Content

    private var iconName: String {
        if isWaitingForEngine {
            return "cpu"
        } else {
            return "brain"
        }
    }

    private var iconColor: Color {
        // Use theme color for normal analysis, keep orange for engine thinking
        if isWaitingForEngine {
            return .orange
        } else {
            return theme.primaryColor
        }
    }

    private var titleText: String {
        if isWaitingForEngine {
            return "Engine Thinking..."
        } else {
            return "Analyzing Move..."
        }
    }

    private var subtitleText: String {
        if isWaitingForEngine {
            return "AI is calculating its move"
        } else if gameMode == .humanVsMachine {
            return "Chess Coach is analyzing your move"
        } else {
            return "Chess Coach is reviewing your move"
        }
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

        CoachingAnalysisOverlay(gameMode: .humanVsMachine, isWaitingForEngine: false)
    }
    .frame(width: 300, height: 300)
}

#Preview("Engine Thinking") {
    ZStack {
        Rectangle()
            .fill(.gray.opacity(0.3))
            .frame(width: 300, height: 300)

        CoachingAnalysisOverlay(gameMode: .humanVsMachine, isWaitingForEngine: true)
    }
    .frame(width: 300, height: 300)
}
