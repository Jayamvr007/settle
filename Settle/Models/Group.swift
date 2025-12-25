//
//  Group.swift
//  Settle
//
//  Created by Jayam Verma on 13/12/25.
//

import Foundation

struct Group: Identifiable, Hashable {
    let id: UUID
    var name: String
    var members: [Member]
    var expenses: [Expense]
    var createdAt: Date
    
    init(id: UUID = UUID(), name: String, members: [Member] = [], expenses: [Expense] = [], createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.members = members
        self.expenses = expenses
        self.createdAt = createdAt
    }
}

struct Member: Identifiable, Hashable, Codable {
    let id: UUID
    var name: String
    var phoneNumber: String?
    var upiId: String?  // ✅ Add this if missing
    
    init(id: UUID = UUID(), name: String, phoneNumber: String? = nil, upiId: String? = nil) {
        self.id = id
        self.name = name
        self.phoneNumber = phoneNumber
        self.upiId = upiId
    }
}


struct Expense: Identifiable, Hashable {
    let id: UUID
    var title: String
    var amount: Decimal
    var date: Date
    var category: ExpenseCategory
    var notes: String?
    var paidBy: Member
    var shares: [ExpenseShare]
    
    init(
        id: UUID = UUID(),
        title: String,
        amount: Decimal,
        date: Date = Date(),
        category: ExpenseCategory = .general,
        notes: String? = nil,
        paidBy: Member,
        shares: [ExpenseShare]
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.category = category
        self.notes = notes
        self.paidBy = paidBy
        self.shares = shares
    }
}

struct ExpenseShare: Identifiable, Hashable {
    let id: UUID
    var member: Member
    var amount: Decimal
    
    init(id: UUID = UUID(), member: Member, amount: Decimal) {
        self.id = id
        self.member = member
        self.amount = amount
    }
}

enum ExpenseCategory: String, CaseIterable {
    case food = "Food"
    case groceries = "Groceries"
    case transport = "Transport"
    case travel = "Travel"
    case entertainment = "Entertainment"
    case subscriptions = "Subscriptions"
    case utilities = "Utilities"
    case shopping = "Shopping"
    case healthcare = "Healthcare"
    case education = "Education"
    case general = "General"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .groceries: return "basket.fill"
        case .transport: return "car.fill"
        case .travel: return "airplane"
        case .entertainment: return "ticket.fill"
        case .subscriptions: return "repeat.circle.fill"
        case .utilities: return "bolt.fill"
        case .shopping: return "cart.fill"
        case .healthcare: return "cross.case.fill"
        case .education: return "book.fill"
        case .general: return "square.grid.2x2"
        }
    }
}

struct Settlement: Identifiable {
    let id: UUID
    var from: Member
    var to: Member
    var amount: Decimal
    var date: Date
    var status: SettlementStatus
    var upiTransactionId: String?
    
    init(
        id: UUID = UUID(),
        from: Member,
        to: Member,
        amount: Decimal,
        date: Date = Date(),
        status: SettlementStatus = .pending
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.amount = amount
        self.date = date
        self.status = status
    }
}

enum SettlementStatus: String {
    case pending = "Pending"
    case completed = "Completed"
    case failed = "Failed"
}
