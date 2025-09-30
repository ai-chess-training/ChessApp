//
//  CoachingFeedbackView.swift
//  ChessApp
//
//  Displays chess move analysis and coaching feedback
//

import SwiftUI

struct CoachingFeedbackView: View {
    let gameState: ChessGameState
    @State private var showingSkillLevelAlert = false
    @State private var pendingSkillLevel: SkillLevel?

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

            }

            // Skill level picker (coaching is always enabled)
            skillLevelPicker

            // Analysis status with enhanced UI
            if gameState.isAnalyzingMove {
                analysisStatusView(
                    icon: "brain",
                    title: "Analyzing move...",
                    subtitle: "Chess Coach is reviewing your move",
                    color: .blue
                )
            } else if gameState.chessCoachAPI.currentSessionId == nil {
                analysisStatusView(
                    icon: "cpu",
                    title: "Creating session...",
                    subtitle: "Setting up coaching session",
                    color: .orange
                )
            }

            // Move feedback
            if let feedback = gameState.currentMoveFeedback {
                feedbackContent(feedback)
            } else if !gameState.isAnalyzingMove {
                Text("Make a move to receive coaching feedback")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }

            // API connection status
            connectionStatus
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("Change Skill Level?", isPresented: $showingSkillLevelAlert) {
            Button("Cancel", role: .cancel) {
                // Revert to previous skill level
                pendingSkillLevel = nil
            }
            Button("Reset & Change", role: .destructive) {
                confirmSkillLevelChange()
            }
        } message: {
            if let newLevel = pendingSkillLevel {
                Text("Changing to \(newLevel.displayName) requires resetting the game because a new coaching session will be created. This will start a fresh game at the new difficulty level.")
            }
        }
    }

    // MARK: - Analysis Status View

    private func analysisStatusView(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            ProgressView()
                .scaleEffect(0.8)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }

    // MARK: - Skill Level Change Handling

    private func handleSkillLevelChange(to newLevel: SkillLevel) {
        // Check if game is in progress
        if gameState.moveCount > 0 && newLevel != gameState.skillLevel {
            logDebug("Skill level change with game in progress - showing warning", category: .ui)
            pendingSkillLevel = newLevel
            showingSkillLevelAlert = true
            return
        }

        // Direct change (no game in progress or coaching disabled)
        gameState.updateSkillLevel(newLevel)
    }

    private func confirmSkillLevelChange() {
        guard let newLevel = pendingSkillLevel else { return }

        logDebug("User confirmed skill level change - resetting game and updating level", category: .ui)
        gameState.updateSkillLevel(newLevel)
        pendingSkillLevel = nil
    }

    private var skillLevelPicker: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Skill Level")
                .font(.caption)
                .foregroundColor(.secondary)

            Picker("Skill Level", selection: Binding(
                get: { gameState.skillLevel },
                set: { newLevel in
                    handleSkillLevelChange(to: newLevel)
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
        .accessibilityIdentifier("move_feedback")
    }

    private func severityIndicator(_ severity: String) -> some View {
        Circle()
            .fill(severityColor(severity))
            .frame(width: 8, height: 8)
            .accessibilityIdentifier("severity_indicator")
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
                .accessibilityIdentifier("connection_status_circle")

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
