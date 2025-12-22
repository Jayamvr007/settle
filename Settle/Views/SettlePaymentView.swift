//
//  SettlePaymentView.swift
//  Settle
//
//  Created by Jayam Verma on 18/12/25.
//

import SwiftUI

struct SettlePaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = PaymentViewModel()
    @State private var showingManualConfirmation = false
    
    let settlement: SimplifiedSettlement
    let group: Group
    let onComplete: () -> Void
    
    // UI State
    @State private var showingUPIOptions = false
    @State private var showingRecordCash = false
    
    // For Gateway
    @State private var presentingController: UIViewController?
    
    var body: some View {
        NavigationStack {
            List {
                // Header
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
                
                // Methods
                Section("Payment Options") {
                    // 1. Direct UPI (Robust Intent)
                    if let upiId = settlement.to.upiId, !upiId.isEmpty {
                        Button {
                            viewModel.preparePayment(settlement: settlement, group: group)
                            showingUPIOptions = true
                        } label: {
                            HStack {
                                Image(systemName: "indianrupeesign.circle.fill")
                                    .foregroundColor(.blue)
                                    .font(.title2)
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Pay via UPI App")
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
                        Text("No UPI ID available")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                    
                    // 2. Gateway (Razorpay) - Test Mode
                    Button {
                        viewModel.preparePayment(settlement: settlement, group: group)
                        if let controller = presentingController {
                             viewModel.initiateRazorpayPayment(presentingController: controller)
                        }
                    } label: {
                        HStack {
                            Image(systemName: "creditcard.fill")
                                .foregroundColor(.purple)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pay via Razorpay")
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                Text(viewModel.isRazorpayAvailable ? "Test Mode" : "SDK Missing")
                                    .font(.caption)
                                    .foregroundColor(viewModel.isRazorpayAvailable ? .orange : .red)
                            }
                            Spacer()
                            if viewModel.isRazorpayAvailable {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(!viewModel.isRazorpayAvailable)
                    
                    // 3. Manual
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
                    Text("Secure payments powered by UPI & Razorpay")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settle Payment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                }
            }
            // Sheets
            .sheet(isPresented: $showingUPIOptions) {
                UPIAppSelectionView(viewModel: viewModel, settlement: settlement, group: group, onComplete: {
                    dismiss()
                    onComplete()
                })
            }
            .sheet(isPresented: $showingRecordCash) {
                RecordCashView(viewModel: viewModel, settlement: settlement, group: group, onComplete: {
                    dismiss()
                    onComplete()
                })
            }
            .background(ViewControllerResolver { controller in
                presentingController = controller
            })
            // Manual Confirmation Triggered by ViewModel
            .sheet(isPresented: $viewModel.showingManualConfirmation) {
                 ManualConfirmationView(
                    viewModel: viewModel,
                    settlement: settlement,
                    group: group,
                    onComplete: {
                         dismiss()
                         onComplete()
                    }
                 )
            }
            .alert("Payment Error", isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) { }
            } message: {
                if let error = viewModel.errorMessage { Text(error) }
            }
        }
    }
}

// MARK: - Helper Views

struct UPIAppSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PaymentViewModel
    let settlement: SimplifiedSettlement
    let group: Group
    let onComplete: () -> Void
    
    var body: some View {
        NavigationStack {
            List {
                Section("Amount: ₹\(settlement.amount.formattedAmount)") {
                    ForEach(viewModel.installedApps, id: \.self) { app in
                        Button {
                            viewModel.initiateUPIPayment(using: app)
                        } label: {
                            HStack {
                                Image(systemName: app.iconName)
                                    .foregroundColor(.blue)
                                Text(app.displayName)
                            }
                        }
                    }
                    
                    if viewModel.installedApps.isEmpty {
                        Text("No UPI apps found")
                    }
                }
                
                Section("Manual Link") {
                     ShareLink(item: viewModel.getGenericUPIString(settlement: settlement, group: group)) {
                         Label("Share Payment Link", systemImage: "square.and.arrow.up")
                     }
                }
            }
            .navigationTitle("Choose App")
            .toolbar {
                 Button("Close") { dismiss() }
            }
        }
    }
}

struct RecordCashView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PaymentViewModel
    let settlement: SimplifiedSettlement
    let group: Group
    let onComplete: () -> Void
    @State private var notes = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Amount: ₹\(settlement.amount.formattedAmount)") {
                    TextField("Notes", text: $notes)
                }
                Button("Mark as Paid") {
                    viewModel.recordCashPayment(settlement: settlement, group: group, notes: notes)
                    onComplete()
                    dismiss()
                }
            }
            .navigationTitle("Record Cash")
        }
    }
}

struct ManualConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PaymentViewModel
    let settlement: SimplifiedSettlement
    let group: Group
    let onComplete: () -> Void
    @State private var txnId = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                 Image(systemName: "questionmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
                 Text("Did you complete the payment?")
                    .font(.title2)
                
                 TextField("Enter Transaction ID (Optional)", text: $txnId)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                 HStack {
                     Button("No") { dismiss() }
                        .padding()
                     Button("Yes, Confirmed") {
                         viewModel.recordCashPayment(settlement: settlement, group: group, notes: "UPI Manual Confirm", transactionId: txnId)
                         onComplete()
                         dismiss()
                     }
                     .buttonStyle(.borderedProminent)
                 }
            }
            .padding()
        }
        .interactiveDismissDisabled()
    }
}


// MARK: - UIViewController Resolver
struct ViewControllerResolver: UIViewControllerRepresentable {
    let onResolve: (UIViewController) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        ParentResolverViewController(onResolve: onResolve)
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    class ParentResolverViewController: UIViewController {
        let onResolve: (UIViewController) -> Void
        init(onResolve: @escaping (UIViewController) -> Void) {
            self.onResolve = onResolve
            super.init(nibName: nil, bundle: nil)
        }
        required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
        
        override func didMove(toParent parent: UIViewController?) {
            super.didMove(toParent: parent)
            if let parent = parent {
                onResolve(parent)
            }
        }
    }
}
