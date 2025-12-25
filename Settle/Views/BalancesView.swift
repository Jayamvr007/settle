//
//  BalancesView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  BalancesView.swift
//  Settle
//

import SwiftUI

struct BalancesView: View {
    @EnvironmentObject var repository: GroupRepository
    
    var allBalances: [(member: Member, group: Group, balance: Decimal)] {
        var balances: [(member: Member, group: Group, balance: Decimal)] = []
        
        for group in repository.groups {
            let viewModel = GroupDetailViewModel(group: group)
            for member in group.members {
                let balance = viewModel.balanceFor(member: member)
                // Filter out zero and near-zero balances (avoids -0 display)
                if abs(balance) > Decimal(string: "0.01")! {
                    balances.append((member: member, group: group, balance: balance))
                }
            }
        }
        
        // Fix: Explicit type annotation for sorted closure
        return balances.sorted { (first: (member: Member, group: Group, balance: Decimal), second: (member: Member, group: Group, balance: Decimal)) in
            abs(first.balance) > abs(second.balance)
        }
    }
    
    var youOwe: [(member: Member, group: Group, balance: Decimal)] {
        allBalances.filter { item in item.balance < 0 }
    }
    
    var youGetBack: [(member: Member, group: Group, balance: Decimal)] {
        allBalances.filter { item in item.balance > 0 }
    }
    
    var body: some View {
        NavigationStack {
            List {
                if allBalances.isEmpty {
                    ContentUnavailableView(
                        "No Balances",
                        systemImage: "indianrupeesign.circle",
                        description: Text("Add expenses to see balances")
                    )
                } else {
                    if !youOwe.isEmpty {
                        Section("You Owe") {
                            ForEach(Array(youOwe.enumerated()), id: \.offset) { index, item in
                                BalanceRow(
                                    member: item.member,
                                    group: item.group,
                                    balance: item.balance
                                )
                            }
                        }
                    }
                    
                    if !youGetBack.isEmpty {
                        Section("You Get Back") {
                            ForEach(Array(youGetBack.enumerated()), id: \.offset) { index, item in
                                BalanceRow(
                                    member: item.member,
                                    group: item.group,
                                    balance: item.balance
                                )
                            }
                        }
                    }
                }
            }
            .navigationTitle("Balances")
        }
    }
}

struct BalanceRow: View {
    let member: Member
    let group: Group
    let balance: Decimal
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(UserHelper.displayName(for: member))
                    .font(.headline)
                    .foregroundColor(UserHelper.isCurrentUser(member) ? AppTheme.primary : .primary)
                
                Text(group.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(abs(balance).formattedAmount)")
                    .font(.headline)
                    .foregroundColor(balance >= 0 ? AppTheme.getsBack : AppTheme.owes)
                
                Text(balance >= 0 ? "gets back" : "owes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    BalancesView()
        .environmentObject(GroupRepository.shared)
}
