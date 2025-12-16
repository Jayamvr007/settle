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
                    .foregroundColor(.green)
                
                // Title
                Text("Payment Completed?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Details
                VStack(spacing: 12) {
                    Text("Did you complete the payment of")
                        .foregroundColor(.secondary)
                    
                    Text("₹\(settlement.amount.formattedAmount))")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.blue)
                    
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
                        .background(Color.green)
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
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
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
        // Save to Core Data
        let dataManager = DataManager.shared
        let context = dataManager.context
        
        let cdSettlement = CDSettlement(context: context)
        cdSettlement.id = settlement.id
        cdSettlement.amount = settlement.amount as NSDecimalNumber
        cdSettlement.date = Date()
        cdSettlement.status = SettlementStatus.completed.rawValue
        cdSettlement.upiTransactionId = transactionId.isEmpty ? nil : transactionId
        
        // Find group
        let groupFetch = CDGroup.fetchRequest()
        groupFetch.predicate = NSPredicate(format: "id == %@", group.id as CVarArg)
        if let cdGroup = try? context.fetch(groupFetch).first {
            cdSettlement.group = cdGroup
            
            // Find members
            let fromFetch = CDMember.fetchRequest()
            fromFetch.predicate = NSPredicate(format: "id == %@ AND group == %@", settlement.from.id as CVarArg, cdGroup)
            if let cdFrom = try? context.fetch(fromFetch).first {
                cdSettlement.from = cdFrom
            }
            
            let toFetch = CDMember.fetchRequest()
            toFetch.predicate = NSPredicate(format: "id == %@ AND group == %@", settlement.to.id as CVarArg, cdGroup)
            if let cdTo = try? context.fetch(toFetch).first {
                cdSettlement.to = cdTo
            }
        }
        
        dataManager.save()
        
        // Notify completion
        onComplete()
        
        dismiss()
    }
}
