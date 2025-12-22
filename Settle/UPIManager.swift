//
//  UPIManager.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  UPIManager.swift
//  Settle
//
//  Handles UPI deep linking and payment verification
//

import Foundation
import UIKit

class UPIManager: ObservableObject {
    static let shared = UPIManager()
    
    @Published var lastTransactionStatus: UPITransactionStatus?
    
    // UPI Apps and their URL schemes
    enum UPIApp: String, CaseIterable {
        case googlePay = "gpay"
        case phonePe = "phonepe"
        case paytm = "paytmmp"
        case bhim = "bhim"
        case amazonPay = "amazonpay"
        
        var displayName: String {
            switch self {
            case .googlePay: return "Google Pay"
            case .phonePe: return "PhonePe"
            case .paytm: return "Paytm"
            case .bhim: return "BHIM UPI"
            case .amazonPay: return "Amazon Pay"
            }
        }
        
        var iconName: String {
            switch self {
            case .googlePay: return "g.circle.fill"
            case .phonePe: return "p.circle.fill"
            case .paytm: return "dollarsign.circle.fill"
            case .bhim: return "b.circle.fill"
            case .amazonPay: return "a.circle.fill"
            }
        }
        
        var color: String {
            switch self {
            case .googlePay: return "blue"
            case .phonePe: return "purple"
            case .paytm: return "cyan"
            case .bhim: return "orange"
            case .amazonPay: return "yellow"
            }
        }
    }
    
    // Check if UPI app is installed
    func isAppInstalled(_ app: UPIApp) -> Bool {
        let urlString = "\(app.rawValue)://upi"
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
    
    // Get all installed UPI apps
    func getInstalledUPIApps() -> [UPIApp] {
        return UPIApp.allCases.filter { isAppInstalled($0) }
    }
    
    // Generate UPI payment URL
    // Generate UPI payment URL
    func generateUPIURL(
        upiId: String,
        name: String,
        amount: Decimal,
        transactionNote: String? = nil,
        transactionRef: String? = nil
    ) -> String {
        // Clean the UPI ID
        let cleanUpiId = upiId.trimmingCharacters(in: .whitespaces)
        
        // Format amount to 2 decimal places
        let amountString = String(format: "%.2f", NSDecimalNumber(decimal: amount).doubleValue)
        
        // Generate transaction reference (alphanumeric only, max 35 chars)
        let txnRef = (transactionRef ?? UUID().uuidString)
            .replacingOccurrences(of: "-", with: "")
            .prefix(25)
        
        // Clean transaction note (remove special characters)
        let cleanNote = transactionNote?
            .replacingOccurrences(of: "[^a-zA-Z0-9 ]", with: "", options: .regularExpression)
            .prefix(50) ?? "Payment"
        
        // Build UPI URL manually (more reliable than URLComponents for UPI)
        var upiString = "upi://pay?"
        upiString += "pa=\(cleanUpiId)"
        upiString += "&pn=\(name.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? name)"
        upiString += "&am=\(amountString)"
        upiString += "&cu=INR"
        upiString += "&tn=\(cleanNote.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Payment")"
        
        return upiString
    }

    
    // Generate app-specific UPI URL
    private func generateAppSpecificURL(
        app: UPIApp,
        upiId: String,
        name: String,
        amount: Decimal,
        transactionNote: String? = nil,
        transactionRef: String? = nil
    ) -> String {
        var components = URLComponents()
        components.scheme = app.rawValue
        
        // Different apps use different URL structures
        switch app {
        case .phonePe:
            // PhonePe: phonepe://pay?pa=<upi>&pn=<name>&am=<amount>
            components.host = "pay"
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "pa", value: upiId),
                URLQueryItem(name: "pn", value: name),
                URLQueryItem(name: "am", value: String(describing: amount)),
                URLQueryItem(name: "cu", value: "INR"),
            ]
            if let note = transactionNote {
                queryItems.append(URLQueryItem(name: "tn", value: note))
            }
            let txnId = transactionRef ?? UUID().uuidString
            queryItems.append(URLQueryItem(name: "tr", value: txnId))
            components.queryItems = queryItems
            
