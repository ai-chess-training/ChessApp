//
//  GameManager.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import Observation
import Foundation

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

    // MARK: - Chess Coach API Integration

    var chessCoachAPI: ChessCoachAPI
    var isCoachingEnabled: Bool = false
    var currentMoveFeedback: MoveFeedback?
    var isAnalyzingMove: Bool = false
    var skillLevel: SkillLevel = .intermediate
    
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
        setupInitialBoard()
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

        // Start new coaching session if enabled
        if isCoachingEnabled {
            Task {
                await startNewCoachingSession()
            }
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
        
        print("Attempting move from (\(from.row), \(from.col)) to (\(to.row), \(to.col))")
        
        let validationResult = ruleEngine.canMovePiece(from: from, to: to, gameState: self)
        
        switch validationResult {
        case .valid:
            print("Move is valid, executing...")
            return executeMove(from: from, to: to)
        case .requiresPromotion(_):
            print("Pawn promotion required, showing UI")
            promotionMove = (from: from, to: to)
            showingPawnPromotion = true
            return true // Return true to indicate move handling is in progress
        case .invalid(let reason):
            print("Invalid move: \(reason)")
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
        
        // Switch players
        currentPlayer = currentPlayer == .white ? .black : .white
        
        // Check for game ending conditions
        updateGameStatus()

        // Analyze the move if coaching is enabled
        if isCoachingEnabled {
            Task {
                await analyzeLastMove()
            }
        }

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
        self.skillLevel = skillLevel
        isCoachingEnabled = true
        Task {
            await startNewCoachingSession()
        }
    }

    func disableCoaching() {
        isCoachingEnabled = false
        currentMoveFeedback = nil
    }

    @MainActor
    private func startNewCoachingSession() async {
        guard isCoachingEnabled else { return }

        do {
            let _ = try await chessCoachAPI.startNewGame(skillLevel: skillLevel)
            print("Started new coaching session with skill level: \(skillLevel.displayName)")
        } catch {
            print("Failed to start coaching session: \(error.localizedDescription)")
        }
    }

    func analyzeLastMove() async {
        guard isCoachingEnabled,
              let lastMoveRecord = moveHistoryManager.getLastMove(),
              !isAnalyzingMove else { return }

        await MainActor.run {
            isAnalyzingMove = true
        }

        do {
            // Convert move to algebraic notation
            let moveString = convertMoveToAlgebraic(lastMoveRecord)
            let analysis = try await chessCoachAPI.analyzeCurrentMove(moveString)

            await MainActor.run {
                currentMoveFeedback = analysis.humanFeedback
                isAnalyzingMove = false
            }

            print("Move analysis complete: \(analysis.humanFeedback?.basic ?? "No feedback")")

        } catch {
            await MainActor.run {
                isAnalyzingMove = false
            }
            print("Failed to analyze move: \(error.localizedDescription)")
        }
    }

    private func convertMoveToAlgebraic(_ move: ChessMoveRecord) -> String {
        // Convert internal move format to algebraic notation
        // For now, return a basic format - this should be improved based on your move record structure
        let fromSquare = "\(Character(UnicodeScalar(97 + move.from.col)!))\(8 - move.from.row)"
        let toSquare = "\(Character(UnicodeScalar(97 + move.to.col)!))\(8 - move.to.row)"
        return "\(fromSquare)\(toSquare)"
    }

    func testAPIConnection() async -> Bool {
        return await chessCoachAPI.testConnection()
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

