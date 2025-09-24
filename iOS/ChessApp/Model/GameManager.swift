//
//  GameManager.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import Observation
import Foundation

// MARK: - Game Mode

enum GameMode: String, CaseIterable {
    case humanVsHuman = "training"
    case humanVsMachine = "play"

    var displayName: String {
        switch self {
        case .humanVsHuman: return "Human vs Human"
        case .humanVsMachine: return "Human vs Machine"
        }
    }

    var description: String {
        switch self {
        case .humanVsHuman: return "Play against another human with coaching analysis"
        case .humanVsMachine: return "Play against AI engine with coaching feedback"
        }
    }
}

@Observable
class ChessGameState: @unchecked Sendable {
    var selectedSquare: ChessPosition?
    var board: [[ChessPiece?]] = Array(repeating: Array(repeating: nil, count: 8), count: 8)
    var currentPlayer: ChessColor = .white
    var gameStatus: GameStatus = .inProgress
    var capturedPieces: [ChessPiece] = []
    var moveHistory: [String] = []
    var moveCount = 0

    // MARK: - Haptic Feedback State

    var captureTrigger = false
    var checkmateTrigger = false
    var checkTrigger = false
    var stalemateTrigger = false

    // MARK: - Game Mode and Chess Coach API Integration

    var gameMode: GameMode = .humanVsMachine // default to play with Engine, and only allow this for now.
    var chessCoachAPI: ChessCoachAPI
    var currentMoveFeedback: MoveFeedback?
    var isAnalyzingMove: Bool = false
    var skillLevel: SkillLevel = .intermediate
    var isWaitingForEngineMove: Bool = false
    
    // Chess rules engine and move history
    var ruleEngine: ChessRuleEngine?
    private var moveHistoryManager = MoveHistoryManager()
    
    // Debug flag for showing move history
    var isDebugMode: Bool = false
    
    // Castling rights
    var castlingRights = CastlingRights()
    
    // Pawn promotion state
    var showingPawnPromotion: Bool = false
    var promotionMove: (from: ChessPosition, to: ChessPosition)?
    
    // En passant state
    var enPassantTarget: ChessPosition?
    
    // Cached king positions for performance
    var whiteKingPosition: ChessPosition = ChessPosition(row: 7, col: 4)
    var blackKingPosition: ChessPosition = ChessPosition(row: 0, col: 4)
    
    // User tracking
    var currentUserName: String = "Guest"
    var gameStartTime: Date?
    
    init() {
        chessCoachAPI = ChessCoachAPI()
        ruleEngine = ChessRuleEngine()
        gameStartTime = Date()

        // Load default settings
        if let savedLevel = UserDefaults.standard.string(forKey: "ChessCoach.defaultSkillLevel"),
           let level = SkillLevel(rawValue: savedLevel) {
            skillLevel = level
        }

        isDebugMode = UserDefaults.standard.bool(forKey: "ChessCoach.shouldShowHistory")

        setupInitialBoard()

        // Start coaching session automatically since coaching is always enabled
        Task {
            await startNewCoachingSession()
        }
    }
    
    func setCurrentUser(_ userName: String) {
        currentUserName = userName
    }
    
    func resetGame() {
        selectedSquare = nil
        board = Array(repeating: Array(repeating: nil, count: 8), count: 8)
        currentPlayer = .white
        gameStatus = .inProgress
        capturedPieces = []
        moveHistory = []
        moveCount = 0
        castlingRights = CastlingRights()
        showingPawnPromotion = false
        promotionMove = nil
        enPassantTarget = nil
        whiteKingPosition = ChessPosition(row: 7, col: 4)
        blackKingPosition = ChessPosition(row: 0, col: 4)
        gameStartTime = Date()
        moveHistoryManager.clear()
        currentMoveFeedback = nil
        isAnalyzingMove = false
        setupInitialBoard()

        // Always start new coaching session for fresh game
        Task {
            await startNewCoachingSession()
        }
    }
    
