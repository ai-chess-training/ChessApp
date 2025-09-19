//
//  ChessRuleEngine.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import Foundation

// MARK: - Move Validation Result
enum MoveValidationResult {
    case valid
    case invalid(reason: String)
    case requiresPromotion(availablePieces: [PieceType])
}

// MARK: - Chess Move
struct ChessMove {
    let from: ChessPosition
    let to: ChessPosition
    let piece: ChessPiece
    let capturedPiece: ChessPiece?
    let isPromotion: Bool
    let promotionPiece: PieceType?
    let isCastling: Bool
    let isEnPassant: Bool
    
    init(from: ChessPosition, to: ChessPosition, piece: ChessPiece, capturedPiece: ChessPiece? = nil, 
         isPromotion: Bool = false, promotionPiece: PieceType? = nil, 
         isCastling: Bool = false, isEnPassant: Bool = false) {
        self.from = from
        self.to = to
        self.piece = piece
        self.capturedPiece = capturedPiece
        self.isPromotion = isPromotion
        self.promotionPiece = promotionPiece
        self.isCastling = isCastling
        self.isEnPassant = isEnPassant
    }
}

// MARK: - Chess Validator Protocol
protocol ChessValidator {
    func isValidMove(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> Bool
    func getLegalMoves(for position: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> [ChessPosition]
}

// MARK: - Chess Rule Engine
class ChessRuleEngine {
    private var validators: [PieceType: ChessValidator] = [:]
    
    init() {
        setupValidators()
    }
    
    private func setupValidators() {
        validators[.rook] = RookValidator()
        validators[.bishop] = BishopValidator()
        validators[.queen] = QueenValidator()
        validators[.knight] = KnightValidator()
        validators[.pawn] = PawnValidator()
        validators[.king] = KingValidator()
    }
    
    // MARK: - Main Validation Methods
    
    func canMovePiece(from: ChessPosition, to: ChessPosition, gameState: ChessGameState) -> MoveValidationResult {
        guard isValidBoardPosition(from) && isValidBoardPosition(to) else {
            return .invalid(reason: "Invalid board position")
        }
        
        guard let piece = gameState.board[from.row][from.col] else {
            return .invalid(reason: "No piece at starting position")
        }
        
        guard piece.color == gameState.currentPlayer else {
            return .invalid(reason: "Not your piece")
        }
        
        guard from != to else {
            return .invalid(reason: "Cannot move to same position")
        }
        
        let destinationPiece = gameState.board[to.row][to.col]
        if let destPiece = destinationPiece, destPiece.color == piece.color {
            return .invalid(reason: "Cannot capture your own piece")
        }
        
        guard let validator = validators[piece.type] else {
            return .invalid(reason: "No validator for piece type")
        }
        
        guard validator.isValidMove(from: from, to: to, board: gameState.board, gameState: gameState) else {
            return .invalid(reason: "Invalid move for this piece")
        }
        
        // Detect special moves
        let isCastling = piece.type == .king && abs(to.col - from.col) == 2
        let isEnPassant = isEnPassantMove(from: from, to: to, piece: piece, gameState: gameState)
        
        // Check if move would leave own king in check
        if wouldLeaveKingInCheck(move: ChessMove(from: from, to: to, piece: piece, capturedPiece: destinationPiece, isCastling: isCastling, isEnPassant: isEnPassant), gameState: gameState) {
            return .invalid(reason: "Move would leave king in check")
        }
        
        // Check for pawn promotion
        if piece.type == .pawn && isPawnPromotionMove(from: from, to: to, piece: piece) {
            return .requiresPromotion(availablePieces: [.queen, .rook, .bishop, .knight])
        }
        
        return .valid
    }
    
    func getAvailableMoves(for position: ChessPosition, gameState: ChessGameState) -> [ChessPosition] {
        guard isValidBoardPosition(position),
              let piece = gameState.board[position.row][position.col],
              piece.color == gameState.currentPlayer,
              let validator = validators[piece.type] else {
            print("Failed to get piece or validator at position (\(position.row), \(position.col))")
            return []
        }
        
        print("Getting moves for \(piece.color) \(piece.type) at (\(position.row), \(position.col))")
        
        let potentialMoves = validator.getLegalMoves(for: position, board: gameState.board, gameState: gameState)
        print("Potential moves: \(potentialMoves.count)")
        
        // Filter out moves that would leave king in check
        let filteredMoves = potentialMoves.filter { to in
            let destinationPiece = gameState.board[to.row][to.col]
            let move = ChessMove(from: position, to: to, piece: piece, capturedPiece: destinationPiece)
            let wouldLeaveInCheck = wouldLeaveKingInCheck(move: move, gameState: gameState)
            if wouldLeaveInCheck {
                print("Move to (\(to.row), \(to.col)) would leave king in check")
            }
            return !wouldLeaveInCheck
        }
        
        print("Final available moves: \(filteredMoves.count)")
        return filteredMoves
    }
    
    // MARK: - Check Detection
    
    func isKingInCheck(color: ChessColor, board: [[ChessPiece?]]) -> Bool {
        guard let kingPosition = findKing(color: color, board: board) else {
            return false
        }
        
        return isSquareAttacked(position: kingPosition, by: color.opposite, board: board)
    }
    
    func isKingInCheck(color: ChessColor, gameState: ChessGameState) -> Bool {
        let kingPosition = gameState.getKingPosition(color: color)
        return isSquareAttacked(position: kingPosition, by: color.opposite, board: gameState.board)
    }
    
    func isCheckmate(color: ChessColor, gameState: ChessGameState) -> Bool {
        guard isKingInCheck(color: color, gameState: gameState) else {
            return false
        }
        
        // Check if any piece of this color has legal moves
        for row in 0..<8 {
            for col in 0..<8 {
                let position = ChessPosition(row: row, col: col)
                if let piece = gameState.board[row][col], piece.color == color {
                    let availableMoves = getAvailableMoves(for: position, gameState: gameState)
                    if !availableMoves.isEmpty {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    func isStalemate(color: ChessColor, gameState: ChessGameState) -> Bool {
        guard !isKingInCheck(color: color, gameState: gameState) else {
            return false
        }
        
        // Check if any piece of this color has legal moves
        for row in 0..<8 {
            for col in 0..<8 {
                let position = ChessPosition(row: row, col: col)
                if let piece = gameState.board[row][col], piece.color == color {
                    let availableMoves = getAvailableMoves(for: position, gameState: gameState)
                    if !availableMoves.isEmpty {
                        return false
                    }
                }
            }
        }
        
        return true
    }
    
    // MARK: - Utility Methods
    
    func isValidBoardPosition(_ position: ChessPosition) -> Bool {
        return position.row >= 0 && position.row < 8 && position.col >= 0 && position.col < 8
    }
    
    
    private func findKing(color: ChessColor, board: [[ChessPiece?]]) -> ChessPosition? {
        for row in 0..<8 {
            for col in 0..<8 {
                if let piece = board[row][col], piece.type == .king && piece.color == color {
                    return ChessPosition(row: row, col: col)
                }
            }
        }
        return nil
    }
    
    private func isSquareAttacked(position: ChessPosition, by color: ChessColor, board: [[ChessPiece?]]) -> Bool {
        for row in 0..<8 {
            for col in 0..<8 {
                let attackerPosition = ChessPosition(row: row, col: col)
                if let piece = board[row][col], piece.color == color {
                    if canPieceAttack(piece: piece, from: attackerPosition, to: position, board: board) {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    private func canPieceAttack(piece: ChessPiece, from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]]) -> Bool {
        switch piece.type {
        case .pawn:
            return canPawnAttack(from: from, to: to, color: piece.color)
        case .rook:
            return canRookAttack(from: from, to: to, board: board)
        case .bishop:
            return canBishopAttack(from: from, to: to, board: board)
        case .queen:
            return canRookAttack(from: from, to: to, board: board) || canBishopAttack(from: from, to: to, board: board)
        case .knight:
            return canKnightAttack(from: from, to: to)
        case .king:
            return canKingAttack(from: from, to: to)
        }
    }
    
    private func canPawnAttack(from: ChessPosition, to: ChessPosition, color: ChessColor) -> Bool {
        let direction = color == .white ? -1 : 1
        let rowDiff = to.row - from.row
        let colDiff = abs(to.col - from.col)
        return rowDiff == direction && colDiff == 1
    }
    
    private func canRookAttack(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]]) -> Bool {
        guard from.row == to.row || from.col == to.col else { return false }
        return PathUtility.isPathClear(from: from, to: to, board: board)
    }
    
    private func canBishopAttack(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]]) -> Bool {
        let rowDiff = abs(to.row - from.row)
        let colDiff = abs(to.col - from.col)
        guard rowDiff == colDiff else { return false }
        return PathUtility.isPathClear(from: from, to: to, board: board)
    }
    
    private func canKnightAttack(from: ChessPosition, to: ChessPosition) -> Bool {
        let rowDiff = abs(to.row - from.row)
        let colDiff = abs(to.col - from.col)
        return (rowDiff == 2 && colDiff == 1) || (rowDiff == 1 && colDiff == 2)
    }
    
    private func canKingAttack(from: ChessPosition, to: ChessPosition) -> Bool {
        let rowDiff = abs(to.row - from.row)
        let colDiff = abs(to.col - from.col)
        return rowDiff <= 1 && colDiff <= 1 && (rowDiff > 0 || colDiff > 0)
    }
    
    private func wouldLeaveKingInCheck(move: ChessMove, gameState: ChessGameState) -> Bool {
        // Simulate the move
        var tempBoard = gameState.board
        tempBoard[move.to.row][move.to.col] = move.piece
        tempBoard[move.from.row][move.from.col] = nil
        
        // Handle en passant capture
        if move.isEnPassant {
            let capturedPawnRow = move.piece.color == .white ? move.to.row + 1 : move.to.row - 1
            tempBoard[capturedPawnRow][move.to.col] = nil
        }
        
        return isKingInCheck(color: move.piece.color, board: tempBoard)
    }
    
    private func isPawnPromotionMove(from: ChessPosition, to: ChessPosition, piece: ChessPiece) -> Bool {
        guard piece.type == .pawn else { return false }
        
        let promotionRow = piece.color == .white ? 0 : 7
        return to.row == promotionRow
    }
    
    private func isEnPassantMove(from: ChessPosition, to: ChessPosition, piece: ChessPiece, gameState: ChessGameState) -> Bool {
        guard piece.type == .pawn else { return false }
        guard let enPassantTarget = gameState.enPassantTarget else { return false }
        
        return to == enPassantTarget
    }
    
}

// MARK: - ChessColor Extension
extension ChessColor {
    var opposite: ChessColor {
        return self == .white ? .black : .white
    }
}