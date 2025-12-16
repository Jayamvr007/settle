//
//  GroupDetailViewModel.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  GroupDetailViewModel.swift
//  Settle
//

import Foundation

@MainActor
class GroupDetailViewModel: ObservableObject {
    func removeMembers(atOffsets offsets: IndexSet) {
        let dataManager = DataManager.shared
        let context = dataManager.context
        
        let fetchRequest = CDGroup.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", group.id as CVarArg)
        
        guard let cdGroup = try? context.fetch(fetchRequest).first else {
            print("❌ Failed to find group")
            return
        }
        
        let membersArray = Array(cdGroup.members as? Set<CDMember> ?? [])
        let sortedMembers = membersArray.sorted { ($0.name ?? "") < ($1.name ?? "") }
        
        for index in offsets {
            if index < sortedMembers.count {
                let memberToDelete = sortedMembers[index]
                context.delete(memberToDelete)
            }
        }
        
        dataManager.save()
        
        // Update local group model
        var updatedMembers = group.members
        updatedMembers.remove(atOffsets: offsets)
        group.members = updatedMembers
        
        // Recalculate balances
        calculateBalances()
    }

    var group: Group
    @Published var balances: [UUID: Decimal] = [:]
    
    var totalExpenses: Decimal {
        group.expenses.reduce(0) { $0 + $1.amount }
    }
    
    init(group: Group) {
        self.group = group
        calculateBalances()
    }
    
    func updateGroup(_ newGroup: Group) {
        self.group = newGroup
        calculateBalances()
    }
    
    func balanceFor(member: Member) -> Decimal {
        balances[member.id] ?? 0
    }
    
    func calculateBalances() {
        var memberBalances: [UUID: Decimal] = [:]
        
        // Initialize all members with 0
        for member in group.members {
            memberBalances[member.id] = 0
        }
        
        // Calculate balances from expenses
        for expense in group.expenses {
            // Person who paid gets positive balance
            memberBalances[expense.paidBy.id, default: 0] += expense.amount
            
            // People who owe get negative balance
            for share in expense.shares {
                memberBalances[share.member.id, default: 0] -= share.amount
            }
        }
        
        balances = memberBalances
    }
}
