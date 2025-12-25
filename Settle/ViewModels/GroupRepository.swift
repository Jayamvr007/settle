//
//  GroupRepository.swift
//  Settle
//
//  Created by Jayam Verma on 13/12/25.
//


//
//  GroupRepository.swift
//  Settle
//

import Foundation
import FirebaseAuth

class GroupRepository: ObservableObject {
    static let shared = GroupRepository()
    
    private let firestoreService = FirestoreService.shared
    
    @Published var groups: [Group] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    init() {
        // Listen for auth state changes to refresh data
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            if user != nil {
                self?.fetchGroups()
            } else {
                self?.groups = []
            }
        }
    }
    
    // MARK: - Fetch from Firestore
    
    func fetchGroups() {
        guard Auth.auth().currentUser != nil else {
            groups = []
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Task { @MainActor in
            do {
                groups = try await firestoreService.fetchGroups()
                isLoading = false
            } catch {
                print("❌ Failed to fetch groups: \(error)")
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // MARK: - Create Group in Firestore
    
    func createGroup(name: String, members: [Member]) {
        isLoading = true
        
        Task { @MainActor in
            do {
                print("📝 Creating group: \(name) with \(members.count) members")
                let newGroup = try await firestoreService.createGroup(name: name, members: members)
                print("✅ Group created successfully: \(newGroup.id)")
                
                // Explicitly trigger UI update
                self.objectWillChange.send()
                groups.insert(newGroup, at: 0)
                isLoading = false
            } catch {
                print("❌ Failed to create group: \(error)")
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
    
    // MARK: - Delete Group from Firestore
    
    func deleteGroup(_ group: Group) {
        Task { @MainActor in
            do {
                try await firestoreService.deleteGroup(group)
                groups.removeAll { $0.id == group.id }
            } catch {
                print("❌ Failed to delete group: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Add Expense to Firestore
    
    func addExpense(_ expense: Expense, to group: Group) {
        Task { @MainActor in
            do {
                try await firestoreService.addExpense(expense, to: group)
                fetchGroups() // Refresh to get updated data
            } catch {
                print("❌ Failed to add expense: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Add Member to Existing Group
    
    func addMember(_ member: Member, to group: Group) {
        Task { @MainActor in
            do {
                try await firestoreService.addMember(member, to: group)
                fetchGroups()
            } catch {
                print("❌ Failed to add member: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
    
    // MARK: - Update Member
    
    func updateMember(_ member: Member, in group: Group) {
        Task { @MainActor in
            do {
                try await firestoreService.updateMember(member, in: group)
                fetchGroups()
            } catch {
                print("❌ Failed to update member: \(error)")
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Core Data to Swift Model Conversion

extension CDGroup {
    func toSwiftModel() -> Group {
        let members = (self.members?.allObjects as? [CDMember])?.map { $0.toSwiftModel() } ?? []
        let expenses = (self.expenses?.allObjects as? [CDExpense])?.map { $0.toSwiftModel() } ?? []
        
        return Group(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            members: members,
            expenses: expenses,
            createdAt: self.createdAt ?? Date()
        )
    }
}

extension CDMember {
    func toSwiftModel() -> Member {
        return Member(
            id: self.id ?? UUID(),
            name: self.name ?? "",
            phoneNumber: self.phoneNumber,
            upiId: self.upiId
        )
    }
}

extension CDExpense {
    func toSwiftModel() -> Expense {
        let paidBy = self.paidBy?.toSwiftModel() ?? Member(name: "Unknown")
        let shares = (self.shares?.allObjects as? [CDExpenseShare])?.map { $0.toSwiftModel() } ?? []
        
        return Expense(
            id: self.id ?? UUID(),
            title: self.title ?? "",
            amount: self.amount as Decimal? ?? 0,
            date: self.date ?? Date(),
            category: ExpenseCategory(rawValue: self.category ?? "") ?? .general,
            notes: self.notes,
            paidBy: paidBy,
            shares: shares
        )
    }
}

extension CDExpenseShare {
    func toSwiftModel() -> ExpenseShare {
        let member = self.member?.toSwiftModel() ?? Member(name: "Unknown")
        return ExpenseShare(
            id: self.id ?? UUID(),
            member: member,
            amount: self.amount as Decimal? ?? 0
        )
    }
}
