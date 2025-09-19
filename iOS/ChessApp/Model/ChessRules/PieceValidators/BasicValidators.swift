//
//  BasicValidators.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import Foundation

// MARK: - Rook Validator
class RookValidator: ChessValidator {
    func isValidMove(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> Bool {
        // Rook moves horizontally or vertically
        guard from.row == to.row || from.col == to.col else {
            return false
        }
        
        // Check if path is clear using shared utility
        return PathUtility.isPathClear(from: from, to: to, board: board)
    }
    
    func getLegalMoves(for position: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> [ChessPosition] {
        var moves: [ChessPosition] = []
        let directions = [(0, 1), (0, -1), (1, 0), (-1, 0)]
        
        for (rowDir, colDir) in directions {
            var currentRow = position.row + rowDir
            var currentCol = position.col + colDir
            
            while currentRow >= 0 && currentRow < 8 && currentCol >= 0 && currentCol < 8 {
                let targetPosition = ChessPosition(row: currentRow, col: currentCol)
                
                if let piece = board[currentRow][currentCol] {
                    // If enemy piece, can capture
                    if piece.color != board[position.row][position.col]?.color {
                        moves.append(targetPosition)
                    }
                    break
                } else {
                    moves.append(targetPosition)
                }
                
                currentRow += rowDir
                currentCol += colDir
            }
        }
        
        return moves
    }
}

// MARK: - Bishop Validator
class BishopValidator: ChessValidator {
    func isValidMove(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> Bool {
        let rowDiff = abs(to.row - from.row)
        let colDiff = abs(to.col - from.col)
        
        // Bishop moves diagonally
        guard rowDiff == colDiff else {
            return false
        }
        
        // Check if path is clear using shared utility
        return PathUtility.isPathClear(from: from, to: to, board: board)
    }
    
    func getLegalMoves(for position: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> [ChessPosition] {
        var moves: [ChessPosition] = []
        let directions = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
        
        for (rowDir, colDir) in directions {
            var currentRow = position.row + rowDir
            var currentCol = position.col + colDir
            
            while currentRow >= 0 && currentRow < 8 && currentCol >= 0 && currentCol < 8 {
                let targetPosition = ChessPosition(row: currentRow, col: currentCol)
                
                if let piece = board[currentRow][currentCol] {
                    // If enemy piece, can capture
                    if piece.color != board[position.row][position.col]?.color {
                        moves.append(targetPosition)
                    }
                    break
                } else {
                    moves.append(targetPosition)
                }
                
                currentRow += rowDir
                currentCol += colDir
            }
        }
        
        return moves
    }
}

// MARK: - Queen Validator
class QueenValidator: ChessValidator {
    private let rookValidator = RookValidator()
    private let bishopValidator = BishopValidator()
    
    func isValidMove(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> Bool {
        return rookValidator.isValidMove(from: from, to: to, board: board, gameState: gameState) ||
               bishopValidator.isValidMove(from: from, to: to, board: board, gameState: gameState)
    }
    
    func getLegalMoves(for position: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> [ChessPosition] {
        let rookMoves = rookValidator.getLegalMoves(for: position, board: board, gameState: gameState)
        let bishopMoves = bishopValidator.getLegalMoves(for: position, board: board, gameState: gameState)
        return rookMoves + bishopMoves
    }
}

// MARK: - Knight Validator
class KnightValidator: ChessValidator {
    func isValidMove(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> Bool {
        let rowDiff = abs(to.row - from.row)
        let colDiff = abs(to.col - from.col)
        
        // Knight moves in L-shape: 2 squares in one direction, 1 in perpendicular
        return (rowDiff == 2 && colDiff == 1) || (rowDiff == 1 && colDiff == 2)
    }
    
    func getLegalMoves(for position: ChessPosition, board: [[ChessPiece?]], gameState: ChessGameState) -> [ChessPosition] {
        var moves: [ChessPosition] = []
        let knightMoves = [(-2, -1), (-2, 1), (-1, -2), (-1, 2), (1, -2), (1, 2), (2, -1), (2, 1)]
        
        for (rowOffset, colOffset) in knightMoves {
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
        
        return moves
    }
}