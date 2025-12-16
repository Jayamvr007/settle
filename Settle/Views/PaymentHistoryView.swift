//
//  PaymentHistoryView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  PaymentHistoryView.swift
//  Settle
//

import SwiftUI

struct PaymentHistoryView: View {
    let group: Group
    @State private var completedSettlements: [SimplifiedSettlement] = []
    
    var body: some View {
        List {
            if completedSettlements.isEmpty {
                ContentUnavailableView(
                    "No Payment History",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Completed payments will appear here")
                )
            } else {
                ForEach(completedSettlements) { settlement in
                    PaymentHistoryRow(settlement: settlement)
                }
            }
        }
        .navigationTitle("Payment History")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCompletedSettlements()
        }
    }
    
    private func loadCompletedSettlements() {
        // Load from Core Data
        // This is a placeholder - implement proper fetch
        completedSettlements = []
    }
}

struct PaymentHistoryRow: View {
    let settlement: SimplifiedSettlement
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(settlement.from.name) → \(settlement.to.name)")
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("₹\(settlement.amount.formattedAmount)")
                    .font(.headline)
                    .foregroundColor(.blue)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("Paid")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                
                // Add date here if you store it
            }
        }
        .padding(.vertical, 4)
    }
}