    private func setupInitialBoard() {
        // Setup initial chess position (just for UI demonstration)
        // Black pieces (top)
        board[0] = [
            ChessPiece(.rook, .black), ChessPiece(.knight, .black), ChessPiece(.bishop, .black), ChessPiece(.queen, .black),
            ChessPiece(.king, .black), ChessPiece(.bishop, .black), ChessPiece(.knight, .black), ChessPiece(.rook, .black)
        ]
        board[1] = Array(repeating: ChessPiece(.pawn, .black), count: 8)
        
        // White pieces (bottom)
        board[6] = Array(repeating: ChessPiece(.pawn, .white), count: 8)
        board[7] = [
            ChessPiece(.rook, .white), ChessPiece(.knight, .white), ChessPiece(.bishop, .white), ChessPiece(.queen, .white),
            ChessPiece(.king, .white), ChessPiece(.bishop, .white), ChessPiece(.knight, .white), ChessPiece(.rook, .white)
        ]
        
    }
    
    func selectSquare(_ position: ChessPosition) {
        selectedSquare = position
    }
    
    func attemptMove(from: ChessPosition, to: ChessPosition) -> Bool {
        guard let ruleEngine = ruleEngine else { return false }
        
        Logger.debug("Attempting move from (\(from.row), \(from.col)) to (\(to.row), \(to.col))", category: Logger.game)
        
        let validationResult = ruleEngine.canMovePiece(from: from, to: to, gameState: self)
        
        switch validationResult {
        case .valid:
            Logger.debug("Move is valid, executing...", category: Logger.game)
            return executeMove(from: from, to: to)
        case .requiresPromotion(_):
            Logger.debug("Pawn promotion required, showing UI", category: Logger.game)
            promotionMove = (from: from, to: to)
            showingPawnPromotion = true
            return true // Return true to indicate move handling is in progress
        case .invalid(let reason):
            Logger.debug("Invalid move: \(reason)", category: Logger.game)
            return false
        }
    }
    
    private func executeMove(from: ChessPosition, to: ChessPosition, promoteTo: PieceType? = nil) -> Bool {
        guard let movingPiece = pieceAt(from) else { return false }
        
        let capturedPiece = pieceAt(to)
        let previousGameStatus = gameStatus
        let wasKingInCheck = isKingInCheck(color: currentPlayer)
        
        // Check if this is a special move
        let isCastling = movingPiece.type == .king && abs(to.col - from.col) == 2
        let isEnPassant = movingPiece.type == .pawn && to == enPassantTarget
        
        // Create move record before making the move
        let moveRecord = ChessMoveRecord(
            from: from,
            to: to,
            piece: movingPiece,
            capturedPiece: capturedPiece,
            promotionPiece: promoteTo,
            moveNumber: moveHistoryManager.currentMoveNumber,
            previousGameStatus: previousGameStatus,
            wasKingInCheck: wasKingInCheck,
            previousCastlingRights: castlingRights,
            previousEnPassantTarget: enPassantTarget
        )
        
        // Execute the move
        if let promoteTo = promoteTo, movingPiece.type == .pawn {
            setPiece(ChessPiece(promoteTo, movingPiece.color), at: to)
        } else {
            setPiece(movingPiece, at: to)
        }
        setPiece(nil, at: from)
        
        // Update king position cache if king moved
        if movingPiece.type == .king {
            if movingPiece.color == .white {
                whiteKingPosition = to
            } else {
                blackKingPosition = to
            }
        }
        
        // Handle castling - move the rook
        if isCastling {
            let isKingSide = to.col > from.col
            let rookFromCol = isKingSide ? 7 : 0
            let rookToCol = isKingSide ? to.col - 1 : to.col + 1
            let rookFrom = ChessPosition(row: from.row, col: rookFromCol)
            let rookTo = ChessPosition(row: from.row, col: rookToCol)
            
            if let rook = pieceAt(rookFrom) {
                setPiece(rook, at: rookTo)
                setPiece(nil, at: rookFrom)
            }
        }
        
        // Handle en passant - remove captured pawn
        if isEnPassant {
            let capturedPawnRow = movingPiece.color == .white ? to.row + 1 : to.row - 1
            let capturedPawnPos = ChessPosition(row: capturedPawnRow, col: to.col)
            if let capturedPawn = pieceAt(capturedPawnPos) {
                capturedPieces.append(capturedPawn)
                setPiece(nil, at: capturedPawnPos)
            }
        }
        
        // Update castling rights
        updateCastlingRights(for: movingPiece, from: from)
        if let captured = capturedPiece, captured.type == .rook {
            updateCastlingRightsForCapturedRook(at: to, color: captured.color)
        }
        
        // Handle captured piece
        if let captured = capturedPiece {
            capturedPieces.append(captured)
            captureTrigger.toggle()
        }
        
        // Record the move
        moveHistoryManager.addMove(moveRecord)
        moveHistory = moveHistoryManager.getAlgebraicMoves()
        moveCount += 1
        
        // Update en passant target
        updateEnPassantTarget(for: movingPiece, from: from, to: to)
        
        // Update game state
        selectedSquare = nil

        // Capture the moving player before switching
        let movingPlayer = currentPlayer

        // Switch players
        currentPlayer = currentPlayer == .white ? .black : .white

        // Analyze the move if coaching is enabled (but not for engine moves)
        if !isWaitingForEngineMove {
            Task {
                await analyzeLastMove(for: movingPlayer)
            }
        }

        // Check for game ending conditions
        updateGameStatus()

        return true
    }
    
