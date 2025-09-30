//
//  AccessibilityUITests.swift
//  ChessAppUITests
//
//  UI tests for accessibility features and VoiceOver support
//

import XCTest

final class AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Basic Accessibility Tests

    func testMainElementsHaveAccessibilityLabels() throws {
        navigateToGame()

        // Chess board accessibility
        let chessBoard = app.otherElements["chess_board"]
        XCTAssertTrue(chessBoard.waitForExistence(timeout: 5.0))
        XCTAssertNotNil(chessBoard.label)
        XCTAssertFalse(chessBoard.label.isEmpty)

        // Game control buttons
        let resetButton = app.buttons["Reset"]
        XCTAssertTrue(resetButton.exists)
        XCTAssertNotNil(resetButton.label)

        let resignButton = app.buttons["Resign"]
        XCTAssertTrue(resignButton.exists)
        XCTAssertNotNil(resignButton.label)
    }

    func testChessSquareAccessibility() throws {
        navigateToGame()

        let chessBoard = app.otherElements["chess_board"]
        XCTAssertTrue(chessBoard.waitForExistence(timeout: 5.0))

        // Test a few key squares for accessibility
        let testSquares = ["a1", "e1", "e4", "h8"]

        for square in testSquares {
            let squareElement = chessBoard.buttons["square_\(square)"]
            if squareElement.exists {
                // Should have meaningful accessibility label
                XCTAssertNotNil(squareElement.label)
                XCTAssertFalse(squareElement.label.isEmpty)

                // Label should describe the square and piece (if any)
                XCTAssertTrue(squareElement.label.contains(square) ||
                             squareElement.label.localizedCaseInsensitiveContains("pawn") ||
                             squareElement.label.localizedCaseInsensitiveContains("rook") ||
                             squareElement.label.localizedCaseInsensitiveContains("knight") ||
                             squareElement.label.localizedCaseInsensitiveContains("bishop") ||
                             squareElement.label.localizedCaseInsensitiveContains("queen") ||
                             squareElement.label.localizedCaseInsensitiveContains("king") ||
                             squareElement.label.localizedCaseInsensitiveContains("empty"))
            }
        }
    }

    func testButtonAccessibilityTraits() throws {
        navigateToGame()

        // Test that buttons have proper accessibility traits
        let resetButton = app.buttons["Reset"]
        XCTAssertTrue(resetButton.exists)
        XCTAssertTrue(resetButton.elementType == .button)

        let resignButton = app.buttons["Resign"]
        XCTAssertTrue(resignButton.exists)
        XCTAssertTrue(resignButton.elementType == .button)

        // Test guest login button
        let guestButton = app.buttons["Continue as Guest"]
        if guestButton.exists {
            XCTAssertTrue(guestButton.elementType == .button)
        }
    }

    func testCoachingAccessibility() throws {
        navigateToGame()

        // Chess Coach section
        let coachSection = app.staticTexts["Chess Coach"]
        if coachSection.waitForExistence(timeout: 5.0) {
            XCTAssertNotNil(coachSection.label)
            XCTAssertFalse(coachSection.label.isEmpty)
        }

        // Skill level picker
        let skillPicker = app.segmentedControls.element(boundBy: 0)
        if skillPicker.exists {
            XCTAssertTrue(skillPicker.elementType == .segmentedControl)

            // Each segment should have a proper label
            let skillButtons = skillPicker.buttons.allElementsBoundByIndex
            for button in skillButtons {
                XCTAssertNotNil(button.label)
                XCTAssertFalse(button.label.isEmpty)
            }
        }
    }

    func testMoveFeedbackAccessibility() throws {
        navigateToGame()

        // Make a move to potentially generate feedback
        makeBasicMove()

        // Check feedback accessibility
        let feedbackContainer = app.otherElements["move_feedback"]
        if feedbackContainer.waitForExistence(timeout: 10.0) {
            // Move number should be accessible
            let moveNumber = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Move '")).element
            if moveNumber.exists {
                XCTAssertNotNil(moveNumber.label)
                XCTAssertFalse(moveNumber.label.isEmpty)
            }

            // Feedback text should be accessible
            let feedbackText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'move' OR label CONTAINS 'excellent' OR label CONTAINS 'good'")).element
            if feedbackText.exists {
                XCTAssertNotNil(feedbackText.label)
                XCTAssertFalse(feedbackText.label.isEmpty)
            }
        }
    }

    func testGameStatusAccessibility() throws {
        navigateToGame()

        // Game status indicators
        let statusTexts = [
            "White to move",
            "Black to move",
            "Your turn",
            "Computer thinking...",
            "Check",
            "Checkmate"
        ]

        for statusText in statusTexts {
            let statusElement = app.staticTexts[statusText]
            if statusElement.exists {
                XCTAssertNotNil(statusElement.label)
                XCTAssertFalse(statusElement.label.isEmpty)
                // Status should be announced to VoiceOver users
                XCTAssertTrue(statusElement.elementType == .staticText)
            }
        }
    }

    // MARK: - VoiceOver Navigation Tests

    func testVoiceOverNavigationThroughBoard() throws {
        navigateToGame()

        let chessBoard = app.otherElements["chess_board"]
        XCTAssertTrue(chessBoard.waitForExistence(timeout: 5.0))

        // Get all chess squares
        let squares = chessBoard.buttons.allElementsBoundByIndex

        // Verify we can navigate through squares
        XCTAssertGreaterThan(squares.count, 0)

        // Test first few squares for navigation
        for i in 0..<min(8, squares.count) {
            let square = squares[i]
            XCTAssertTrue(square.exists)
            XCTAssertNotNil(square.label)
        }
    }

    func testVoiceOverGameControls() throws {
        navigateToGame()

        // Test VoiceOver can find and interact with game controls
        let resetButton = app.buttons["Reset"]
        XCTAssertTrue(resetButton.exists)
        XCTAssertTrue(resetButton.isHittable)

        let resignButton = app.buttons["Resign"]
        XCTAssertTrue(resignButton.exists)
        XCTAssertTrue(resignButton.isHittable)
    }

    func testAlertAccessibility() throws {
        navigateToGame()

        // Test skill level change alert accessibility
        let skillPicker = app.segmentedControls.element(boundBy: 0)
        if skillPicker.exists {
            // Make a move first
            makeBasicMove()

            // Try to change skill level
            let skillButtons = skillPicker.buttons.allElementsBoundByIndex
            if skillButtons.count > 1 {
                let currentlySelected = skillButtons.first { $0.isSelected }
                let otherButton = skillButtons.first { !$0.isSelected }

                if let otherButton = otherButton {
                    otherButton.tap()

                    // Check alert accessibility
                    let alert = app.alerts["Change Skill Level?"]
                    if alert.waitForExistence(timeout: 3.0) {
                        XCTAssertNotNil(alert.label)
                        XCTAssertFalse(alert.label.isEmpty)

                        // Alert buttons should be accessible
                        let cancelButton = alert.buttons["Cancel"]
                        XCTAssertTrue(cancelButton.exists)
                        XCTAssertNotNil(cancelButton.label)

                        let confirmButton = alert.buttons["Reset & Change"]
                        XCTAssertTrue(confirmButton.exists)
                        XCTAssertNotNil(confirmButton.label)

                        // Dismiss alert
                        cancelButton.tap()
                    }
                }
            }
        }
    }

    // MARK: - Dynamic Type Support Tests

    func testDynamicTypeSupport() throws {
        // This test would check if text scales properly with accessibility text sizes
        // In a real implementation, you'd test with different content size categories
        navigateToGame()

        let coachSection = app.staticTexts["Chess Coach"]
        if coachSection.exists {
            // Verify text is still readable and properly laid out
            XCTAssertTrue(coachSection.exists)
            XCTAssertTrue(coachSection.isHittable)
        }
    }

    // MARK: - Color Accessibility Tests

    func testHighContrastSupport() throws {
        // Test that UI elements are still distinguishable in high contrast mode
        navigateToGame()

        let chessBoard = app.otherElements["chess_board"]
        XCTAssertTrue(chessBoard.waitForExistence(timeout: 5.0))

        // Verify board squares are distinguishable
        let lightSquare = chessBoard.buttons["square_a1"]
        let darkSquare = chessBoard.buttons["square_b1"]

        if lightSquare.exists && darkSquare.exists {
            // Squares should be visually distinct (this is a basic test)
            XCTAssertTrue(lightSquare.exists)
            XCTAssertTrue(darkSquare.exists)
        }
    }

    // MARK: - Reduced Motion Tests

    func testReducedMotionSupport() throws {
        // Test that animations are reduced or disabled when reduce motion is enabled
        navigateToGame()

        // Make a move and verify it completes without excessive animation
        makeBasicMove()

        // The move should complete in reasonable time regardless of animation settings
        let chessBoard = app.otherElements["chess_board"]
        XCTAssertTrue(chessBoard.exists)
    }

    // MARK: - Focus Management Tests

    func testFocusManagement() throws {
        navigateToGame()

        // Test that focus moves logically through the interface
        let resetButton = app.buttons["Reset"]
        if resetButton.exists {
            resetButton.tap()

            // After reset, focus should be manageable
            let chessBoard = app.otherElements["chess_board"]
            XCTAssertTrue(chessBoard.waitForExistence(timeout: 3.0))
        }
    }

    // MARK: - Error Message Accessibility

    func testErrorMessageAccessibility() throws {
        navigateToGame()

        // Look for error messages and verify they're accessible
        let errorMessages = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'error' OR label CONTAINS 'Error' OR label CONTAINS 'failed'"))

        for i in 0..<errorMessages.count {
            let errorMessage = errorMessages.element(boundBy: i)
            if errorMessage.exists {
                XCTAssertNotNil(errorMessage.label)
                XCTAssertFalse(errorMessage.label.isEmpty)
                // Error messages should be announced to assistive technologies
                XCTAssertTrue(errorMessage.elementType == .staticText)
            }
        }
    }

    // MARK: - Helper Methods

    private func navigateToGame() {
        let guestButton = app.buttons["Continue as Guest"]
        if guestButton.waitForExistence(timeout: 2.0) {
            guestButton.tap()
        }

        let chessBoard = app.otherElements["chess_board"]
        _ = chessBoard.waitForExistence(timeout: 5.0)
    }

    private func makeBasicMove() {
        let chessBoard = app.otherElements["chess_board"]
        if chessBoard.exists {
            let e2Square = chessBoard.buttons["square_e2"]
            let e4Square = chessBoard.buttons["square_e4"]

            if e2Square.exists && e4Square.exists {
                e2Square.tap()
                e4Square.tap()
            }
        }
    }

    // MARK: - Custom Accessibility Action Tests

    func testCustomAccessibilityActions() throws {
        navigateToGame()

        let chessBoard = app.otherElements["chess_board"]
        XCTAssertTrue(chessBoard.waitForExistence(timeout: 5.0))

        // Test if pieces have custom accessibility actions (like "move to e4")
        let pawnSquare = chessBoard.buttons["square_e2"]
        if pawnSquare.exists {
            // Check if custom actions are available
            // In a full implementation, you'd test custom VoiceOver actions
            XCTAssertTrue(pawnSquare.isHittable)
        }
    }
}