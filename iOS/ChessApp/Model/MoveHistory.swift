//
//  MoveHistory.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import Foundation

// MARK: - Chess Move History
struct ChessMoveRecord {
    let from: ChessPosition
    let to: ChessPosition
    let piece: ChessPiece
    let capturedPiece: ChessPiece?
    let promotionPiece: PieceType?
    let moveNumber: Int
    let algebraicNotation: String
    let isCastling: Bool
    
    // Game state before the move (for undo)
    let previousGameStatus: GameStatus
    let wasKingInCheck: Bool
    let previousCastlingRights: CastlingRights
    let previousEnPassantTarget: ChessPosition?
    
    init(from: ChessPosition, to: ChessPosition, piece: ChessPiece, 
         capturedPiece: ChessPiece? = nil, promotionPiece: PieceType? = nil,
         moveNumber: Int, previousGameStatus: GameStatus = .inProgress, 
         wasKingInCheck: Bool = false, previousCastlingRights: CastlingRights,
         previousEnPassantTarget: ChessPosition? = nil) {
        self.from = from
        self.to = to
        self.piece = piece
        self.capturedPiece = capturedPiece
        self.promotionPiece = promotionPiece
        self.moveNumber = moveNumber
        self.previousGameStatus = previousGameStatus
        self.wasKingInCheck = wasKingInCheck
        self.previousCastlingRights = previousCastlingRights
        self.previousEnPassantTarget = previousEnPassantTarget
        self.isCastling = piece.type == .king && abs(to.col - from.col) == 2
        self.algebraicNotation = Self.generateAlgebraicNotation(
            from: from, to: to, piece: piece, 
            capturedPiece: capturedPiece, promotionPiece: promotionPiece,
            isCastling: self.isCastling
        )
    }
    
    private static func generateAlgebraicNotation(
        from: ChessPosition, to: ChessPosition, piece: ChessPiece,
        capturedPiece: ChessPiece?, promotionPiece: PieceType?,
        isCastling: Bool
    ) -> String {
        // Handle castling notation first
        if isCastling {
            let isKingSide = to.col > from.col
            return isKingSide ? "O-O" : "O-O-O"
        }
        
        let files = ["a", "b", "c", "d", "e", "f", "g", "h"]
        let ranks = ["8", "7", "6", "5", "4", "3", "2", "1"]
        
        let toSquare = "\(files[to.col])\(ranks[to.row])"
        
        var notation = ""
        
        // Piece symbol (except for pawns)
        if piece.type != .pawn {
            notation += piece.type.rawValue.uppercased().prefix(1)
        }
        
        // Capture notation
        if capturedPiece != nil {
            if piece.type == .pawn {
                notation += files[from.col]
            }
            notation += "x"
        }
        
        // Destination square
        notation += toSquare
        
        // Promotion
        if let promotion = promotionPiece {
            notation += "=\(promotion.rawValue.uppercased().prefix(1))"
        }
        
        return notation
    }
}

// MARK: - Move History Manager
class MoveHistoryManager {
    private(set) var moves: [ChessMoveRecord] = []
    private(set) var currentMoveNumber = 1
    
    func addMove(_ move: ChessMoveRecord) {
        moves.append(move)
        if move.piece.color == .black {
            currentMoveNumber += 1
        }
    }
    
    func getLastMove() -> ChessMoveRecord? {
        return moves.last
    }
    
    func undoLastMove() -> ChessMoveRecord? {
        guard !moves.isEmpty else { return nil }
        let lastMove = moves.removeLast()
        if lastMove.piece.color == .black {
            currentMoveNumber -= 1
        }
        return lastMove
    }
    
    func clear() {
        moves.removeAll()
        currentMoveNumber = 1
    }
    
    func getAlgebraicMoves() -> [String] {
        return moves.map { $0.algebraicNotation }
    }
}