        case .paytm:
            // Paytm: paytmmp://pay?pa=<upi>&pn=<name>&am=<amount>
            components.host = "pay"
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "pa", value: upiId),
                URLQueryItem(name: "pn", value: name),
                URLQueryItem(name: "am", value: String(describing: amount)),
                URLQueryItem(name: "cu", value: "INR"),
            ]
            if let note = transactionNote {
                queryItems.append(URLQueryItem(name: "tn", value: note))
            }
            let txnId = transactionRef ?? UUID().uuidString
            queryItems.append(URLQueryItem(name: "tr", value: txnId))
            components.queryItems = queryItems
            
        case .amazonPay:
            // Amazon Pay: amazonpay://pay?pa=<upi>&pn=<name>&am=<amount>
            components.host = "pay"
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "pa", value: upiId),
                URLQueryItem(name: "pn", value: name),
                URLQueryItem(name: "am", value: String(describing: amount)),
                URLQueryItem(name: "cu", value: "INR"),
            ]
            if let note = transactionNote {
                queryItems.append(URLQueryItem(name: "tn", value: note))
            }
            let txnId = transactionRef ?? UUID().uuidString
            queryItems.append(URLQueryItem(name: "tr", value: txnId))
            components.queryItems = queryItems
            
        case .googlePay:
            // Google Pay: gpay://pay?pa=<upi>&pn=<name>&am=<amount>
            components.host = "pay"
            var queryItems: [URLQueryItem] = [
                URLQueryItem(name: "pa", value: upiId),
                URLQueryItem(name: "pn", value: name),
                URLQueryItem(name: "am", value: String(describing: amount)),
                URLQueryItem(name: "cu", value: "INR"),
            ]
            if let note = transactionNote {
                queryItems.append(URLQueryItem(name: "tn", value: note))
            }
            let txnId = transactionRef ?? UUID().uuidString
            queryItems.append(URLQueryItem(name: "tr", value: txnId))
            components.queryItems = queryItems
            
        case .bhim:
            // BHIM uses standard UPI format
            return generateUPIURL(
                upiId: upiId,
                name: name,
                amount: amount,
                transactionNote: transactionNote,
                transactionRef: transactionRef
            )
        }
        
        return components.url?.absoluteString ?? ""
    }
    
    // Initiate UPI payment
    // Initiate UPI payment
    func initiatePayment(
        app: UPIApp,
        upiId: String,
        name: String,
        amount: Decimal,
        transactionNote: String? = nil,
        transactionRef: String? = nil,
        completion: @escaping (Bool) -> Void
    ) {
        // Generate robust URL using URLComponents
        let finalURLString = generateAppSpecificURL(
            app: app,
            upiId: upiId,
            name: name,
            amount: amount,
            transactionNote: transactionNote,
            transactionRef: transactionRef
        )
        
        guard let url = URL(string: finalURLString) else {
            print("❌ Failed to create URL: \(finalURLString)")
            completion(false)
            return
        }
        
        print("🔗 Opening UPI URL: \(url.absoluteString)")
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url) { success in
                print(success ? "✅ UPI app opened successfully" : "❌ Failed to open UPI app")
                completion(success)
            }
        } else {
            print("❌ Cannot open URL - app not installed or URL scheme incorrect")
            
            // Fallback: try generic UPI URL
            if app != .bhim, let genericURL = URL(string: generateUPIURL(upiId: upiId, name: name, amount: amount, transactionNote: transactionNote)) {
                 print("🔄 Attempting generic fallback...")
                 UIApplication.shared.open(genericURL) { success in
                     completion(success)
                 }
            } else {
                completion(false)
            }
        }
    }

    
    // Handle UPI callback response
    func handleCallback(url: URL) -> UPITransactionStatus {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return .failed(reason: "Invalid callback URL")
        }
        
        var params: [String: String] = [:]
        for item in queryItems {
            if let value = item.value {
                params[item.name] = value
            }
        }
        
        // Parse status
        guard let statusString = params["Status"] else {
            return .failed(reason: "No status in callback")
        }
        
        let status = statusString.lowercased()
        
        if status == "success" {
            let txnId = params["txnId"]
            let txnRef = params["txnRef"]
            let approvalRef = params["ApprovalRefNo"]
            
            return .success(
                transactionId: txnId ?? "",
                transactionRef: txnRef ?? "",
                approvalRef: approvalRef
            )
        } else if status == "submitted" {
            return .pending
        } else {
            let reason = params["responseCode"] ?? "Unknown error"
            return .failed(reason: reason)
        }
    }
}

// Transaction status enum
enum UPITransactionStatus: Equatable {
    case success(transactionId: String, transactionRef: String, approvalRef: String?)
    case pending
    case failed(reason: String)
    
    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }
    
    var message: String {
        switch self {
        case .success(let txnId, _, _):
            return "Payment successful! Transaction ID: \(txnId)"
        case .pending:
            return "Payment is pending verification"
        case .failed(let reason):
            return "Payment failed: \(reason)"
        }
    }
}
