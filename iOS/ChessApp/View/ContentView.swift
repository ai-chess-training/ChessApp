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
        Group {
            if horizontalSizeClass == .regular && verticalSizeClass == .regular {
                splitViewLayout
            } else {
                singleColumnLayout
            }
        }
        .onAppear {
            gameState.setCurrentUser(authManager.userName)
            gameState.setAppleIdentityToken(authManager.appleIdentityToken)
        }
        .onChange(of: authManager.userName) { _, newName in
            gameState.setCurrentUser(newName)
        }
        .onChange(of: authManager.appleIdentityToken) { _, newToken in
            gameState.setAppleIdentityToken(newToken)
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
            iPadSideBar
        } detail: {
            VStack {
                ChessBoardView(gameState: gameState)
                Spacer()
            }
            .padding()
            .sensoryFeedback(.impact(weight: .heavy), trigger: gameState.captureTrigger)
            .sensoryFeedback(.success, trigger: gameState.checkmateTrigger)
            .sensoryFeedback(.error, trigger: gameState.checkTrigger)
            .sensoryFeedback(.warning, trigger: gameState.stalemateTrigger)
        }
    }
    
    private var iPadSideBar: some View {
        ScrollView {
            VStack {
                GameStatusView(gameState: gameState)
                GameControlsView(gameState: gameState)
            }
            .padding()
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                ResetGameButtonView(gameState: gameState)
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    ResignGameButtonView(gameState: gameState)
                    SettingsMenuView(authManager: authManager, gameState: gameState)
                }
            }
        }
    }
    
    // MARK: - Single Column Layout 
    private var singleColumnLayout: some View {
        NavigationStack {
            Group {
                ScrollView {
                    VStack {
                        ChessBoardView(gameState: gameState)
                            .padding(.horizontal)
                        
                        GameStatusView(gameState: gameState)
                            .padding()
                        
                        GameControlsView(gameState: gameState)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ResetGameButtonView(gameState: gameState)
                }
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "Chess Mentor"))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(theme.primaryColor)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        ResignGameButtonView(gameState: gameState)
                        SettingsMenuView(authManager: authManager, gameState: gameState)
                    }
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
