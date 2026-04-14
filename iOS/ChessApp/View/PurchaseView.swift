//
//  PurchaseView.swift
//  ChessApp
//
//  Sheet for purchasing game credit packs.
//

import SwiftUI
import StoreKit

struct PurchaseView: View {
    @Environment(GameCreditsManager.self) private var creditsManager
    @Environment(AppTheme.self) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    trialStatusSection
                    creditsSection
                    productSection
                    restoreSection
                }
                .padding()
            }
            .navigationTitle("Game Credits")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "crown.fill")
                .font(.system(size: 48))
                .foregroundStyle(theme.primaryColor.gradient)

            Text("Chess Mentor")
                .font(.title2)
                .fontWeight(.bold)

            Text("Keep playing and improving with your AI chess mentor")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 8)
    }

    // MARK: - Trial Status

    private var trialStatusSection: some View {
        GroupBox {
            HStack {
                Image(systemName: creditsManager.isInFreeTrial ? "clock.fill" : "clock.badge.xmark.fill")
                    .foregroundStyle(creditsManager.isInFreeTrial ? .green : .red)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    if creditsManager.isInFreeTrial {
                        Text("Free Trial Active")
                            .font(.headline)
                        Text("\(creditsManager.freeTrialDaysRemaining) days remaining · 1 free game per day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("Free Trial Expired")
                            .font(.headline)
                        Text("Purchase game packs to keep playing")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Credits Display

    private var creditsSection: some View {
        GroupBox {
            HStack {
                Image(systemName: "bitcoinsign.circle.fill")
                    .foregroundStyle(theme.primaryColor)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Game Credits")
                        .font(.headline)

                    if creditsManager.isInFreeTrial && creditsManager.hasFreeGameToday {
                        Text("1 free game available today + \(creditsManager.remainingCredits) purchased")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("\(creditsManager.remainingCredits) game\(creditsManager.remainingCredits == 1 ? "" : "s") remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Text("\(creditsManager.remainingCredits)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.primaryColor)
            }
            .padding(.vertical, 4)
        }
    }

    // MARK: - Product

    private var productSection: some View {
        VStack(spacing: 12) {
            if let product = creditsManager.products.first {
                GroupBox {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(product.displayName)
                                    .font(.headline)
                                Text(product.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Text(product.displayPrice)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(theme.primaryColor)
                        }

                        Button {
                            Task {
                                await creditsManager.purchase(product)
                            }
                        } label: {
                            HStack {
                                if creditsManager.isPurchasing {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "cart.fill")
                                    Text("Buy \(product.displayName)")
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(theme.primaryColor)
                        .controlSize(.large)
                        .disabled(creditsManager.isPurchasing)
                    }
                    .padding(.vertical, 4)
                }
            } else if creditsManager.isLoadingProducts {
                ProgressView("Loading products...")
                    .padding()
            } else if let loadError = creditsManager.productsLoadError {
                GroupBox {
                    VStack(spacing: 12) {
                        Label(loadError, systemImage: "wifi.exclamationmark")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button {
                            Task {
                                await creditsManager.loadProducts()
                            }
                        } label: {
                            Label("Try Again", systemImage: "arrow.clockwise")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.regular)
                    }
                    .padding(.vertical, 4)
                }
            }

            if let error = creditsManager.purchaseError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    // MARK: - Restore

    private var restoreSection: some View {
        Button {
            Task {
                await creditsManager.restorePurchases()
            }
        } label: {
            Text("Restore Purchases")
                .font(.footnote)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.secondary)
    }
}

#Preview {
    PurchaseView()
        .environment(GameCreditsManager())
        .environment(AppTheme.shared)
}
