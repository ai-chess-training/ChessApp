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
    @Environment(AuthenticationManager.self) private var authManager
    
    var body: some View {
        GeometryReader { ruler in
            if ruler.size.width < ruler.size.height {
                singleColumnLayout
            } else {
                splitViewLayout
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
            ScrollView {
                VStack {
                    GameStatusView(gameState: gameState)
                    ChessBoardView(gameState: gameState)
                    GameControlsView(gameState: gameState)
                }
                .padding()
            }
            .navigationTitle(String(localized: "Chess"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
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
