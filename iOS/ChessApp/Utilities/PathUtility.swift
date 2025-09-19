//
//  PathUtility.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/9/25.
//

import Foundation

struct PathUtility {
    static func isPathClear(from: ChessPosition, to: ChessPosition, board: [[ChessPiece?]]) -> Bool {
        let rowDiff = to.row - from.row
        let colDiff = to.col - from.col
        
        let rowStep = rowDiff == 0 ? 0 : (rowDiff > 0 ? 1 : -1)
        let colStep = colDiff == 0 ? 0 : (colDiff > 0 ? 1 : -1)
        
        var currentRow = from.row + rowStep
        var currentCol = from.col + colStep
        
        while currentRow != to.row || currentCol != to.col {
            // Safety check for array bounds
            guard currentRow >= 0 && currentRow < 8 && currentCol >= 0 && currentCol < 8 else {
                return false
            }
            
            if board[currentRow][currentCol] != nil {
                return false
            }
            currentRow += rowStep
            currentCol += colStep
        }
        
        return true
    }
}