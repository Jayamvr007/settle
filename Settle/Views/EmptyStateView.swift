//
//  EmptyStateView.swift
//  Settle
//
//  Reusable empty state component for lists
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // Icon
            ZStack {
                Circle()
                    .fill(AppTheme.primary.opacity(0.1))
                    .frame(width: 100, height: 100)
                
                Image(systemName: icon)
                    .font(.system(size: 40))
                    .foregroundColor(AppTheme.primary)
            }
            
            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(.settleHeadline)
                    .foregroundColor(.primary)
                
                Text(message)
                    .font(.settleBody)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            // Optional action button
            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticManager.light()
                    action()
                }) {
                    Text(actionTitle)
                        .font(.settleHeadline)
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(AppTheme.primaryGradient)
                        .cornerRadius(12)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preset Empty States
extension EmptyStateView {
    static var noGroups: EmptyStateView {
        EmptyStateView(
            icon: "person.3",
            title: "No Groups Yet",
            message: "Create a group to start tracking shared expenses with friends and family."
        )
    }
    
    static var noExpenses: EmptyStateView {
        EmptyStateView(
            icon: "list.bullet.rectangle",
            title: "No Expenses",
            message: "Add your first expense to start tracking who owes what."
        )
    }
    
    static var noSettlements: EmptyStateView {
        EmptyStateView(
            icon: "checkmark.circle",
            title: "All Settled Up!",
            message: "No pending balances. Everyone is even!"
        )
    }
    
    static var noPaymentHistory: EmptyStateView {
        EmptyStateView(
            icon: "clock",
            title: "No Payment History",
            message: "Completed settlements will appear here."
        )
    }
}

#Preview {
    EmptyStateView.noGroups
}
