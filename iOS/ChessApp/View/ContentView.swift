//
//  ContentView.swift
//  ChessApp
//
//  Created by Cynthia Wang on 9/5/25.
//

import SwiftUI

// MARK: - Views
struct ContentView: View {
    @State private var gameState = ChessGameState()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(AuthenticationManager.self) private var authManager
    @Environment(AppTheme.self) private var theme

    var body: some View {
        GeometryReader { ruler in
            // iPad landscape: use split view
            // iPhone landscape or portrait: use single column
            if horizontalSizeClass == .regular && verticalSizeClass == .regular {
                splitViewLayout
            } else {
                singleColumnLayout
            }
        }
        .onAppear {
            gameState.setCurrentUser(authManager.userName)
        }
        .onChange(of: authManager.userName) { _, newName in
            gameState.setCurrentUser(newName)
        }
        .overlay(
            // Pawn promotion overlay
            Group {
                if gameState.showingPawnPromotion {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .overlay(
                            PawnPromotionView(
                                color: gameState.currentPlayer,
                                onSelection: { pieceType in
                                    gameState.completePawnPromotion(with: pieceType)
                                },
                                onCancel: {
                                    gameState.cancelPawnPromotion()
                                }
                            )
                        )
                }
            }
        )
        
    }
    
    // MARK: - iPad Landscape Layout
    private var splitViewLayout: some View {
        NavigationSplitView {
            // Left sidebar with controls
            ScrollView {
                VStack {
                    GameStatusView(gameState: gameState)
                    GameControlsView(gameState: gameState)
                }
                .padding()
            }
            .navigationTitle(String(localized: "Game Controls"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    UserProfileView(authManager: authManager, gameState: gameState)
                }
            }
        } detail: {
            VStack {
                ChessBoardView(gameState: gameState)

                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "Game Board"))
                        .font(.headline)
                        .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.impact(weight: .heavy), trigger: gameState.captureTrigger)
            .sensoryFeedback(.success, trigger: gameState.checkmateTrigger)
            .sensoryFeedback(.error, trigger: gameState.checkTrigger)
            .sensoryFeedback(.warning, trigger: gameState.stalemateTrigger)
        }
    }
    
    // MARK: - Single Column Layout (iPhone + iPad Portrait)
    private var singleColumnLayout: some View {
        NavigationStack {
            GeometryReader { geometry in
                if geometry.size.height > geometry.size.width {
                    // Portrait orientation
                    ScrollView {
                        VStack(spacing: 16) {
                            GameStatusView(gameState: gameState)
                                .padding(.horizontal)

                            ChessBoardView(gameState: gameState)
                                .padding(.horizontal)

                            GameControlsView(gameState: gameState)
                                .padding(.horizontal)
                        }
                        .padding(.vertical)
                    }
                } else {
                    // Landscape orientation
                    HStack(spacing: 12) {
                        ChessBoardView(gameState: gameState)
                            .frame(maxHeight: .infinity)
                            .padding(.vertical)

                        ScrollView {
                            VStack(spacing: 16) {
                                GameStatusView(gameState: gameState)
                                GameControlsView(gameState: gameState)
                            }
                            .padding()
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "Chess Mentor"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryColor)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    UserProfileView(authManager: authManager, gameState: gameState)
                }
            }
            .sensoryFeedback(.impact(weight: .heavy), trigger: gameState.captureTrigger)
            .sensoryFeedback(.success, trigger: gameState.checkmateTrigger)
            .sensoryFeedback(.error, trigger: gameState.checkTrigger)
            .sensoryFeedback(.warning, trigger: gameState.stalemateTrigger)
        }
    }
}


#Preview("Portrait", traits: .portrait) {
    let authManager = AuthenticationManager()
    ContentView()
        .environment(authManager)
        .withAuthenticationUI(authManager)
}

#Preview("Landscape", traits: .landscapeLeft) {
    let authManager = AuthenticationManager()
    ContentView()
        .environment(authManager)
        .withAuthenticationUI(authManager)
}
