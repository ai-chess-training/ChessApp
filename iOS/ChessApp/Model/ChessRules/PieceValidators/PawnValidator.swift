//
//  PawnValidator.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import Foundation

class PawnValidator: ChessValidator {
    func isValidMove(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> Bool {
        guard let pawn = board[from.row][from.col] else { return false }
        
        let direction = pawn.color == .white ? -1 : 1
        let startingRow = pawn.color == .white ? 6 : 1
        let rowDiff = to.row - from.row
        let colDiff = abs(to.col - from.col)
        
        // Forward move
        if colDiff == 0 {
            // Single step forward
            if rowDiff == direction {
                return board[to.row][to.col] == nil
            }
            // Double step from starting position
            if rowDiff == direction * 2 && from.row == startingRow {
                return board[to.row][to.col] == nil && board[from.row + direction][from.col] == nil
            }
        }
        // Diagonal capture
        else if colDiff == 1 && rowDiff == direction {
            if let targetPiece = board[to.row][to.col] {
                return targetPiece.color != pawn.color
            }
            // En passant capture
            return isEnPassantCapture(from: from, to: to, gameState: gameState)
        }
        
        return false
    }
    
    func getLegalMoves(for position: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> [ChessPosition] {
        var moves: [ChessPosition] = []
        
        guard let pawn = board[position.row][position.col] else { return moves }
        
        let direction = pawn.color == .white ? -1 : 1
        let startingRow = pawn.color == .white ? 6 : 1
        
        // Forward moves
        let oneStep = ChessPosition(row: position.row + direction, col: position.col)
        if oneStep.row >= 0 && oneStep.row < 8 && board[oneStep.row][oneStep.col] == nil {
            moves.append(oneStep)
            
            // Double step from starting position
            if position.row == startingRow {
                let twoStep = ChessPosition(row: position.row + direction * 2, col: position.col)
                if twoStep.row >= 0 && twoStep.row < 8 && board[twoStep.row][twoStep.col] == nil {
                    moves.append(twoStep)
                }
            }
        }
        
        // Diagonal captures
        for colOffset in [-1, 1] {
            let newCol = position.col + colOffset
            if newCol >= 0 && newCol < 8 {
                let capturePos = ChessPosition(row: position.row + direction, col: newCol)
                if capturePos.row >= 0 && capturePos.row < 8 {
                    // Regular capture
                    if let targetPiece = board[capturePos.row][capturePos.col],
                       targetPiece.color != pawn.color {
                        moves.append(capturePos)
                    }
                    // En passant capture
                    else if isEnPassantCapture(from: position, to: capturePos, gameState: gameState) {
                        moves.append(capturePos)
                    }
                }
            }
        }
        
        return moves
    }
    
    private func isEnPassantCapture(from: ChessPosition, to: ChessPosition, gameState: ChessGameState) -> Bool {
        guard let enPassantTarget = gameState.enPassantTarget else { return false }
        guard let pawn = gameState.pieceAt(from) else { return false }
        
        // Must be capturing on the en passant target square
        guard to == enPassantTarget else { return false }
        
        // Verify we're on the correct rank for en passant
        let enPassantRank = pawn.color == .white ? 3 : 4
        guard from.row == enPassantRank else { return false }
        
        // Verify there's an enemy pawn next to us that just moved two squares
        let enemyPawnPosition = ChessPosition(row: from.row, col: to.col)
        guard let enemyPawn = gameState.pieceAt(enemyPawnPosition) else { return false }
        guard enemyPawn.type == .pawn && enemyPawn.color != pawn.color else { return false }
        
        return true
    }
}