//
//  KingValidator.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import Foundation

class KingValidator: ChessValidator {
    func isValidMove(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> Bool {
        let rowDiff = abs(to.row - from.row)
        let colDiff = abs(to.col - from.col)
        
        // Regular king move (one square in any direction)
        if rowDiff <= 1 && colDiff <= 1 {
            return true
        }
        
        // Castling move
        if rowDiff == 0 && colDiff == 2 {
            return isValidCastling(from: from, to: to, board: board, gameState: gameState)
        }
        
        return false
    }
    
    func getLegalMoves(for position: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> [ChessPosition] {
        var moves: [ChessPosition] = []
        
        // Regular king moves (one square in any direction)
        for rowOffset in -1...1 {
            for colOffset in -1...1 {
                if rowOffset == 0 && colOffset == 0 { continue }
                
                let newRow = position.row + rowOffset
                let newCol = position.col + colOffset
                
                if newRow >= 0 && newRow < 8 && newCol >= 0 && newCol < 8 {
                    let targetPosition = ChessPosition(row: newRow, col: newCol)
                    
                    // Can move to empty square or capture enemy piece
                    if let piece = board[newRow][newCol] {
                        if piece.color != board[position.row][position.col]?.color {
                            moves.append(targetPosition)
                        }
                    } else {
                        moves.append(targetPosition)
                    }
                }
            }
        }
        
        // Castling moves
        // Kingside castling
        let kingsideCastle = ChessPosition(row: position.row, col: position.col + 2)
        if isValidCastling(from: position, to: kingsideCastle, board: board, gameState: gameState) {
            moves.append(kingsideCastle)
        }
        
        // Queenside castling
        let queensideCastle = ChessPosition(row: position.row, col: position.col - 2)
        if isValidCastling(from: position, to: queensideCastle, board: board, gameState: gameState) {
            moves.append(queensideCastle)
        }
        
        return moves
    }
    
    private func isValidCastling(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> Bool {
        guard let king = board[from.row][from.col] else { return false }
        
        let color = king.color
        let isKingSide = to.col > from.col
        
        // Check castling rights
        guard gameState.castlingRights.canCastle(color, kingSide: isKingSide) else {
            return false
        }
        
        // King must not be in check
        if gameState.isKingInCheck(color: color) {
            return false
        }
        
        // Determine rook position
        let rookCol = isKingSide ? 7 : 0
        let rookPosition = ChessPosition(row: from.row, col: rookCol)
        
        // Check if rook is present
        guard let rook = board[rookPosition.row][rookPosition.col],
              rook.type == .rook, rook.color == color else {
            return false
        }
        
        // Check path between king and rook is clear
        let startCol = min(from.col, rookCol) + 1
        let endCol = max(from.col, rookCol) - 1
        for col in startCol...endCol {
            if board[from.row][col] != nil {
                return false
            }
        }
        
        // Check that king doesn't pass through check
        let direction = isKingSide ? 1 : -1
        for step in 1...2 {
            let checkPosition = ChessPosition(row: from.row, col: from.col + step * direction)
            
            // Simulate king at this position
            var tempBoard = board
            tempBoard[from.row][from.col] = nil
            tempBoard[checkPosition.row][checkPosition.col] = king
            
            // Use rule engine to check if this position is attacked
            if gameState.ruleEngine?.isKingInCheck(color: color, board: tempBoard) == true {
                return false
            }
        }
        
        return true
    }
}