//
//  PaymentService.swift
//  Settle
//
//  Created by Jayam Verma on 18/12/25.
//

import Foundation
import UIKit
#if canImport(Razorpay)
import Razorpay
#endif

// MARK: - Payment Service Protocol
protocol PaymentService {
    func initiatePayment(
        amount: Decimal,
        currency: String,
        description: String,
        payeeName: String,
        payeeUpiId: String,
        transactionRef: String,
        completion: @escaping (PaymentResult) -> Void
    )
}

enum PaymentResult {
    case success(transactionId: String)
    case failure(error: String)
    case cancelled
    case pending // For UPI apps where we can't be 100% sure without return callback
}

// MARK: - UPI Intent Adapter
class UPIIntentAdapter: PaymentService {
    private let app: UPIManager.UPIApp
    private let openURL: (URL) -> Void
    
    init(app: UPIManager.UPIApp, openURL: @escaping (URL) -> Void = { UIApplication.shared.open($0) }) {
        self.app = app
        self.openURL = openURL
    }
    
    func initiatePayment(
        amount: Decimal,
        currency: String,
        description: String,
        payeeName: String,
        payeeUpiId: String,
        transactionRef: String,
        completion: @escaping (PaymentResult) -> Void
    ) {
        // Use UPIManager's robust URL generation
        let success = UPIManager.shared.initiatePayment(
            app: self.app, // Use specific app intent
            upiId: payeeUpiId,
            name: payeeName,
            amount: amount,
            transactionNote: description,
            transactionRef: transactionRef
        ) { opened in
            if opened {
                // For UPI Intent, we assume pending/user input needed upon return
                completion(.pending)
            } else {
                completion(.failure(error: "Could not open \(self.app.displayName)"))
            }
        }
    }
}

// MARK: - Razorpay Adapter
class RazorpayAdapter: NSObject, PaymentService {
    private weak var presentingController: UIViewController?
    private let keyId: String
    private var completion: ((PaymentResult) -> Void)?
    
    #if canImport(Razorpay)
    private var razorpay: RazorpayCheckout!
    #endif
    
    init(presentingController: UIViewController, keyId: String = "rzp_test_1DP5mmOlF5G5ag") { // Public Test Key
        self.presentingController = presentingController
        self.keyId = keyId
        super.init()
        
        #if canImport(Razorpay)
        // strict adherence to docs: var razorpay: RazorpayCheckout!
        self.razorpay = RazorpayCheckout.initWithKey(keyId, andDelegate: self)
        #endif
    }
    
    func initiatePayment(
        amount: Decimal,
        currency: String,
        description: String,
        payeeName: String,
        payeeUpiId: String,
        transactionRef: String,
        completion: @escaping (PaymentResult) -> Void
    ) {
        #if canImport(Razorpay)
        self.completion = completion
        
        // Amount in paise
        let amountInPaise = (amount as NSDecimalNumber).multiplying(by: 100).intValue
        
        // 1. Create Order (Simulation / Placeholder)
        // NOTE: In production, this MUST be done on your backend using Key ID + Key Secret.
        // For this test integration, we will proceed without an order_id (Legacy Flow)
        // or you can implement the API call here if you have the Key Secret.
        
        // 2. Prepare Options
        let options: [String: Any] = [
            "amount": amountInPaise,
            "currency": "INR", // Razorpay usually supports INR
            "description": description,
            "image": "https://www.settle.app/logo.png", // Optional: Add a logo if you have one
            "name": "Settle",
            "prefill": [
                "email": "user@settle.app", // In real app, fetch from Auth
                "contact": "9876543210"     // In real app, fetch from Auth
            ],
            "theme": [
                "color": "#3366FF"
            ],
            // "order_id": "order_DBJOWzybf0sJbb" // Add this if you generate an order
            "notes": [
                "transaction_ref": transactionRef
            ]
        ]
        
        if let controller = presentingController {
            razorpay.open(options, displayController: controller)
        } else {
            completion(.failure(error: "Root view controller missing"))
        }
        #else
        print("⚠️ Razorpay SDK not found. Please add the pod 'razorpay-pod'.")
        completion(.failure(error: "Razorpay SDK is not installed."))
        #endif
    }
    
    // Helper to simulate Order Creation (Requires Secret)
    // func createOrder(amount: Int, completion: @escaping (String?) -> Void) { ... }
}

#if canImport(Razorpay)
extension RazorpayAdapter: RazorpayPaymentCompletionProtocol {
    func onPaymentError(_ code: Int32, description str: String) {
        let errorMessage = "Payment Failed: \(str) (Code: \(code))"
        print("❌ Razorpay Error: \(errorMessage)")
        completion?(.failure(error: errorMessage))
    }
    
    func onPaymentSuccess(_ payment_id: String) {
        print("✅ Razorpay Success: \(payment_id)")
        completion?(.success(transactionId: payment_id))
    }
    
    // Conformance for RazorpayPaymentCompletionProtocolWithData (often required by compiler)
    func onPaymentError(_ code: Int32, description str: String, andData response: [AnyHashable : Any]?) {
        onPaymentError(code, description: str)
    }
    
    func onPaymentSuccess(_ payment_id: String, andData response: [AnyHashable : Any]?) {
        onPaymentSuccess(payment_id)
    }
}
#endif