    private func updateGameStatus() {
        guard let ruleEngine = ruleEngine else { return }

        if ruleEngine.isCheckmate(color: currentPlayer, gameState: self) {
            gameStatus = .checkmate(winner: currentPlayer == .white ? .black : .white)
            checkmateTrigger.toggle()
        } else if ruleEngine.isStalemate(color: currentPlayer, gameState: self) {
            gameStatus = .stalemate
            stalemateTrigger.toggle()
        } else {
            gameStatus = .inProgress
            // Check if current player is in check
            if isKingInCheck(color: currentPlayer) {
                checkTrigger.toggle()
            }
        }
    }
    
    func isSquareAvailable(position: ChessPosition) -> Bool {
        guard let selectedSquare = selectedSquare,
              let ruleEngine = ruleEngine else { return false }
        
        let availableMoves = ruleEngine.getAvailableMoves(for: selectedSquare, gameState: self)
        return availableMoves.contains(position)
    }
    
    func isKingInCheck(color: ChessColor) -> Bool {
        return ruleEngine?.isKingInCheck(color: color, gameState: self) ?? false
    }
    
    func getKingPosition(color: ChessColor) -> ChessPosition {
        return color == .white ? whiteKingPosition : blackKingPosition
    }
    
    func isKingInCheckAt(position: ChessPosition) -> Bool {
        guard let piece = pieceAt(position), piece.type == .king else { return false }
        return isKingInCheck(color: piece.color)
    }
    
    // MARK: - Safe Board Access Helpers
    
    func pieceAt(_ position: ChessPosition) -> ChessPiece? {
        guard isValidPosition(position) else { return nil }
        return board[position.row][position.col]
    }
    
    func setPiece(_ piece: ChessPiece?, at position: ChessPosition) {
        guard isValidPosition(position) else { return }
        board[position.row][position.col] = piece
    }
    
    func isValidPosition(_ position: ChessPosition) -> Bool {
        return position.row >= 0 && position.row < 8 && position.col >= 0 && position.col < 8
    }
    
    func isEmpty(at position: ChessPosition) -> Bool {
        return pieceAt(position) == nil
    }
    
    // MARK: - Undo Functionality
    
    func canUndo() -> Bool {
        return moveCount > 0
    }
    
