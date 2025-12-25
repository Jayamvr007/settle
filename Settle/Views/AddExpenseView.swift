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
import Combine

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
    
    // ML Prediction State
    @State private var suggestedCategory: ExpenseCategory?
    @State private var showSuggestion = false
    @State private var debounceTask: Task<Void, Never>?
    
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
                        .onChange(of: title) { newValue in
                            debouncePrediction(for: newValue)
                        }
                    
                    // ML Suggestion Chip
                    if showSuggestion, let suggested = suggestedCategory, suggested != selectedCategory {
                        Button {
                            withAnimation(.spring(response: 0.3)) {
                                selectedCategory = suggested
                                showSuggestion = false
                            }
                            HapticManager.selection()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "wand.and.stars")
                                    .font(.caption)
                                Text("Suggested: \(suggested.rawValue)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                Image(systemName: suggested.icon)
                                    .font(.caption)
                            }
                            .foregroundColor(AppTheme.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.primary.opacity(0.1))
                            .cornerRadius(20)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    
                    HStack {
                        Text("₹")
                            .foregroundColor(.secondary)
                        TextField("Amount", text: $amount)
                            .keyboardType(.decimalPad)
                    }
                    
                    if let amountError {
                        Text(amountError)
                            .font(.caption)
                            .foregroundColor(AppTheme.owes)
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
                                    .foregroundColor(AppTheme.primary)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedPayer = member
                        }
                    }
                }
                
                // Split options section
                memberSplitSection
                
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
                    
                    // Percentage input
                    if splitType == .percentage && selectedMembers.contains(member.id) {
                        HStack(spacing: 4) {
                            TextField("0", text: Binding(
                                get: { customSplits[member.id] ?? "" },
                                set: { customSplits[member.id] = $0 }
                            ))
                            .keyboardType(.decimalPad)
                            .frame(width: 50)
                            .multilineTextAlignment(.trailing)
                            Text("%")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Custom amount input
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
            if splitType == .percentage {
                let totalPercent = customSplits.values.compactMap { Double($0) }.reduce(0, +)
                if abs(totalPercent - 100) > 0.01 {
                    Text("Percentages must equal 100%. Current: \(Int(totalPercent))%")
                        .foregroundColor(.red)
                }
            } else if splitType == .custom {
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
            // Calculate share based on entered percentage
            shares = selectedMembersList.compactMap { member in
                guard let percentStr = customSplits[member.id],
                      let percent = Decimal(string: percentStr) else {
                    return nil
                }
                let shareAmount = (percent / 100) * amountValue
                return ExpenseShare(member: member, amount: shareAmount)
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
        // Save to Firestore via repository
        repository.addExpense(expense, to: group)
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
    
    /// ML-powered category prediction with confidence threshold
    private func predictCategory(from description: String) {
        // Only predict after 3+ characters
        guard description.count >= 3 else {
            withAnimation {
                showSuggestion = false
            }
            return
        }
        
        // Get prediction with confidence
        let predictions = ExpenseCategoryPredictor.shared.predictWithConfidence(description: description)
        
        // Only suggest if confidence is > 60%
        guard let topPrediction = predictions.first,
              topPrediction.confidence > 0.6 else {
            withAnimation {
                showSuggestion = false
            }
            return
        }
        
        let predicted = topPrediction.category
        
        // Only show suggestion if it's different from current selection
        if predicted != selectedCategory && predicted != .general {
            withAnimation(.spring(response: 0.3)) {
                suggestedCategory = predicted
                showSuggestion = true
            }
            HapticManager.light()
        } else if predicted == selectedCategory {
            withAnimation {
                showSuggestion = false
            }
        }
    }
    
    /// Debounce prediction - waits 0.5s after user stops typing
    private func debouncePrediction(for description: String) {
        // Cancel any existing pending prediction
        debounceTask?.cancel()
        
        // Hide suggestion immediately while typing
        if description.count < 3 {
            withAnimation {
                showSuggestion = false
            }
            return
        }
        
        // Schedule new prediction after 0.5s delay
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Check if task was cancelled
            guard !Task.isCancelled else { return }
            
            // Perform prediction on main thread
            await MainActor.run {
                predictCategory(from: description)
            }
        }
    }
}

enum SplitType {
    case equally
    case percentage
    case custom
}
