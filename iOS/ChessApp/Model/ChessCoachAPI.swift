//
//  ChessCoachAPI.swift
//  ChessApp
//
//  Chess coaching API integration for move analysis and feedback
//

import Foundation

// MARK: - API Models

struct SessionResponse: Codable {
    let sessionId: String
    let fenStart: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case fenStart = "fen_start"
    }
}

struct MoveAnalysisResponse: Codable {
    let legal: Bool
    let humanFeedback: MoveFeedback?
    let engineMove: EngineMove?

    enum CodingKeys: String, CodingKey {
        case legal
        case humanFeedback = "human_feedback"
        case engineMove = "engine_move"
    }
}

struct MoveFeedback: Codable {
    let moveNo: Int
    let side: String
    let san: String
    let uci: String
    let fenBefore: String
    let fenAfter: String?
    let cpBefore: Int?
    let cpAfter: Int?
    let cpLoss: Double
    let severity: String
    let bestMoveSan: String?
    let basic: String?
    let extended: String?
    let tags: [String]
    let drills: [DrillExercise]

    enum CodingKeys: String, CodingKey {
        case moveNo = "move_no"
        case side, san, uci
        case fenBefore = "fen_before"
        case fenAfter = "fen_after"
        case cpBefore = "cp_before"
        case cpAfter = "cp_after"
        case cpLoss = "cp_loss"
        case severity
        case bestMoveSan = "best_move_san"
        case basic, extended, tags, drills
    }
}

struct DrillExercise: Codable {
    let fen: String
    let sideToMove: String
    let objective: String
    let bestLineSan: [String]
    let altTrapsSan: [String]?

    enum CodingKeys: String, CodingKey {
        case fen
        case sideToMove = "side_to_move"
        case objective
        case bestLineSan = "best_line_san"
        case altTrapsSan = "alt_traps_san"
    }
}

struct EngineMove: Codable {
    let san: String?
    let uci: String?
    let fenAfter: String?
    let score: ScoreInfo?
    let skillLevel: Int?

    enum CodingKeys: String, CodingKey {
        case san, uci
        case fenAfter = "fen_after"
        case score
        case skillLevel = "skill_level"
    }
}

struct ScoreInfo: Codable {
    let cp: Int?
    let mate: Int?
}

struct SessionSnapshot: Codable {
    let sessionId: String
    let skillLevel: String
    let gameMode: String
    let moves: [MoveFeedback]
    let currentFen: String

    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case skillLevel = "skill_level"
        case gameMode = "game_mode"
        case moves
        case currentFen = "current_fen"
    }
}

enum SkillLevel: String, CaseIterable {
    case beginner
    case advBeginner = "adv_beginner"
    case intermediate
    case advanced
    case expert

    var displayName: String {
        switch self {
        case .beginner: return "Beginner"
        case .advBeginner: return "Advanced Beginner"
        case .intermediate: return "Intermediate"
        case .advanced: return "Advanced"
        case .expert: return "Expert"
        }
    }
}

// MARK: - API Service

@Observable
class ChessCoachAPI: @unchecked Sendable {

    // MARK: - Configuration

    private let baseURL: String
    private let apiKey: String?
    private let session: URLSession

    private(set) var currentSessionId: String?
    private(set) var isConnected: Bool = false
    private(set) var lastError: String?

    init(baseURL: String? = nil, apiKey: String? = nil) {
        // Use provided URL or get from settings, fallback to localhost
        let configuredURL = baseURL ??
                          UserDefaults.standard.string(forKey: "ChessCoach.apiBaseURL") ??
                          "http://localhost:8000"

        self.baseURL = configuredURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        // Use provided API key or get from settings
        self.apiKey = apiKey ?? UserDefaults.standard.string(forKey: "ChessCoach.apiKey")

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30.0
        config.timeoutIntervalForResource = 60.0
        self.session = URLSession(configuration: config)
    }

    // MARK: - Session Management