    func undoLastMove() -> Bool {
        guard let lastMove = moveHistoryManager.undoLastMove() else {
            return false
        }

        Logger.warning("Undo detected - will disable coaching (game state out of sync)", category: Logger.coaching)
        
        // Restore the piece to its original position
        let finalPiece: ChessPiece
        if lastMove.promotionPiece != nil {
            // If it was a promotion, restore the original pawn
            finalPiece = lastMove.piece
        } else {
            finalPiece = lastMove.piece
        }
        
        setPiece(finalPiece, at: lastMove.from)
        setPiece(lastMove.capturedPiece, at: lastMove.to)
        
        // Restore king position cache if king was moved
        if lastMove.piece.type == .king {
            if lastMove.piece.color == .white {
                whiteKingPosition = lastMove.from
            } else {
                blackKingPosition = lastMove.from
            }
        }
        
        // Handle castling undo - move the rook back
        if lastMove.isCastling {
            let isKingSide = lastMove.to.col > lastMove.from.col
            let rookFromCol = isKingSide ? lastMove.to.col - 1 : lastMove.to.col + 1
            let rookToCol = isKingSide ? 7 : 0
            let rookFrom = ChessPosition(row: lastMove.from.row, col: rookFromCol)
            let rookTo = ChessPosition(row: lastMove.from.row, col: rookToCol)
            
            if let rook = pieceAt(rookFrom) {
                setPiece(rook, at: rookTo)
                setPiece(nil, at: rookFrom)
            }
        }
        
        // Handle en passant undo - restore captured pawn
        let wasEnPassant = lastMove.piece.type == .pawn && lastMove.to == lastMove.previousEnPassantTarget
        if wasEnPassant {
            let capturedPawnRow = lastMove.piece.color == .white ? lastMove.to.row + 1 : lastMove.to.row - 1
            let capturedPawnPos = ChessPosition(row: capturedPawnRow, col: lastMove.to.col)
            let capturedPawn = ChessPiece(.pawn, lastMove.piece.color == .white ? .black : .white)
            setPiece(capturedPawn, at: capturedPawnPos)
        }
        
        // Remove captured piece from captured pieces list
        if let capturedPiece = lastMove.capturedPiece {
            if let index = capturedPieces.lastIndex(where: { $0.type == capturedPiece.type && $0.color == capturedPiece.color }) {
                capturedPieces.remove(at: index)
            }
        }
        
        // Restore game state
        gameStatus = lastMove.previousGameStatus
        currentPlayer = lastMove.piece.color // Switch back to the player who made the move
        castlingRights = lastMove.previousCastlingRights // Restore castling rights
        enPassantTarget = lastMove.previousEnPassantTarget // Restore en passant target
        moveHistory = moveHistoryManager.getAlgebraicMoves()
        moveCount -= 1
        
        // Clear selection
        selectedSquare = nil

        return true
    }
    
    // MARK: - Castling Rights Management
    
    private func updateCastlingRights(for piece: ChessPiece, from position: ChessPosition) {
        if piece.type == .king {
            castlingRights.disableKingMoved(piece.color)
        } else if piece.type == .rook {
            let isKingSide = position.col == 7
            castlingRights.disableRookMoved(piece.color, kingSide: isKingSide)
        }
    }
    
    private func updateCastlingRightsForCapturedRook(at position: ChessPosition, color: ChessColor) {
        let isKingSide = position.col == 7
        castlingRights.disableRookMoved(color, kingSide: isKingSide)
    }
    
    // MARK: - En Passant Management
    
    private func updateEnPassantTarget(for piece: ChessPiece, from: ChessPosition, to: ChessPosition) {
        // Clear previous en passant target
        enPassantTarget = nil
        
        // Set new en passant target if pawn moved two squares
        if piece.type == .pawn && abs(to.row - from.row) == 2 {
            let targetRow = piece.color == .white ? from.row - 1 : from.row + 1
            enPassantTarget = ChessPosition(row: targetRow, col: from.col)
        }
    }
    
    // MARK: - Pawn Promotion Handling
    
    func completePawnPromotion(with pieceType: PieceType) {
        guard let move = promotionMove else { return }
        
        showingPawnPromotion = false
        promotionMove = nil
        
        // Clear selection first
        selectedSquare = nil
        
        // Execute the move with promotion
        let _ = executeMove(from: move.from, to: move.to, promoteTo: pieceType)
    }
    
