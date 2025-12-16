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
import CoreData

class GroupRepository: ObservableObject {
    private let dataManager = DataManager.shared
    
    @Published var groups: [Group] = []
    
    init() {
        fetchGroups()
    }
    
    // MARK: - Fetch
    
    func fetchGroups() {
        let request: NSFetchRequest<CDGroup> = CDGroup.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \CDGroup.createdAt, ascending: false)]
        
        do {
            let cdGroups = try dataManager.context.fetch(request)
            groups = cdGroups.map { $0.toSwiftModel() }
        } catch {
            print("Failed to fetch groups: \(error)")
        }
    }
    
    // MARK: - Create
    
    func createGroup(name: String, members: [Member]) {
        let cdGroup = CDGroup(context: dataManager.context)
        cdGroup.id = UUID()
        cdGroup.name = name
        cdGroup.createdAt = Date()
        cdGroup.updatedAt = Date()
        
        // Add members
        for member in members {
            let cdMember = CDMember(context: dataManager.context)
            cdMember.id = member.id
            cdMember.name = member.name
            cdMember.phoneNumber = member.phoneNumber
            cdMember.upiId = member.upiId
            cdMember.group = cdGroup
        }
        
        dataManager.save()
        fetchGroups()
    }
    
    // MARK: - Update
    
    func updateGroup(_ group: Group) {
        let request: NSFetchRequest<CDGroup> = CDGroup.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", group.id as CVarArg)
        
        do {
            let results = try dataManager.context.fetch(request)
            if let cdGroup = results.first {
                cdGroup.name = group.name
                cdGroup.updatedAt = Date()
                dataManager.save()
                fetchGroups()
            }
        } catch {
            print("Failed to update group: \(error)")
        }
    }
    
    // MARK: - Delete
    
    func deleteGroup(_ group: Group) {
        let request: NSFetchRequest<CDGroup> = CDGroup.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", group.id as CVarArg)
        
        do {
            let results = try dataManager.context.fetch(request)
            if let cdGroup = results.first {
                dataManager.context.delete(cdGroup)
                dataManager.save()
                fetchGroups()
            }
        } catch {
            print("Failed to delete group: \(error)")
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
