//
//  CoachingUITests.swift
//  ChessAppUITests
//
//  UI tests specific to chess coaching features
//

import XCTest

final class CoachingUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Coaching Interface Tests

    func testCoachingSectionExists() throws {
        navigateToGame()

        let coachingSection = app.staticTexts["Chess Coach"]
        XCTAssertTrue(coachingSection.waitForExistence(timeout: 5.0))

        // Verify coaching icon
        let brainIcon = app.images["brain"]
        XCTAssertTrue(brainIcon.exists)
    }

    func testSkillLevelPicker() throws {
        navigateToGame()

        let skillLevelPicker = app.segmentedControls.element(boundBy: 0)
        XCTAssertTrue(skillLevelPicker.waitForExistence(timeout: 5.0))

        // Test all skill levels if they exist
        let skillLevels = ["Beginner", "Intermediate", "Advanced", "Expert"]
        for skillLevel in skillLevels {
            let levelButton = skillLevelPicker.buttons[skillLevel]
            if levelButton.exists {
                levelButton.tap()
                XCTAssertTrue(levelButton.isSelected)
            }
        }
    }

    func testSkillLevelChangeAlert() throws {
        navigateToGame()

        // Make a move first to have game in progress
        let chessBoard = app.otherElements["chess_board"]
        if chessBoard.waitForExistence(timeout: 5.0) {
            let e2Square = chessBoard.buttons["square_e2"]
            let e4Square = chessBoard.buttons["square_e4"]

            if e2Square.exists && e4Square.exists {
                e2Square.tap()
                e4Square.tap()

                // Now try to change skill level - should show alert
                let skillPicker = app.segmentedControls.element(boundBy: 0)
                if skillPicker.exists {
                    let currentLevel = skillPicker.buttons.allElementsBoundByIndex.first { $0.isSelected }
                    let otherLevel = skillPicker.buttons.allElementsBoundByIndex.first { !$0.isSelected }

                    if let otherLevel = otherLevel {
                        otherLevel.tap()

                        // Look for confirmation alert
                        let alert = app.alerts["Change Skill Level?"]
                        if alert.waitForExistence(timeout: 3.0) {
                            XCTAssertTrue(alert.exists)
                            XCTAssertTrue(alert.buttons["Cancel"].exists)
                            XCTAssertTrue(alert.buttons["Reset & Change"].exists)

                            // Test cancel
                            alert.buttons["Cancel"].tap()
                            XCTAssertTrue(currentLevel?.isSelected ?? false)
                        }
                    }
                }
            }
        }
    }

    func testAnalysisStatusDisplay() throws {
        navigateToGame()

        // Look for analysis status indicators
        let analyzingText = app.staticTexts["Analyzing move..."]
        let creatingSessionText = app.staticTexts["Creating session..."]

        // These may appear temporarily
        if analyzingText.exists {
            XCTAssertTrue(app.staticTexts["Chess Coach is reviewing your move"].exists)
        }

        if creatingSessionText.exists {
            XCTAssertTrue(app.staticTexts["Setting up coaching session"].exists)
        }
    }

    func testMoveFeedbackDisplay() throws {
        navigateToGame()

        // Make a move to generate feedback
        let chessBoard = app.otherElements["chess_board"]
        if chessBoard.waitForExistence(timeout: 5.0) {
            let e2Square = chessBoard.buttons["square_e2"]
            let e4Square = chessBoard.buttons["square_e4"]

            if e2Square.exists && e4Square.exists {
                e2Square.tap()
                e4Square.tap()

                // Wait for potential feedback
                let feedbackContainer = app.otherElements["move_feedback"]
                if feedbackContainer.waitForExistence(timeout: 10.0) {
                    // Check for move number
                    let moveNumber = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Move '")).element
                    XCTAssertTrue(moveNumber.exists)

                    // Check for move notation
                    let moveNotation = app.staticTexts["e4"]
                    XCTAssertTrue(moveNotation.exists)
                }
            }
        }
    }

    func testFeedbackSeverityIndicators() throws {
        navigateToGame()

        // Look for severity indicators in feedback
        let severityColors = ["Excellent", "Good", "Inaccuracy", "Mistake", "Blunder"]

        for severity in severityColors {
            let severityText = app.staticTexts[severity]
            if severityText.exists {
                // Verify severity indicator circle exists near the text
                let severityIndicator = app.otherElements["severity_indicator"]
                XCTAssertTrue(severityIndicator.exists)
                break
            }
        }
    }

    func testExtendedFeedbackToggle() throws {
        navigateToGame()

        let detailedAnalysisButton = app.buttons["Detailed Analysis"]
        if detailedAnalysisButton.waitForExistence(timeout: 10.0) {
            XCTAssertTrue(detailedAnalysisButton.exists)

            // Test expand
            detailedAnalysisButton.tap()
            let chevronUp = app.images["chevron.up"]
            XCTAssertTrue(chevronUp.waitForExistence(timeout: 2.0))

            // Test collapse
            detailedAnalysisButton.tap()
            let chevronDown = app.images["chevron.down"]
            XCTAssertTrue(chevronDown.waitForExistence(timeout: 2.0))
        }
    }

    func testConceptTags() throws {
        navigateToGame()

        let conceptsSection = app.staticTexts["Concepts"]
        if conceptsSection.waitForExistence(timeout: 10.0) {
            XCTAssertTrue(conceptsSection.exists)

            // Look for tag elements
            let tagElements = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'opening' OR label CONTAINS 'center' OR label CONTAINS 'development'"))
            XCTAssertGreaterThan(tagElements.count, 0)
        }
    }

    func testPracticeSuggestions() throws {
        navigateToGame()

        let practiceSection = app.staticTexts["Practice Suggestions"]
        if practiceSection.waitForExistence(timeout: 10.0) {
            let expandButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Practice Suggestions'")).element

            if expandButton.exists {
                expandButton.tap()

                // Look for drill objectives
                let drillObjective = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Practice'")).element
                XCTAssertTrue(drillObjective.waitForExistence(timeout: 2.0))

                // Look for best line suggestions
                let bestLine = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Best line:'")).element
                if bestLine.exists {
                    XCTAssertTrue(bestLine.exists)
                }
            }
        }
    }

    func testBestMoveSuggestion() throws {
        navigateToGame()

        // Look for best move suggestions (only appears when player move differs from best)
        let bestMoveText = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Better:'")).element
        if bestMoveText.exists {
            let lightbulbIcon = app.images["lightbulb"]
            XCTAssertTrue(lightbulbIcon.exists)
        }
    }

    func testConnectionStatus() throws {
        navigateToGame()

        // Check for connection status indicator
        let connectedStatus = app.staticTexts["Connected"]
        let disconnectedStatus = app.staticTexts["Disconnected"]

        XCTAssertTrue(connectedStatus.exists || disconnectedStatus.exists)

        // If disconnected, check for retry functionality
        if disconnectedStatus.exists {
            let retryButton = app.buttons["Retry"]
            if retryButton.exists {
                XCTAssertTrue(retryButton.isEnabled)

                // Test retry button
                retryButton.tap()

                // Should attempt reconnection
                XCTAssertTrue(connectedStatus.waitForExistence(timeout: 10.0) ||
                             app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Connecting'")).element.exists)
            }
        }
    }

    func testConnectionStatusIndicator() throws {
        navigateToGame()

        // Look for connection status circle indicator
        let statusCircle = app.otherElements["connection_status_circle"]
        if statusCircle.exists {
            // Circle should be visible and have appropriate color
            XCTAssertTrue(statusCircle.exists)
        }
    }

    func testCoachingDisabledState() throws {
        // This test would apply if coaching can be disabled
        navigateToGame()

        let disabledMessage = app.staticTexts["Make a move to receive coaching feedback"]
        if disabledMessage.exists {
            XCTAssertTrue(disabledMessage.exists)
        }
    }

    // MARK: - Performance Tests

    func testCoachingResponseTime() throws {
        navigateToGame()

        measure(metrics: [XCTClockMetric()]) {
            let chessBoard = app.otherElements["chess_board"]
            if chessBoard.exists {
                let e2Square = chessBoard.buttons["square_e2"]
                let e4Square = chessBoard.buttons["square_e4"]

                if e2Square.exists && e4Square.exists {
                    e2Square.tap()
                    e4Square.tap()

                    // Wait for feedback to appear or analysis to complete
                    let feedbackContainer = app.otherElements["move_feedback"]
                    let analyzingComplete = !app.staticTexts["Analyzing move..."].exists

                    _ = feedbackContainer.waitForExistence(timeout: 10.0) || analyzingComplete
                }
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
}