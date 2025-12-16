//
//  DebtSimplifier.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  DebtSimplifier.swift
//  Settle
//
//  Graph-based debt simplification using greedy algorithm
//

import Foundation

class DebtSimplifier {
    
    /// Simplifies debts to minimize number of transactions
    /// Example: If A owes B ₹100, B owes C ₹100 → A pays C directly (1 transaction instead of 2)
    func simplifyDebts(balances: [UUID: Decimal]) -> [Settlement] {
        // Separate creditors (get money) and debtors (owe money)
        var creditors: [(id: UUID, amount: Decimal)] = []
        var debtors: [(id: UUID, amount: Decimal)] = []
        
        for (id, balance) in balances {
            if balance > 0 {
                creditors.append((id, balance))
            } else if balance < 0 {
                debtors.append((id, abs(balance)))
            }
        }
        
        // Sort by amount (largest first) for greedy approach
        creditors.sort { $0.amount > $1.amount }
        debtors.sort { $0.amount > $1.amount }
        
        var settlements: [Settlement] = []
        var creditorIndex = 0
        var debtorIndex = 0
        
        // Greedy algorithm: Match largest creditor with largest debtor
        while creditorIndex < creditors.count && debtorIndex < debtors.count {
            let creditor = creditors[creditorIndex]
            let debtor = debtors[debtorIndex]
            
            let settlementAmount = min(creditor.amount, debtor.amount)
            
            // Create settlement (but we need Member objects, not just UUIDs)
            // We'll fix this in the ViewModel
            
            // Update amounts
            creditors[creditorIndex].amount -= settlementAmount
            debtors[debtorIndex].amount -= settlementAmount
            
            // Store the settlement info
            settlements.append(Settlement(
                from: Member(id: debtor.id, name: ""), // Placeholder
                to: Member(id: creditor.id, name: ""), // Placeholder
                amount: settlementAmount
            ))
            
            // Move to next if current is settled
            if creditors[creditorIndex].amount == 0 {
                creditorIndex += 1
            }
            if debtors[debtorIndex].amount == 0 {
                debtorIndex += 1
            }
        }
        
        return settlements
    }
    
    /// Calculate optimal settlements for a group
    func calculateOptimalSettlements(for group: Group) -> [SimplifiedSettlement] {
        // Calculate balances
        var balances: [UUID: Decimal] = [:]
        
        for member in group.members {
            balances[member.id] = 0
        }
        
        for expense in group.expenses {
            // Person who paid gets positive balance
            balances[expense.paidBy.id, default: 0] += expense.amount
            
            // People who share get negative balance
            for share in expense.shares {
                balances[share.member.id, default: 0] -= share.amount
            }
        }
        
        // Separate creditors and debtors
        var creditors: [(member: Member, amount: Decimal)] = []
        var debtors: [(member: Member, amount: Decimal)] = []
        
        for member in group.members {
            let balance = balances[member.id, default: 0]
            if balance > 0.01 { // Use small threshold for floating point
                creditors.append((member, balance))
            } else if balance < -0.01 {
                debtors.append((member, abs(balance)))
            }
        }
        
        // Sort largest first
        creditors.sort { $0.amount > $1.amount }
        debtors.sort { $0.amount > $1.amount }
        
        var settlements: [SimplifiedSettlement] = []
        var creditorsCopy = creditors
        var debtorsCopy = debtors
        
        var creditorIndex = 0
        var debtorIndex = 0
        
        // Greedy matching
        while creditorIndex < creditorsCopy.count && debtorIndex < debtorsCopy.count {
            let creditor = creditorsCopy[creditorIndex]
            let debtor = debtorsCopy[debtorIndex]
            
            let settlementAmount = min(creditor.amount, debtor.amount)
            
            settlements.append(SimplifiedSettlement(
                id: UUID(),
                from: debtor.member,
                to: creditor.member,
                amount: settlementAmount,
                status: .pending
            ))
            
            // Update amounts
            creditorsCopy[creditorIndex].amount -= settlementAmount
            debtorsCopy[debtorIndex].amount -= settlementAmount
            
            // Move to next if settled
            if creditorsCopy[creditorIndex].amount < 0.01 {
                creditorIndex += 1
            }
            if debtorsCopy[debtorIndex].amount < 0.01 {
                debtorIndex += 1
            }
        }
        
        return settlements
    }
}

// Simplified settlement model (doesn't need Core Data yet)
struct SimplifiedSettlement: Identifiable, Hashable {
    let id: UUID
    let from: Member
    let to: Member
    let amount: Decimal
    var status: SettlementStatus
    
    init(id: UUID = UUID(), from: Member, to: Member, amount: Decimal, status: SettlementStatus = .pending) {
        self.id = id
        self.from = from
        self.to = to
        self.amount = amount
        self.status = status
    }
}
