//
//  ManualPaymentConfirmationView.swift
//  Settle
//
//  Created by Jayam Verma on 15/12/25.
//


//
//  ManualPaymentConfirmationView.swift
//  Settle
//

import SwiftUI

struct ManualPaymentConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    let settlement: SimplifiedSettlement
    let group: Group
    let onComplete: () -> Void
    
    @State private var transactionId = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()
                
                // Icon
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(AppTheme.getsBack)
                
                // Title
                Text("Payment Completed?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Details
                VStack(spacing: 12) {
                    Text("Did you complete the payment of")
                        .foregroundColor(.secondary)
                    
                    Text("₹\(settlement.amount.formattedAmount)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(AppTheme.primary)
                    
                    Text("to \(settlement.to.name)?")
                        .foregroundColor(.secondary)
                }
                
                // Transaction ID (Optional)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Transaction ID (Optional)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    TextField("Enter UPI transaction ID", text: $transactionId)
                        .textFieldStyle(.roundedBorder)
                        .textInputAutocapitalization(.characters)
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        confirmPayment()
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Yes, Payment Completed")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.secondary)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                    
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("No, Cancel")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppTheme.owes.opacity(0.1))
                        .foregroundColor(AppTheme.owes)
                        .cornerRadius(12)
                        .fontWeight(.semibold)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .navigationTitle("Confirm Payment")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func confirmPayment() {
        // Settlement is recorded via PaymentViewModel.recordCashPayment() 
        // which creates a settlement expense in Firestore
        // Just notify completion and dismiss
        onComplete()
        dismiss()
    }
}

