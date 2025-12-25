//
//  OnboardingView.swift
//  Settle
//
//  Simple first-launch walkthrough for the app.
//

import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    
    var body: some View {
        ZStack {
            TabView {
                OnboardingPageView(
                    systemImage: "person.3.fill",
                    title: "Split expenses with friends",
                    message: "Create groups for trips, dinners, and more. Add friends and keep everything in one place."
                )
                
                OnboardingPageView(
                    systemImage: "list.bullet.rectangle.portrait",
                    title: "Track who owes what",
                    message: "Add expenses and let Settle keep track of balances automatically for each member."
                )
                
                OnboardingPageView(
                    systemImage: "indianrupeesign.circle.fill",
                    title: "Settle up easily",
                    message: "Use UPI helper to jump into your UPI apps and settle pending balances quickly."
                )
                
                OnboardingPageView(
                    systemImage: "lock.fill",
                    title: "Your data stays on device",
                    message: "All groups, expenses, and balances are stored locally on your iPhone. No analytics, no tracking."
                )
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            
            VStack {
                Spacer()
                Button(action: {
                    HapticManager.success()
                    hasSeenOnboarding = true
                }) {
                    Text("Get Started")
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
    }
}

private struct OnboardingPageView: View {
    let systemImage: String
    let title: String
    let message: String
    
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: systemImage)
                .font(.system(size: 72))
                .foregroundStyle(AppTheme.primaryGradient)
                .scaleEffect(isAnimated ? 1.0 : 0.8)
                .opacity(isAnimated ? 1.0 : 0.5)
                .padding(.bottom, 8)
            
            Text(title)
                .font(.settleTitle)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Text(message)
                .font(.settleBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimated = true
            }
        }
    }
}


