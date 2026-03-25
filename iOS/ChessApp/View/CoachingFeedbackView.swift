//
//  CoachingFeedbackView.swift
//  ChessApp
//
//  Displays chess move analysis and coaching feedback
//

import SwiftUI

struct CoachingFeedbackView: View {
    let gameState: ChessGameState
    @Environment(AppTheme.self) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: "brain")
                    .foregroundColor(theme.primaryColor)
                Text("Chess Coach")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()
                
                // API connection status
                connectionStatus
            }

            // Analysis status with enhanced UI
            if gameState.isAnalyzingMove {
                analysisStatusView(
                    icon: "brain",
                    title: "Analyzing move...",
                    subtitle: "Chess Coach is reviewing your move",
                    color: theme.primaryColor
                )
            } else if gameState.isCreatingSession {
                analysisStatusView(
                    icon: "cpu",
                    title: "Creating session...",
                    subtitle: "Setting up coaching session",
                    color: .orange
                )
            } else if gameState.chessCoachAPI.currentSessionId == nil && gameState.chessCoachAPI.lastError != nil {
                // Session creation failed (only show if there's an actual error)
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 32, height: 32)

                        Image(systemName: "exclamationmark.triangle")
                            .font(.callout.weight(.medium))
                            .foregroundColor(.red)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Session creation failed")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)

                        Text(gameState.chessCoachAPI.lastError ?? "Unable to connect to Chess Coach")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
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

            
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Analysis Status View

    private func analysisStatusView(icon: String, title: String, subtitle: String, color: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.callout.weight(.medium))
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

    private func feedbackContent(_ feedback: MoveFeedback) -> some View {
        VStack(alignment: .leading) {
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
            if let tags = feedback.tags, !tags.isEmpty {
                TagsView(tags: tags)
            }

            // Practice drills
            if let drills = feedback.drills, !drills.isEmpty {
                DrillsView(drills: drills)
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
                .foregroundColor(theme.primaryColor)
            }
        }
    }
}

struct TagsView: View {
    let tags: [String]
    @Environment(AppTheme.self) private var theme

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
                        .background(theme.primaryColor.opacity(0.1))
                        .foregroundColor(theme.primaryColor)
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
        CoachingFeedbackView(gameState: ChessGameState.sampleState())
        Spacer()
    }
    .padding()
}