    func cancelPawnPromotion() {
        showingPawnPromotion = false
        promotionMove = nil
        selectedSquare = nil
    }

    // MARK: - Chess Coach Integration

    func enableCoaching(skillLevel: SkillLevel = .intermediate) {
        Logger.debug("enableCoaching called with skill level: \(skillLevel.displayName)", category: Logger.coaching)
        self.skillLevel = skillLevel

        // Create session if we don't have one
        if chessCoachAPI.currentSessionId == nil {
            Logger.debug("No active session, creating one...", category: Logger.coaching)
            Task {
                await startNewCoachingSession()
            }
        } else {
            Logger.debug("Reusing existing session: \(chessCoachAPI.currentSessionId!)", category: Logger.coaching)
        }
    }

    func updateGameMode(_ newMode: GameMode) {
        let previousMode = gameMode
        gameMode = newMode

        Logger.debug("Updating game mode from \(previousMode.displayName) to \(newMode.displayName)", category: Logger.coaching)

        // Only recreate session if mode actually changed
        if previousMode != newMode {
            Logger.debug("Game mode change detected, recreating session...", category: Logger.coaching)
            Task {
                await startNewCoachingSession()
            }
        } else if previousMode != newMode {
            Logger.debug("Game mode changed but coaching is disabled - will use new mode when enabled", category: Logger.coaching)
        } else {
            Logger.debug("Game mode unchanged", category: Logger.coaching)
        }
    }

    func updateSkillLevel(_ newLevel: SkillLevel) {
        let previousLevel = skillLevel
        skillLevel = newLevel

        Logger.debug("Updating skill level from \(previousLevel.displayName) to \(newLevel.displayName)", category: Logger.coaching)

        // Only recreate session if level actually changed
        if previousLevel != newLevel {
            Logger.debug("Skill level change detected, resetting board and recreating session...", category: Logger.coaching)

            // Reset the board first to sync with new session
            resetGame()

            Task {
                await startNewCoachingSession()
            }
        } else if previousLevel != newLevel {
            Logger.debug("Skill level changed but coaching is disabled - will use new level when enabled", category: Logger.coaching)
        } else {
            Logger.debug("Skill level unchanged", category: Logger.coaching)
        }
    }

    @MainActor
    private func startNewCoachingSession() async {
        Logger.debug("Starting new coaching session...", category: Logger.coaching)

        do {
            let sessionResponse = try await chessCoachAPI.startNewGame(skillLevel: skillLevel, gameMode: gameMode.rawValue)
            Logger.info("Started new coaching session", category: Logger.coaching)
            Logger.debug("Session ID: \(sessionResponse.sessionId)", category: Logger.coaching)
            Logger.debug("Skill level: \(skillLevel.displayName)", category: Logger.coaching)
            Logger.debug("Game mode: \(gameMode.displayName)", category: Logger.coaching)
            Logger.debug("Starting position: \(sessionResponse.fenStart)", category: Logger.coaching)
        } catch {
            Logger.error("Failed to start coaching session: \(error)", category: Logger.coaching)
            Logger.error("Error type: \(type(of: error))", category: Logger.coaching)
            Logger.error("Error description: \(error.localizedDescription)", category: Logger.coaching)
        }
    }

