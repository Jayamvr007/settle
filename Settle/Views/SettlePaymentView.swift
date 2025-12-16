//
//  SettlePaymentView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  SettlePaymentView.swift
//  Settle
//

import SwiftUI

struct SettlePaymentView: View {
    @Environment(\.dismiss) private var dismiss
    let settlement: SimplifiedSettlement
    let group: Group
    let onComplete: () -> Void
    
    @State private var showingUPIOptions = false
    @State private var showingRecordCash = false
    @State private var transactionId = ""
    var onDismissParent: (() -> Void)?
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("From")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(settlement.from.name)
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "arrow.right")
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("To")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(settlement.to.name)
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    HStack {
                        Text("Amount")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("₹\(settlement.amount.formattedAmount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                    }
                }
                
                Section("Payment Methods") {
                    if let upiId = settlement.to.upiId, !upiId.isEmpty {
                        Button {
                            showingUPIOptions = true
                        } label: {
                            HStack {
                                Image(systemName: "indianrupeesign.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pay via UPI")
                                        .foregroundColor(.primary)
                                        .fontWeight(.medium)
                                    
                                    Text(upiId)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    } else {
                        Text("No UPI ID available for \(settlement.to.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    Button {
                        showingRecordCash = true
                    } label: {
                        HStack {
                            Image(systemName: "banknote.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                            
                            Text("Record Cash Payment")
                                .foregroundColor(.primary)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Text("Once settled, this will be marked as complete")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settle Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingUPIOptions) {
                UPIPaymentView(settlement: settlement, group: group, onComplete: onComplete)
            }
            .sheet(isPresented: $showingRecordCash) {
                RecordCashPaymentView(settlement: settlement, group: group, onComplete: {
                    dismiss()
                    onComplete()
                })
            }
        }
    }
}

//
//  UPIPaymentView.swift
//  Settle
//

//
//  UPIPaymentView.swift
//  Settle
//

struct UPIPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    let settlement: SimplifiedSettlement
    let group: Group
    let onComplete: () -> Void
    
    @State private var installedApps: [UPIManager.UPIApp] = []
    @State private var isProcessing = false
    @State private var showingManualConfirmation = false
    @State private var transactionRef: String = UUID().uuidString
    
    var body: some View {
        NavigationStack {
            List {
                paymentDetailsSection
                
                if installedApps.isEmpty {
                    noUPIAppsSection
                } else {
                    upiAppsSection
                }
                
                footerSection
            }
            .navigationTitle("Pay via UPI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadInstalledApps()
            }
            .sheet(isPresented: $showingManualConfirmation) {
                ManualPaymentConfirmationView(
                    settlement: settlement,
                    group: group,
                    onComplete: {
                        onComplete()
                        dismiss()
                    }
                )
            }
        }
    }
    
    private var paymentDetailsSection: some View {
        Section {
            HStack {
                Text("Amount to pay")
                Spacer()
                Text("₹\(settlement.amount.formattedAmount)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            
            HStack {
                Text("To")
                Spacer()
                Text(settlement.to.name)
                    .fontWeight(.medium)
            }
            
            HStack {
                Text("UPI ID")
                Spacer()
                Text(settlement.to.upiId ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var upiAppsSection: some View {
        Section("Choose UPI App") {
            ForEach(installedApps, id: \.self) { app in
                UPIAppRow(app: app) {
                    initiatePayment(using: app)
                }
            }
        }
    }
    
    private var noUPIAppsSection: some View {
        Section {
            ContentUnavailableView(
                "No UPI Apps Found",
                systemImage: "exclamationmark.triangle",
                description: Text("Please install a UPI app like Google Pay, PhonePe, or Paytm")
            )
        }
    }
    
    private var footerSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("After completing payment in the UPI app:")
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text("1. Complete the payment")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("2. Return to Settle app")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("3. Confirm payment completion")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func loadInstalledApps() {
        installedApps = UPIManager.shared.getInstalledUPIApps()
    }
    
    private func initiatePayment(using app: UPIManager.UPIApp) {
        guard let upiId = settlement.to.upiId else { return }
        
        UPIManager.shared.initiatePayment(
            app: app,
            upiId: upiId,
            name: settlement.to.name,
            amount: settlement.amount,
            transactionNote: "Settlement - \(group.name)",
            transactionRef: transactionRef
        ) { success in
            if success {
                // Wait a moment for the UPI app to open
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    // Show manual confirmation when user returns
                    showingManualConfirmation = true
                }
            }
        }
    }
}

struct UPIAppRow: View {
    let app: UPIManager.UPIApp
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: app.iconName)
                    .font(.title2)
                    .foregroundColor(colorForApp(app))
                    .frame(width: 32)
                
                Text(app.displayName)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
    }
    
    private func colorForApp(_ app: UPIManager.UPIApp) -> Color {
        switch app.color {
        case "blue": return .blue
        case "purple": return .purple
        case "cyan": return .cyan
        case "orange": return .orange
        case "yellow": return .yellow
        default: return .blue
        }
    }
}


struct RecordCashPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    let settlement: SimplifiedSettlement
    let group: Group
    let onComplete: () -> Void
    
    @State private var notes = ""
    @State private var showingConfirmation = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Amount")
                        Spacer()
                        Text("₹\(settlement.amount.formattedAmount)")
                            .font(.headline)
                    }
                    
                    HStack {
                        Text("From")
                        Spacer()
                        Text(settlement.from.name)
                    }
                    
                    HStack {
                        Text("To")
                        Spacer()
                        Text(settlement.to.name)
                    }
                }
                
                Section("Notes (Optional)") {
                    TextField("Add notes...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button {
                        showingConfirmation = true
                    } label: {
                        Text("Mark as Paid")
                            .frame(maxWidth: .infinity)
                            .fontWeight(.semibold)
                    }
                } footer: {
                    Text("This will record that the payment was made in cash")
                        .font(.caption)
                }
            }
            .navigationTitle("Record Cash Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Confirm Payment", isPresented: $showingConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Confirm") {
                    recordPayment()
                }
            } message: {
                Text("Mark ₹\(settlement.amount.formattedAmount) as paid by \(settlement.from.name) to \(settlement.to.name)?")
            }
        }
    }
    
    private func recordPayment() {
        let dataManager = DataManager.shared
        let context = dataManager.context
        
        let cdSettlement = CDSettlement(context: context)
        cdSettlement.id = settlement.id
        cdSettlement.amount = settlement.amount as NSDecimalNumber
        cdSettlement.date = Date()
        cdSettlement.status = SettlementStatus.completed.rawValue
        
        // Find group
        let groupFetch = CDGroup.fetchRequest()
        groupFetch.predicate = NSPredicate(format: "id == %@", group.id as CVarArg)
        if let cdGroup = try? context.fetch(groupFetch).first {
            cdSettlement.group = cdGroup
            
            // Find members
            let fromFetch = CDMember.fetchRequest()
            fromFetch.predicate = NSPredicate(format: "id == %@ AND group == %@", settlement.from.id as CVarArg, cdGroup)
            if let cdFrom = try? context.fetch(fromFetch).first {
                cdSettlement.from = cdFrom  // Changed from fromMember
            }
            
            let toFetch = CDMember.fetchRequest()
            toFetch.predicate = NSPredicate(format: "id == %@ AND group == %@", settlement.to.id as CVarArg, cdGroup)
            if let cdTo = try? context.fetch(toFetch).first {
                cdSettlement.to = cdTo  // Changed from toMember
            }
        }
        
        dataManager.save()
        onComplete()
        dismiss()
    }

}
