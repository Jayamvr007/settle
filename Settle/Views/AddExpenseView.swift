//
//  AddExpenseView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  AddExpenseView.swift
//  Settle
//

import SwiftUI

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var repository: GroupRepository
    
    let group: Group
    
    @State private var title = ""
    @State private var amount = ""
    @State private var selectedCategory: ExpenseCategory = .general
    @State private var selectedPayer: Member?
    @State private var splitType: SplitType = .equally
    @State private var selectedMembers: Set<UUID> = []
    @State private var customSplits: [UUID: String] = [:]
    @State private var amountError: String?
    
    var isValid: Bool {
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty,
              let amountValue = Decimal(string: amount),
              amountValue > 0,
              let _ = selectedPayer,
              !selectedMembers.isEmpty else {
            return false
        }
        
        if splitType == .custom {
            let total = customSplits.values.compactMap { Decimal(string: $0) }.reduce(0, +)
            return total == amountValue
        }
        
        return true
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Expense Details") {
                    TextField("Description (e.g., Dinner)", text: $title)
                    
                    HStack {
                        Text("₹")
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    if let amountError {
                        Text(amountError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { category in
                            Label(category.rawValue, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                
                Section("Paid By") {
                    ForEach(group.members) { member in
                        HStack {
                            Text(member.name)
                            Spacer()
                            if selectedPayer?.id == member.id {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPayer = member
                        }
                    }
                }
                
             
                
                
                
                
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addExpense()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // Select all members by default
                selectedMembers = Set(group.members.map { $0.id })
                // Select first member as payer
                selectedPayer = group.members.first
                validateAmount()
            }
            .onChange(of: amount) { _ in
                validateAmount()
            }
        }
    }
    
    private var memberSplitSection: some View {
        Section {
            Picker("Split Type", selection: $splitType) {
                Text("Equally").tag(SplitType.equally)
                Text("By Percentage").tag(SplitType.percentage)
                Text("Custom Amount").tag(SplitType.custom)
            }
            .pickerStyle(.segmented)
            
            ForEach(group.members) { member in
                HStack {
                    Toggle(member.name, isOn: Binding(
                        get: { selectedMembers.contains(member.id) },
                        set: { isSelected in
                            if isSelected {
                                selectedMembers.insert(member.id)
                            } else {
                                selectedMembers.remove(member.id)
                                customSplits.removeValue(forKey: member.id)
                            }
                        }
                    ))
                    
                    if splitType == .custom && selectedMembers.contains(member.id) {
                        TextField("₹", text: Binding(
                            get: { customSplits[member.id] ?? "" },
                            set: { customSplits[member.id] = $0 }
                        ))
                        .keyboardType(.decimalPad)
                        .frame(width: 80)
                        .multilineTextAlignment(.trailing)
                    }
                }
            }
        } header: {
            Text("Split Between (\(selectedMembers.count) selected)")
        } footer: {
            if splitType == .custom {
                let total = customSplits.values.compactMap { Decimal(string: $0) }.reduce(0, +)
                let amountValue = Decimal(string: amount) ?? 0
                if total != amountValue {
                    Text("Total must equal ₹\((Decimal(string: amount) ?? 0).formattedAmount). Current: ₹\(total.formattedAmount)")
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func addExpense() {
        guard let payer = selectedPayer,
              let amountValue = Decimal(string: amount) else {
            return
        }
        
        // Calculate shares based on split type
        var shares: [ExpenseShare] = []
        let selectedMembersList = group.members.filter { selectedMembers.contains($0.id) }
        
        switch splitType {
        case .equally:
            let shareAmount = amountValue / Decimal(selectedMembersList.count)
            shares = selectedMembersList.map { member in
                ExpenseShare(member: member, amount: shareAmount)
            }
            
        case .percentage:
            // For simplicity, equal percentage for now
            // In production, you'd have percentage inputs
            let shareAmount = amountValue / Decimal(selectedMembersList.count)
            shares = selectedMembersList.map { member in
                ExpenseShare(member: member, amount: shareAmount)
            }
            
        case .custom:
            shares = selectedMembersList.compactMap { member in
                guard let amountStr = customSplits[member.id],
                      let shareAmount = Decimal(string: amountStr) else {
                    return nil
                }
                return ExpenseShare(member: member, amount: shareAmount)
            }
        }
        
        let expense = Expense(
            title: title,
            amount: amountValue,
            category: selectedCategory,
            paidBy: payer,
            shares: shares
        )
        
        // Save to Core Data
        saveExpense(expense, to: group)
        
        dismiss()
    }
    
    private func saveExpense(_ expense: Expense, to group: Group) {
        let dataManager = DataManager.shared
        let context = dataManager.context
        
        // Fetch the CDGroup
        let fetchRequest = CDGroup.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", group.id as CVarArg)
        
        guard let cdGroup = try? context.fetch(fetchRequest).first else { return }
        
        // Create CDExpense
        let cdExpense = CDExpense(context: context)
        cdExpense.id = expense.id
        cdExpense.title = expense.title
        cdExpense.amount = expense.amount as NSDecimalNumber
        cdExpense.date = expense.date
        cdExpense.category = expense.category.rawValue
        cdExpense.notes = expense.notes
        cdExpense.createdAt = Date()
        cdExpense.group = cdGroup
        
        // Find and set payer
        let payerFetch = CDMember.fetchRequest()
        payerFetch.predicate = NSPredicate(format: "id == %@ AND group == %@", expense.paidBy.id as CVarArg, cdGroup)
        if let cdPayer = try? context.fetch(payerFetch).first {
            cdExpense.paidBy = cdPayer
        }
        
        // Create shares
        for share in expense.shares {
            let memberFetch = CDMember.fetchRequest()
            memberFetch.predicate = NSPredicate(format: "id == %@ AND group == %@", share.member.id as CVarArg, cdGroup)
            
            if let cdMember = try? context.fetch(memberFetch).first {
                let cdShare = CDExpenseShare(context: context)
                cdShare.id = share.id
                cdShare.amount = share.amount as NSDecimalNumber
                cdShare.expense = cdExpense
                cdShare.member = cdMember
            }
        }
        
        dataManager.save()
        repository.fetchGroups() // Refresh
    }
    
    private func validateAmount() {
        guard !amount.isEmpty else {
            amountError = nil
            return
        }
        
        guard let value = Decimal(string: amount) else {
            amountError = "Enter a valid number for amount"
            return
        }
        
        if value <= 0 {
            amountError = "Amount must be greater than ₹0"
        } else {
            amountError = nil
        }
    }
}

enum SplitType {
    case equally
    case percentage
    case custom
}
