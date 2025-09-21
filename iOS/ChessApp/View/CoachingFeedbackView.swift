//
//  CoachingFeedbackView.swift
//  ChessApp
//
//  Displays chess move analysis and coaching feedback
//

import SwiftUI

struct CoachingFeedbackView: View {
    let gameState: ChessGameState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(.blue)
                Text("Chess Coach")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                // Coaching toggle
                Toggle("", isOn: Binding(
                    get: { gameState.isCoachingEnabled },
                    set: { isEnabled in
                        if isEnabled {
                            gameState.enableCoaching(skillLevel: gameState.skillLevel)
                        } else {
                            gameState.disableCoaching()
                        }
                    }
                ))
                .labelsHidden()
            }

            if gameState.isCoachingEnabled {
                // Skill level picker
                skillLevelPicker

                // Analysis status
                if gameState.isAnalyzingMove {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Analyzing move...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                // Move feedback
                if let feedback = gameState.currentMoveFeedback {
                    feedbackContent(feedback)
                } else if !gameState.isAnalyzingMove {
                    if gameState.coachingDisabledByUndo {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle")
                                    .foregroundColor(.orange)
                                Text("Coaching disabled")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                            Text("Game state is out of sync due to undo operation. Toggle coaching off and on again to resume.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        Text("Make a move to receive coaching feedback")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }

                // API connection status
                connectionStatus
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private var skillLevelPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Skill Level")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Skill Level", selection: Binding(
                get: { gameState.skillLevel },
                set: { newLevel in
                    gameState.skillLevel = newLevel
                    if gameState.isCoachingEnabled {
                        gameState.enableCoaching(skillLevel: newLevel)
                    }
                }
            )) {
                ForEach(SkillLevel.allCases, id: \.self) { level in
                    Text(level.displayName)
                        .tag(level)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    private func feedbackContent(_ feedback: MoveFeedback) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            // Move info
            HStack {
                Text("Move \(feedback.moveNo)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text(feedback.san)
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
            }

            // Severity indicator
            if !feedback.severity.isEmpty {
                HStack {
                    severityIndicator(feedback.severity)
                    Text(feedback.severity.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }

            // Basic feedback
            if let basic = feedback.basic, !basic.isEmpty {
                Text(basic)
                    .font(.system(.callout))
                    .padding(.vertical, 4)
            }

            // Extended feedback (collapsible)
            if let extended = feedback.extended, !extended.isEmpty {
                ExtendedFeedbackView(extended: extended)
            }

            // Best move suggestion
            if let bestMove = feedback.bestMoveSan, bestMove != feedback.san {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                    Text("Better: \(bestMove)")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .padding(.top, 4)
            }

            // Tags
            if !feedback.tags.isEmpty {
                TagsView(tags: feedback.tags)
            }

            // Practice drills
            if !feedback.drills.isEmpty {
                DrillsView(drills: feedback.drills)
            }
        }
    }

    private func severityIndicator(_ severity: String) -> some View {
        Circle()
            .fill(severityColor(severity))
            .frame(width: 8, height: 8)
    }

    private func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "excellent", "good":
            return .green
        case "inaccuracy", "inaccurate":
            return .yellow
        case "mistake":
            return .orange
        case "blunder":
            return .red
        default:
            return .gray
        }
    }

    private var connectionStatus: some View {
        HStack {
            Circle()
                .fill(gameState.chessCoachAPI.isConnected ? .green : .red)
                .frame(width: 6, height: 6)

            Text(gameState.chessCoachAPI.isConnected ? "Connected" : "Disconnected")
                .font(.caption2)
                .foregroundColor(.secondary)

            if let error = gameState.chessCoachAPI.lastError {
                Spacer()
                Text(error)
                Button("Retry") {
                    Task {
                        //let _ = await gameState.testAPIConnection()
                    }
                }
                .font(.caption2)
                .foregroundColor(.blue)
            }
        }
    }
}

struct ExtendedFeedbackView: View {
    let extended: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Detailed Analysis")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                Text(extended)
                    .font(.caption)
                    .padding(.vertical, 4)
                    .animation(.easeInOut, value: isExpanded)
            }
        }
    }
}

struct TagsView: View {
    let tags: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Concepts")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 80), spacing: 4)
            ], spacing: 4) {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                }
            }
        }
    }
}

struct DrillsView: View {
    let drills: [DrillExercise]
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Practice Suggestions")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: { isExpanded.toggle() }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            if isExpanded {
                ForEach(drills.indices, id: \.self) { index in
                    let drill = drills[index]
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(alignment: .top) {
                            Text("•")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(drill.objective)
                                    .font(.caption)
                                    .fontWeight(.medium)

                                if !drill.bestLineSan.isEmpty {
                                    Text("Best line: \(drill.bestLineSan.joined(separator: " "))")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .animation(.easeInOut, value: isExpanded)
            }
        }
    }
}

#Preview {
    VStack {
        CoachingFeedbackView(gameState: {
            let state = ChessGameState()
            state.isCoachingEnabled = true
            state.currentMoveFeedback = MoveFeedback(
                moveNo: 1,
                side: "white",
                san: "e4",
                uci: "e2e4",
                fenBefore: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                fenAfter: nil,
                cpBefore: 0,
                cpAfter: 25,
                cpLoss: 0.0,
                severity: "good",
                bestMoveSan: "e4",
                basic: "Excellent opening move! You control the center and develop quickly.",
                extended: "The King's Pawn opening is one of the most popular and strong openings in chess. By playing e4, you immediately control the central squares d5 and f5, and you open lines for your bishop and queen.",
                tags: ["opening", "center control", "development"],
                drills: [
                    DrillExercise(
                        fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1",
                        sideToMove: "white",
                        objective: "Practice more King's Pawn openings",
                        bestLineSan: ["e4", "e5"],
                        altTrapsSan: nil
                    )
                ]
            )
            return state
        }())
        Spacer()
    }
    .padding()
}