    func createSession(skillLevel: SkillLevel = .intermediate, gameMode: String = "training") async throws -> SessionResponse {
        var components = URLComponents(string: "\(baseURL)/v1/sessions")!
        components.queryItems = [
            URLQueryItem(name: "skill_level", value: skillLevel.rawValue),
            URLQueryItem(name: "game_mode", value: gameMode)
        ]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        addAuthHeader(to: &request)

        do {
            let (data, response) = try await session.data(for: request)
            try validateResponse(response)

            let sessionResponse = try JSONDecoder().decode(SessionResponse.self, from: data)
            currentSessionId = sessionResponse.sessionId
            isConnected = true
            lastError = nil

            return sessionResponse
        } catch {
            isConnected = false
            lastError = error.localizedDescription
            print("🚨 Session creation failed:")
            print("   URL: \(components.url?.absoluteString ?? "invalid")")
            print("   Error: \(error)")
            throw error
        }
    }

    func getSession(sessionId: String) async throws -> SessionSnapshot {
        let url = URL(string: "\(baseURL)/v1/sessions/\(sessionId)")!
        var request = URLRequest(url: url)
        addAuthHeader(to: &request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)

        return try JSONDecoder().decode(SessionSnapshot.self, from: data)
    }

    // MARK: - Move Analysis

    func analyzeMove(sessionId: String, move: String) async throws -> MoveAnalysisResponse {
        var components = URLComponents(string: "\(baseURL)/v1/sessions/\(sessionId)/move")!
        components.queryItems = [URLQueryItem(name: "move", value: move)]

        var request = URLRequest(url: components.url!)
        request.httpMethod = "POST"
        addAuthHeader(to: &request)

        let (data, response) = try await session.data(for: request)

        // Special handling for 400 errors to get the actual error message
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 400 {
            if let errorMessage = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = errorMessage["detail"] as? String {
                print("🚨 API Error 400: \(detail)")
                throw APIError.badRequest
            }
        }

        // Debug: Print successful responses
        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
            print("✅ API Success 200: Move analysis received")
        }

        try validateResponse(response)

        let analysisResponse = try JSONDecoder().decode(MoveAnalysisResponse.self, from: data)

        if !analysisResponse.legal {
            lastError = "Illegal move"
        } else {
            lastError = nil
        }

        return analysisResponse
    }

    // MARK: - Convenience Methods

    func analyzeCurrentMove(_ move: String) async throws -> MoveAnalysisResponse {
        guard let sessionId = currentSessionId else {
            throw APIError.noActiveSession
        }
        return try await analyzeMove(sessionId: sessionId, move: move)
    }

    func startNewGame(skillLevel: SkillLevel = .intermediate, gameMode: String = "training") async throws -> SessionResponse {
        print("🔄 Starting new game, clearing session...")
        currentSessionId = nil

        print("📡 Creating new session...")
        let sessionResponse = try await createSession(skillLevel: skillLevel, gameMode: gameMode)

        print("✅ Session created successfully: \(sessionResponse.sessionId)")
        print("   Game mode: \(gameMode)")
        return sessionResponse
    }

    // MARK: - Helper Methods

    private func addAuthHeader(to request: inout URLRequest) {
        if let apiKey = apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard 200...299 ~= httpResponse.statusCode else {
            switch httpResponse.statusCode {
            case 401:
                throw APIError.unauthorized
            case 403:
                throw APIError.forbidden
            case 404:
                throw APIError.sessionNotFound
            case 400:
                throw APIError.badRequest
            default:
                throw APIError.serverError(httpResponse.statusCode)
            }
        }
    }

    // MARK: - Connection Testing

    func testConnection() async -> Bool {
        do {
            // Try to create a temporary session to test connectivity
            let _ = try await createSession()
            return true
        } catch {
            lastError = error.localizedDescription
            isConnected = false
            return false
        }
    }
}

// MARK: - Error Types

enum APIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case forbidden
    case sessionNotFound
    case badRequest
    case serverError(Int)
    case noActiveSession
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .unauthorized:
            return "Unauthorized - check API key"
        case .forbidden:
            return "Forbidden - invalid credentials"
        case .sessionNotFound:
            return "Chess session not found"
        case .badRequest:
            return "Invalid request"
        case .serverError(let code):
            return "Server error: \(code)"
        case .noActiveSession:
            return "No active chess session"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}