    func analyzeLastMove(for movingPlayer: ChessColor) async {
        Logger.debug("analyzeLastMove called for: \(movingPlayer == .white ? "White" : "Black")", category: Logger.coaching)


        guard let lastMoveRecord = moveHistoryManager.getLastMove() else {
            Logger.debug("No last move record found", category: Logger.coaching)
            return
        }

        guard !isAnalyzingMove else {
            Logger.debug("Already analyzing a move", category: Logger.coaching)
            return
        }

        Logger.debug("All guards passed, starting analysis for \(movingPlayer == .white ? "White" : "Black")", category: Logger.coaching)

        await MainActor.run {
            isAnalyzingMove = true
        }

        do {
            // Convert move to algebraic notation
            let moveString = convertMoveToAlgebraic(lastMoveRecord, movingPlayer: movingPlayer)
            Logger.debug("Analyzing move: \(moveString)", category: Logger.coaching)
            Logger.debug("Session ID: \(chessCoachAPI.currentSessionId ?? "NONE")", category: Logger.coaching)
            Logger.debug("iOS move count: \(moveCount)", category: Logger.coaching)
            Logger.debug("iOS current player: \(currentPlayer)", category: Logger.coaching)

            let analysis = try await chessCoachAPI.analyzeCurrentMove(moveString)

            await MainActor.run {
                currentMoveFeedback = analysis.humanFeedback
                isAnalyzingMove = false

                // Handle engine move in human vs machine mode
                if gameMode == .humanVsMachine, let engineMove = analysis.engineMove {
                    handleEngineMove(engineMove)
                }
            }

            Logger.info("Move analysis complete: \(analysis.humanFeedback?.basic ?? "No feedback")", category: Logger.coaching)

            // Log engine move if present
            if gameMode == .humanVsMachine {
                if let engineMove = analysis.engineMove {
                    Logger.debug("Engine move: \(engineMove.san ?? engineMove.uci ?? "unknown")", category: Logger.game)
                } else {
                    Logger.debug("No engine move (game may be over)", category: Logger.game)
                }
            }

        } catch {
            await MainActor.run {
                isAnalyzingMove = false
            }
            Logger.error("Failed to analyze move: \(error)", category: Logger.coaching)
            Logger.error("Error type: \(type(of: error))", category: Logger.coaching)
            Logger.error("Error description: \(error.localizedDescription)", category: Logger.coaching)

            // If it's an API error, let's see the details
            if let apiError = error as? APIError {
                Logger.error("API Error details: \(apiError.localizedDescription)", category: Logger.api)
            }

            // Check for specific error types
            if let urlError = error as? URLError {
                Logger.error("URL Error code: \(urlError.code)", category: Logger.api)
                Logger.error("URL Error description: \(urlError.localizedDescription)", category: Logger.api)
            }

            if let decodingError = error as? DecodingError {
                Logger.error("JSON Decoding Error: \(decodingError)", category: Logger.api)
            }
        }
    }

    // MARK: - Engine Move Handling

    @MainActor
    private func handleEngineMove(_ engineMove: EngineMove) {
        guard let uciMove = engineMove.uci else {
            Logger.error("Engine move missing UCI notation", category: Logger.game)
            return
        }

        Logger.debug("Processing engine move: \(uciMove)", category: Logger.game)

        // Parse UCI move (e.g., "e2e4", "e7e8q" for promotion)
        guard uciMove.count >= 4,
              let fromPos = parseSquare(from: String(uciMove.prefix(2))),
              let toPos = parseSquare(from: String(uciMove.dropFirst(2).prefix(2))) else {
            Logger.error("Failed to parse engine move: \(uciMove)", category: Logger.game)
            return
        }

        // Handle promotion piece if present
        let promotionPiece: PieceType? = {
            if uciMove.count == 5 {
                let promotionChar = uciMove.last!.lowercased()
                switch promotionChar {
                case "q": return .queen
                case "r": return .rook
                case "b": return .bishop
                case "n": return .knight
                default: return nil
                }
            }
            return nil
        }()

        // Execute the engine move
        Logger.debug("Executing engine move (will not trigger analysis)", category: Logger.game)
        isWaitingForEngineMove = true
        let success = executeMove(from: fromPos, to: toPos, promoteTo: promotionPiece)
        isWaitingForEngineMove = false

        if success {
            Logger.debug("Engine move executed successfully - no server analysis needed", category: Logger.game)
        } else {
            Logger.error("Failed to execute engine move", category: Logger.game)
        }
    }

