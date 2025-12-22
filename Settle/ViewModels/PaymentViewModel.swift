//
//  PaymentViewModel.swift
//  Settle
//
//  Created by Jayam Verma on 18/12/25.
//

import Foundation
import UIKit
import Combine

@MainActor
class PaymentViewModel: ObservableObject {
    @Published var installedApps: [UPIManager.UPIApp] = []
    @Published var isProcessing = false
    @Published var errorMessage: String?
    @Published var showingManualConfirmation = false
    
    // Feature Flags & Config
    var isRazorpayAvailable: Bool {
        #if canImport(Razorpay)
        return true
        #else
        return false
        #endif
    }
    
    // Dependencies
    private let upiManager = UPIManager.shared
    private let dataManager = DataManager.shared
    private var paymentService: PaymentService?
    
    // Transaction State
    private var currentSettlement: SimplifiedSettlement?
    private var currentGroup: Group?
    private var currentTransactionRef: String?
    
    init() {
        loadInstalledApps()
    }
    
    func loadInstalledApps() {
        installedApps = upiManager.getInstalledUPIApps()
    }
    
    func preparePayment(settlement: SimplifiedSettlement, group: Group) {
        self.currentSettlement = settlement
        self.currentGroup = group
        self.currentTransactionRef = UUID().uuidString
    }
    
    // MARK: - Payment Actions
    
    func initiateUPIPayment(using app: UPIManager.UPIApp) {
        startPayment(service: UPIIntentAdapter(app: app))
    }
    
    func initiateRazorpayPayment(presentingController: UIViewController) {
        startPayment(service: RazorpayAdapter(presentingController: presentingController))
    }
    
    private func startPayment(service: PaymentService) {
        guard let settlement = currentSettlement,
              let group = currentGroup,
              let upiId = settlement.to.upiId,
              let txnRef = currentTransactionRef else {
            errorMessage = "Payment details missing"
            return
        }
        
        isProcessing = true
        self.paymentService = service
        
        service.initiatePayment(
            amount: settlement.amount,
            currency: "INR",
            description: "Settlement - \(group.name)",
            payeeName: settlement.to.name,
            payeeUpiId: upiId,
            transactionRef: txnRef
        ) { [weak self] result in
            guard let self = self else { return }
            self.isProcessing = false
            
            switch result {
            case .success(let transactionId):
                self.recordCashPayment(settlement: settlement, group: group, notes: "Paid via Gateway/UPI", transactionId: transactionId)
                // We rely on the view to observe this completion or we can publish a success event
                // Ideally, we'd have a publisher for "PaymentCompleted"
                
            case .pending:
                // For direct UPI, we land here. Show manual confirmation.
                // Delay slightly to allow app switch
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.showingManualConfirmation = true
                }
                
            case .failure(let error):
                self.errorMessage = error
                
            case .cancelled:
                break
            }
        }
    }
    
    // MARK: - Record Logic
    
    func recordCashPayment(settlement: SimplifiedSettlement, group: Group, notes: String? = nil, transactionId: String? = nil) {
        let context = dataManager.context
        
        let cdSettlement = CDSettlement(context: context)
        cdSettlement.id = settlement.id
        cdSettlement.amount = settlement.amount as NSDecimalNumber
        cdSettlement.date = Date()
        cdSettlement.status = SettlementStatus.completed.rawValue
        
        if let tid = transactionId, !tid.isEmpty {
            cdSettlement.upiTransactionId = tid
        }
        
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
    }
    
    func getGenericUPIString(settlement: SimplifiedSettlement, group: Group) -> String {
        guard let upiId = settlement.to.upiId else { return "" }
        return upiManager.generateUPIURL(
            upiId: upiId,
            name: settlement.to.name,
            amount: settlement.amount,
            transactionNote: "Settlement - \(group.name)"
        )
    }
}
