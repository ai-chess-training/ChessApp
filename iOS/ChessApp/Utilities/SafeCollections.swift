//
//  SafeCollections.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import Foundation

// MARK: - Safe Array Extension
extension Array {
    /// Safe subscript that returns nil instead of crashing on out-of-bounds access
    subscript(safe index: Int) -> Element? {
        guard index >= 0, index < count else {
            return nil
        }
        return self[index]
    }
}

// MARK: - Safe 2D Array Extension
extension Array where Element == Array<ChessPiece?> {
    /// Safe subscript for 2D chess board access
    subscript(safe row: Int, safe col: Int) -> ChessPiece?? {
        guard row >= 0, row < count, col >= 0, col < self[row].count else {
            return nil
        }
        return self[row][col]
    }
}

// MARK: - Safe Collection Extension (for broader compatibility)
extension Collection {
    /// Safe subscript for any Collection type
    subscript(safe index: Index) -> Element? {
        guard indices.contains(index) else {
            return nil
        }
        return self[index]
    }
}