    private func parseSquare(from uci: String) -> ChessPosition? {
        guard uci.count == 2,
              let file = uci.first?.asciiValue,
              let rank = uci.last?.wholeNumberValue else {
            return nil
        }

        let col = Int(file - 97) // 'a' = 97, so 'a' = 0, 'b' = 1, etc.
        let row = 8 - rank      // rank 1 = row 7, rank 8 = row 0

        guard col >= 0 && col < 8 && row >= 0 && row < 8 else {
            return nil
        }

        return ChessPosition(row: row, col: col)
    }

    private func convertMoveToAlgebraic(_ move: ChessMoveRecord, movingPlayer: ChessColor) -> String {
        // Convert internal move format to UCI notation
        // Your board setup: Row 0 = rank 8, Row 1 = rank 7, Row 6 = rank 2, Row 7 = rank 1
        // Col 0 = file a, Col 7 = file h

        let fromFile = Character(UnicodeScalar(97 + move.from.col)!) // a-h
        let fromRank = 8 - move.from.row // Convert: Row 0->8, Row 1->7, Row 6->2, Row 7->1
        let toFile = Character(UnicodeScalar(97 + move.to.col)!) // a-h
        let toRank = 8 - move.to.row

        let fromSquare = "\(fromFile)\(fromRank)"
        let toSquare = "\(toFile)\(toRank)"

        // Debug: Show the piece that moved (from move record)
        let pieceInfo = "\(move.piece.color) \(move.piece.type)"

        Logger.debug("Move conversion: (\(move.from.row),\(move.from.col)) -> (\(move.to.row),\(move.to.col)) = \(fromSquare)\(toSquare)", category: Logger.game)
        Logger.debug("Piece moved: \(pieceInfo), Moving player: \(movingPlayer)", category: Logger.game)

        return "\(fromSquare)\(toSquare)"
    }

    func testAPIConnection() async -> Bool {
        return await chessCoachAPI.testConnection()
    }

    // MARK: - Settings Refresh

    func refreshSettings() {
        // Reload settings from UserDefaults
        if let savedLevel = UserDefaults.standard.string(forKey: "ChessCoach.defaultSkillLevel"),
           let level = SkillLevel(rawValue: savedLevel) {
            skillLevel = level
        }

        isDebugMode = UserDefaults.standard.bool(forKey: "ChessCoach.shouldShowHistory")
    }
}

struct ChessPosition: Equatable {
    let row: Int
    let col: Int
}

struct ChessPiece {
    let type: PieceType
    let color: ChessColor
    
    init(_ type: PieceType, _ color: ChessColor) {
        self.type = type
        self.color = color
    }
}

enum PieceType: String, CaseIterable {
    case pawn, rook, knight, bishop, queen, king
    
    func symbol(for color: ChessColor) -> String {
        switch (self, color) {
        case (.pawn, .white): return "♙"
        case (.pawn, .black): return "♟︎"
        case (.rook, .white): return "♖"
        case (.rook, .black): return "♜"
        case (.knight, .white): return "♘"
        case (.knight, .black): return "♞"
        case (.bishop, .white): return "♗"
        case (.bishop, .black): return "♝︎"
        case (.queen, .white): return "♕"
        case (.queen, .black): return "♛︎"
        case (.king, .white): return "♔"
        case (.king, .black): return "♚︎"
        }
    }
}

enum ChessColor: String, CaseIterable {
    case white, black
    
    var displayName: String {
        rawValue.capitalized
    }
}

enum GameStatus {
    case inProgress
    case checkmate(winner: ChessColor)
    case stalemate
    case draw
}

struct CastlingRights {
    private var rights: [ChessColor: [Bool]] = [
        .white: [true, true], // [kingside, queenside]
        .black: [true, true]
    ]
    
    mutating func disableKingMoved(_ color: ChessColor) {
        rights[color] = [false, false]
    }
    
    mutating func disableRookMoved(_ color: ChessColor, kingSide: Bool) {
        let index = kingSide ? 0 : 1
        rights[color]?[index] = false
    }
    
    func canCastle(_ color: ChessColor, kingSide: Bool) -> Bool {
        let index = kingSide ? 0 : 1
        return rights[color]?[index] ?? false
    }
}

