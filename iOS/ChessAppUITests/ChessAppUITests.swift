//
//  ChessAppUITests.swift
//  ChessAppUITests
//
//  Main UI test suite for Chess App
//

import XCTest

final class ChessAppUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch and Authentication Tests

    func testAppLaunch() throws {
        XCTAssertTrue(app.staticTexts["Chess Training"].exists)
    }

    func testGuestLoginFlow() throws {
        let guestButton = app.buttons["Continue as Guest"]
        XCTAssertTrue(guestButton.exists)

        guestButton.tap()

        // Verify we reach the main game screen
        XCTAssertTrue(app.staticTexts["Chess Training"].waitForExistence(timeout: 3.0))
    }

    func testAppleSignInButtonExists() throws {
        let appleSignInButton = app.buttons["Sign in with Apple"]
        XCTAssertTrue(appleSignInButton.exists)
        XCTAssertTrue(appleSignInButton.isEnabled)
    }

    // MARK: - Chess Board Tests

    func testChessBoardInitialState() throws {
        // Navigate to game if needed
        navigateToGame()

        // Verify chess board exists
        let chessBoard = app.otherElements["chess_board"]
        XCTAssertTrue(chessBoard.waitForExistence(timeout: 5.0))

        // Verify initial game state indicators
        XCTAssertTrue(app.staticTexts["White to move"].exists || app.staticTexts["Your turn"].exists)
    }

    func testBasicChessMove() throws {
        navigateToGame()

        let chessBoard = app.otherElements["chess_board"]
        XCTAssertTrue(chessBoard.waitForExistence(timeout: 5.0))

        // Try to make a basic opening move (e2-e4)
        let e2Square = chessBoard.buttons["square_e2"]
        let e4Square = chessBoard.buttons["square_e4"]

        if e2Square.exists && e4Square.exists {
            e2Square.tap()
            e4Square.tap()

            // Verify move was made (move history or turn indicator changes)
            XCTAssertTrue(
                app.staticTexts["Black to move"].waitForExistence(timeout: 2.0) ||
                app.staticTexts["Computer thinking..."].waitForExistence(timeout: 2.0)
            )
        }
    }

    func testPieceSelection() throws {
        navigateToGame()

        let chessBoard = app.otherElements["chess_board"]
        XCTAssertTrue(chessBoard.waitForExistence(timeout: 5.0))

        // Select a piece and verify selection indicator
        let pawnSquare = chessBoard.buttons["square_e2"]
        if pawnSquare.exists {
            pawnSquare.tap()

            // Look for selection indicator or highlighted squares
            let selectedSquare = app.otherElements["selected_square"]
            XCTAssertTrue(selectedSquare.exists || pawnSquare.isSelected)
        }
    }

    // MARK: - Game Controls Tests

    func testResetButton() throws {
        navigateToGame()

        let resetButton = app.buttons["Reset"]
        XCTAssertTrue(resetButton.waitForExistence(timeout: 5.0))
        XCTAssertTrue(resetButton.isEnabled)

        resetButton.tap()

        // Verify game state reset (should show initial position)
        XCTAssertTrue(app.staticTexts["White to move"].waitForExistence(timeout: 3.0) ||
                     app.staticTexts["Your turn"].waitForExistence(timeout: 3.0))
    }

    func testResignButton() throws {
        navigateToGame()

        let resignButton = app.buttons["Resign"]
        XCTAssertTrue(resignButton.waitForExistence(timeout: 5.0))
        XCTAssertTrue(resignButton.isEnabled)

        resignButton.tap()

        // Verify game ended
        XCTAssertTrue(
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'wins'")).element.waitForExistence(timeout: 3.0) ||
            app.staticTexts["Game Over"].waitForExistence(timeout: 3.0)
        )
    }

    func testGameModeSelection() throws {
        navigateToGame()

        // Look for game mode picker if multiple play modes are enabled
        let humanVsHumanOption = app.buttons["Human vs Human"]
        let humanVsMachineOption = app.buttons["Human vs Machine"]

        if humanVsHumanOption.exists && humanVsMachineOption.exists {
            // Test switching modes
            humanVsHumanOption.tap()
            XCTAssertTrue(humanVsHumanOption.isSelected)

            humanVsMachineOption.tap()
            XCTAssertTrue(humanVsMachineOption.isSelected)
        }
    }

    // MARK: - Coaching Features Tests

    func testCoachingFeedbackDisplay() throws {
        navigateToGame()

        // Look for chess coach section
        let coachSection = app.staticTexts["Chess Coach"]
        if coachSection.waitForExistence(timeout: 5.0) {
            XCTAssertTrue(coachSection.exists)

            // Check for skill level picker
            let skillPicker = app.segmentedControls.firstMatch
            if skillPicker.exists {
                XCTAssertTrue(skillPicker.isEnabled)
            }
        }
    }

    func testSkillLevelChange() throws {
        navigateToGame()

        let skillPicker = app.segmentedControls.firstMatch
        if skillPicker.waitForExistence(timeout: 5.0) {
            let beginnerButton = skillPicker.buttons["Beginner"]
            let intermediateButton = skillPicker.buttons["Intermediate"]

            if beginnerButton.exists && intermediateButton.exists {
                beginnerButton.tap()
                XCTAssertTrue(beginnerButton.isSelected)

                intermediateButton.tap()
                XCTAssertTrue(intermediateButton.isSelected)
            }
        }
    }

    // MARK: - User Profile Tests

    func testUserProfileAccess() throws {
        navigateToGame()

        // Look for profile button or navigation
        let profileButton = app.buttons["profile_button"]
        if profileButton.exists {
            profileButton.tap()

            // Verify profile screen elements
            XCTAssertTrue(app.staticTexts["Profile"].waitForExistence(timeout: 3.0))
        }
    }

    // MARK: - Error Handling Tests

    func testNetworkErrorHandling() throws {
        navigateToGame()

        // Look for connection status indicators
        let connectionStatus = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Connected' OR label CONTAINS 'Disconnected'")).element

        if connectionStatus.exists {
            // If disconnected, verify error handling UI exists
            if connectionStatus.label.contains("Disconnected") {
                let retryButton = app.buttons["Retry"]
                XCTAssertTrue(retryButton.exists || app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'error'")).element.exists)
            }
        }
    }

    // MARK: - Helper Methods

    private func navigateToGame() {
        // If on authentication screen, continue as guest
        let guestButton = app.buttons["Continue as Guest"]
        if guestButton.waitForExistence(timeout: 2.0) {
            guestButton.tap()
        }

        // Wait for game screen to load
        let chessBoard = app.otherElements["chess_board"]
        _ = chessBoard.waitForExistence(timeout: 5.0)
    }

    // MARK: - Performance Tests

    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    func testChessBoardRenderingPerformance() throws {
        navigateToGame()

        measure(metrics: [XCTCPUMetric(), XCTMemoryMetric()]) {
            let chessBoard = app.otherElements["chess_board"]
            _ = chessBoard.waitForExistence(timeout: 5.0)

            // Perform several piece selections to test rendering performance
            for file in ["a", "b", "c", "d", "e"] {
                let square = chessBoard.buttons["square_\(file)2"]
                if square.exists {
                    square.tap()
                }
            }
        }
    }
}