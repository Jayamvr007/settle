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
    
    let settlement: SimplifiedSettlement
    let group: Group
    let onComplete: () -> Void
    
    // Single sheet state to prevent multiple sheet issue
    enum ActiveSheet: Identifiable {
        case upiOptions
        case recordCash
        case manualConfirmation
        
        var id: Int { hashValue }
    }
    @State private var activeSheet: ActiveSheet?
    
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
                            Text(UserHelper.displayName(for: settlement.from))
                                .font(.headline)
                                .foregroundColor(UserHelper.isCurrentUser(settlement.from) ? AppTheme.primary : .primary)
                        }
                        Spacer()
                        Image(systemName: "arrow.right")
                            .foregroundColor(.blue)
                        Spacer()
                        VStack(alignment: .trailing, spacing: 8) {
                            Text("To")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(UserHelper.displayName(for: settlement.to))
                                .font(.headline)
                                .foregroundColor(UserHelper.isCurrentUser(settlement.to) ? AppTheme.primary : .primary)
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
                            activeSheet = .upiOptions
                        } label: {
                            HStack {
                                Image(systemName: "indianrupeesign.circle.fill")
                                    .foregroundColor(AppTheme.primary)
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
                    
                    // Razorpay - Commented out (not fully integrated)
                    /*
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
                                    .foregroundColor(viewModel.isRazorpayAvailable ? .orange : AppTheme.owes)
                            }
                            Spacer()
                            if viewModel.isRazorpayAvailable {
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .disabled(!viewModel.isRazorpayAvailable)
                    */
                    
                    // 3. Manual
                    Button {
                        activeSheet = .recordCash
                    } label: {
                        HStack {
                            Image(systemName: "banknote.fill")
                                .foregroundColor(AppTheme.secondary)
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
                    Text("Secure payments powered by UPI")
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
            // Single sheet using item-based approach
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .upiOptions:
                    UPIAppSelectionView(viewModel: viewModel, settlement: settlement, group: group, onComplete: {
                        activeSheet = nil
                        dismiss()
                        onComplete()
                    })
                case .recordCash:
                    RecordCashView(viewModel: viewModel, settlement: settlement, group: group, onComplete: {
                        activeSheet = nil
                        dismiss()
                        onComplete()
                    })
                case .manualConfirmation:
                    ManualConfirmationView(viewModel: viewModel, settlement: settlement, group: group, onComplete: {
                        activeSheet = nil
                        dismiss()
                        onComplete()
                    })
                }
            }
            .background(ViewControllerResolver { controller in
                presentingController = controller
            })
            // Sync viewModel flag with activeSheet
            .onChange(of: viewModel.showingManualConfirmation) { newValue in
                if newValue {
                    activeSheet = .manualConfirmation
                    viewModel.showingManualConfirmation = false
                }
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
    
    @State private var showingManualFlow = false
    
    var body: some View {
        NavigationStack {
            List {
                // Amount Header
                Section {
                    HStack {
                        Text("Amount to Pay")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("₹\(settlement.amount.formattedAmount)")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.primary)
                    }
                }
                
                // UPI Apps
                Section("Choose UPI App") {
                    ForEach(viewModel.installedApps, id: \.self) { app in
                        Button {
                            viewModel.initiateUPIPayment(using: app)
                        } label: {
                            HStack {
                                Image(systemName: app.iconName)
                                    .font(.title2)
                                    .foregroundColor(AppTheme.primary)
                                    .frame(width: 32)
                                Text(app.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "arrow.up.forward.app")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if viewModel.installedApps.isEmpty {
                        HStack {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                            Text("No UPI apps found on this device")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Manual Payment Option
                Section {
                    Button {
                        showingManualFlow = true
                    } label: {
                        HStack {
                            Image(systemName: "hand.tap")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Pay Manually")
                                    .foregroundColor(.primary)
                                    .fontWeight(.medium)
                                Text("Copy UPI ID and pay from any app")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                    }
                } header: {
                    Text("Other Options")
                } footer: {
                    Text("Note: Some UPI apps may block payments from third-party apps for security. Use 'Pay Manually' if you face issues.")
                        .font(.caption)
                }
                
                // Share Link
                Section {
                    ShareLink(item: viewModel.getGenericUPIString(settlement: settlement, group: group)) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(AppTheme.primary)
                                .frame(width: 32)
                            Text("Share Payment Link")
                                .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Pay via UPI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(isPresented: $showingManualFlow) {
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
    @State private var copiedUPI = false
    @State private var currentStep = 1
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Icon
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 20)
                    
                    Text("Complete Payment Manually")
                        .font(.settleTitle)
                        .multilineTextAlignment(.center)
                    
                    // Payment Details Card
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Pay to")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(settlement.to.name)
                                    .font(.headline)
                            }
                            Spacer()
                            Text("₹\(settlement.amount.formattedAmount)")
                                .font(.settleLargeAmount)
                                .foregroundColor(AppTheme.primary)
                        }
                        
                        Divider()
                        
                        // UPI ID with Copy
                        if let upiId = settlement.to.upiId {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("UPI ID")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(upiId)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                }
                                Spacer()
                                Button {
                                    UIPasteboard.general.string = upiId
                                    copiedUPI = true
                                    HapticManager.success()
                                    
                                    // Reset after 2 seconds
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                        copiedUPI = false
                                    }
                                } label: {
                                    HStack(spacing: 4) {
                                        Image(systemName: copiedUPI ? "checkmark" : "doc.on.doc")
                                        Text(copiedUPI ? "Copied!" : "Copy")
                                    }
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(copiedUPI ? Color.green : AppTheme.primary)
                                    .cornerRadius(8)
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Steps
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Steps to complete:")
                            .font(.headline)
                        
                        StepRow(number: 1, text: "Copy the UPI ID above", isCompleted: copiedUPI)
                        StepRow(number: 2, text: "Open your UPI app (GPay, PhonePe, etc.)", isCompleted: false)
                        StepRow(number: 3, text: "Send ₹\(settlement.amount.formattedAmount) to the UPI ID", isCompleted: false)
                        StepRow(number: 4, text: "Come back and confirm below", isCompleted: false)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    // Transaction ID Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Transaction ID (Optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter UPI transaction ID", text: $txnId)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.asciiCapable)
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button {
                            HapticManager.success()
                            viewModel.recordCashPayment(
                                settlement: settlement,
                                group: group,
                                notes: "Manual UPI Payment",
                                transactionId: txnId.isEmpty ? nil : txnId
                            )
                            onComplete()
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("I've Completed the Payment")
                            }
                            .font(.settleHeadline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppTheme.successGradient)
                            .cornerRadius(AppTheme.cardCornerRadius)
                        }
                        
                        Button {
                            dismiss()
                        } label: {
                            Text("Cancel")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

// Step Row Component
private struct StepRow: View {
    let number: Int
    let text: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.2))
                    .frame(width: 28, height: 28)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                } else {
                    Text("\(number)")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                }
            }
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted)
        }
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
