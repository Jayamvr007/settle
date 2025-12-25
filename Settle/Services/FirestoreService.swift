//
//  FirestoreService.swift
//  Settle
//
//  Cloud sync service for storing groups, expenses, and settlements
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class FirestoreService: ObservableObject {
    static let shared = FirestoreService()
    
    private let db = Firestore.firestore()
    
    // MARK: - User Reference
    
    private var userId: String? {
        Auth.auth().currentUser?.uid
    }
    
    private func userDocument() -> DocumentReference? {
        guard let userId = userId else { return nil }
        return db.collection("users").document(userId)
    }
    
    // MARK: - Groups Collection
    
    private func groupsCollection() -> CollectionReference? {
        return userDocument()?.collection("groups")
    }
    
    // MARK: - Fetch Groups
    
    func fetchGroups() async throws -> [Group] {
        guard let collection = groupsCollection() else {
            throw FirestoreError.notAuthenticated
        }
        
        let snapshot = try await collection.order(by: "createdAt", descending: true).getDocuments()
        
        var groups: [Group] = []
        
        for document in snapshot.documents {
            if let group = try? await parseGroup(from: document) {
                groups.append(group)
            }
        }
        
        return groups
    }
    
    private func parseGroup(from document: DocumentSnapshot) async throws -> Group {
        let data = document.data() ?? [:]
        
        let id = UUID(uuidString: document.documentID) ?? UUID()
        let name = data["name"] as? String ?? ""
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        
        // Parse members
        let membersData = data["members"] as? [[String: Any]] ?? []
        let members = membersData.map { memberData -> Member in
            Member(
                id: UUID(uuidString: memberData["id"] as? String ?? "") ?? UUID(),
                name: memberData["name"] as? String ?? "",
                phoneNumber: memberData["phone"] as? String,
                upiId: memberData["upiId"] as? String
            )
        }
        
        // Fetch expenses subcollection
        let expensesSnapshot = try await groupsCollection()?
            .document(document.documentID)
            .collection("expenses")
            .order(by: "date", descending: true)
            .getDocuments()
        
        var expenses: [Expense] = []
        for expenseDoc in expensesSnapshot?.documents ?? [] {
            if let expense = parseExpense(from: expenseDoc, members: members) {
                expenses.append(expense)
            }
        }
        
        return Group(
            id: id,
            name: name,
            members: members,
            expenses: expenses,
            createdAt: createdAt
        )
    }
    
    private func parseExpense(from document: DocumentSnapshot, members: [Member]) -> Expense? {
        let data = document.data() ?? [:]
        
        guard let id = UUID(uuidString: document.documentID),
              let title = data["title"] as? String,
              let amount = data["amount"] as? Double,
              let paidById = data["paidBy"] as? String,
              let paidBy = members.first(where: { $0.id.uuidString == paidById })
        else { return nil }
        
        let date = (data["date"] as? Timestamp)?.dateValue() ?? Date()
        let categoryRaw = data["category"] as? String ?? "General"
        let category = ExpenseCategory(rawValue: categoryRaw) ?? .general
        let notes = data["notes"] as? String
        
        // Parse shares
        let sharesData = data["shares"] as? [[String: Any]] ?? []
        let shares = sharesData.compactMap { shareData -> ExpenseShare? in
            guard let memberId = shareData["memberId"] as? String,
                  let shareAmount = shareData["amount"] as? Double,
                  let member = members.first(where: { $0.id.uuidString == memberId })
            else { return nil }
            
            return ExpenseShare(
                id: UUID(),
                member: member,
                amount: Decimal(shareAmount)
            )
        }
        
        return Expense(
            id: id,
            title: title,
            amount: Decimal(amount),
            date: date,
            category: category,
            notes: notes,
            paidBy: paidBy,
            shares: shares
        )
    }
    
    // MARK: - Create Group
    
    func createGroup(name: String, members: [Member]) async throws -> Group {
        guard let collection = groupsCollection() else {
            throw FirestoreError.notAuthenticated
        }
        
        let groupId = UUID()
        let createdAt = Date()
        
        // Prepare members data
        let membersData = members.map { member -> [String: Any] in
            var data: [String: Any] = [
                "id": member.id.uuidString,
                "name": member.name
            ]
            if let phone = member.phoneNumber { data["phone"] = phone }
            if let upiId = member.upiId { data["upiId"] = upiId }
            return data
        }
        
        let groupData: [String: Any] = [
            "name": name,
            "createdAt": Timestamp(date: createdAt),
            "members": membersData
        ]
        
        try await collection.document(groupId.uuidString).setData(groupData)
        
        return Group(
            id: groupId,
            name: name,
            members: members,
            expenses: [],
            createdAt: createdAt
        )
    }
    
    // MARK: - Delete Group
    
    func deleteGroup(_ group: Group) async throws {
        guard let collection = groupsCollection() else {
            throw FirestoreError.notAuthenticated
        }
        
        // Delete all expenses first (subcollection)
        let expensesRef = collection.document(group.id.uuidString).collection("expenses")
        let expenses = try await expensesRef.getDocuments()
        for expense in expenses.documents {
            try await expense.reference.delete()
        }
        
        // Delete group document
        try await collection.document(group.id.uuidString).delete()
    }
    
    // MARK: - Add Expense
    
    func addExpense(_ expense: Expense, to group: Group) async throws {
        guard let collection = groupsCollection() else {
            throw FirestoreError.notAuthenticated
        }
        
        let sharesData = expense.shares.map { share -> [String: Any] in
            [
                "memberId": share.member.id.uuidString,
                "amount": NSDecimalNumber(decimal: share.amount).doubleValue
            ]
        }
        
        let expenseData: [String: Any] = [
            "title": expense.title,
            "amount": NSDecimalNumber(decimal: expense.amount).doubleValue,
            "date": Timestamp(date: expense.date),
            "category": expense.category.rawValue,
            "notes": expense.notes ?? "",
            "paidBy": expense.paidBy.id.uuidString,
            "shares": sharesData,
            "createdAt": Timestamp(date: Date())
        ]
        
        try await collection
            .document(group.id.uuidString)
            .collection("expenses")
            .document(expense.id.uuidString)
            .setData(expenseData)
    }
    
    // MARK: - Delete Expense
    
    func deleteExpense(_ expense: Expense, from group: Group) async throws {
        guard let collection = groupsCollection() else {
            throw FirestoreError.notAuthenticated
        }
        
        try await collection
            .document(group.id.uuidString)
            .collection("expenses")
            .document(expense.id.uuidString)
            .delete()
    }
    
    // MARK: - Update Member
    
    func updateMember(_ member: Member, in group: Group) async throws {
        guard let collection = groupsCollection() else {
            throw FirestoreError.notAuthenticated
        }
        
        // Get current group data
        let groupDoc = try await collection.document(group.id.uuidString).getDocument()
        guard var data = groupDoc.data(),
              var membersData = data["members"] as? [[String: Any]] else {
            throw FirestoreError.documentNotFound
        }
        
        // Update the member
        if let index = membersData.firstIndex(where: { ($0["id"] as? String) == member.id.uuidString }) {
            membersData[index]["name"] = member.name
            membersData[index]["phone"] = member.phoneNumber ?? NSNull()
            membersData[index]["upiId"] = member.upiId ?? NSNull()
            
            try await collection.document(group.id.uuidString).updateData([
                "members": membersData
            ])
        }
    }
    
    // MARK: - Add Member to Existing Group
    
    func addMember(_ member: Member, to group: Group) async throws {
        guard let collection = groupsCollection() else {
            throw FirestoreError.notAuthenticated
        }
        
        var memberData: [String: Any] = [
            "id": member.id.uuidString,
            "name": member.name
        ]
        if let phone = member.phoneNumber { memberData["phone"] = phone }
        if let upiId = member.upiId { memberData["upiId"] = upiId }
        
        try await collection.document(group.id.uuidString).updateData([
            "members": FieldValue.arrayUnion([memberData])
        ])
    }
    
    // MARK: - Save User Profile
    
    func saveUserProfile(name: String, upiId: String?) async throws {
        guard let doc = userDocument() else {
            throw FirestoreError.notAuthenticated
        }
        
        var profileData: [String: Any] = [
            "name": name,
            "updatedAt": Timestamp(date: Date())
        ]
        if let upiId = upiId { profileData["upiId"] = upiId }
        
        try await doc.setData(["profile": profileData], merge: true)
    }
}

// MARK: - Errors

enum FirestoreError: LocalizedError {
    case notAuthenticated
    case documentNotFound
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to sync your data"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        }
    }
}
