//
//  GroupDetailView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//

import SwiftUI

struct GroupDetailView: View {
    @EnvironmentObject var repository: GroupRepository
    @StateObject private var viewModel: GroupDetailViewModel
    
    @State private var currentGroup: Group
    @State private var showingAddExpense = false
    @State private var selectedExpense: Expense?
    @State private var selectedMemberForEdit: Member?
    @State private var showingAddMember = false
    
    init(group: Group) {
        _currentGroup = State(initialValue: group)
        _viewModel = StateObject(wrappedValue: GroupDetailViewModel(group: group))
    }
    
    var body: some View {
        List {
            // Quick Stats Section
            Section {
                HStack {
                    StatCard(title: "Total Spent", value: "₹\(viewModel.totalExpenses.formattedAmount)", color: .blue)
                    StatCard(title: "Expenses", value: "\(currentGroup.expenses.count)", color: .green)
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            
            // Members Section
            Section("Members") {
                ForEach(currentGroup.members) { member in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.name)
                                .font(.body)
                                .fontWeight(.medium)

                            if let upiId = member.upiId {
                                Text(upiId)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No UPI ID")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                                    .italic()
                            }
                        }

                        Spacer()

                        Button {
                            selectedMemberForEdit = member
                        } label: {
                            Image(systemName: "pencil.circle.fill")
                                .foregroundColor(.blue)
                                .font(.title3)
                        }
                    }
                }
                
                
                Button {
                    showingAddMember = true
                } label: {
                    Label("Add Member", systemImage: "person.badge.plus")
                }
            }
            
            // Expenses Section
            Section {
                if currentGroup.expenses.isEmpty {
                    Text("No expenses yet")
                        .foregroundColor(.secondary)
                        .italic()
                } else {
                    ForEach(currentGroup.expenses.sorted(by: { $0.date > $1.date })) { expense in
                        ExpenseRowView(expense: expense)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedExpense = expense
                            }
                    }
                }
            } header: {
                HStack {
                    Text("Recent Expenses")
                    Spacer()
                    Button(action: { showingAddExpense = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            
            Section {
                NavigationLink {
                    SettlementsView(group: currentGroup)
                } label: {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right.circle.fill")
                            .foregroundColor(.green)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settle Up")
                                .fontWeight(.medium)
                            
                            Text("View simplified settlements")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                
                    }
                }
            }
        }
        .navigationTitle(currentGroup.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddExpense) {
            AddExpenseView(group: currentGroup)
        }
        .sheet(item: $selectedExpense) { expense in
            ExpenseDetailView(expense: expense, group: currentGroup)
        }
        .sheet(item: $selectedMemberForEdit) { member in
            EditMemberSheet(group: currentGroup, member: member)
                .environmentObject(repository)
                .onDisappear {
                    refreshGroup()
                }
        }
        .sheet(isPresented: $showingAddMember) {
            AddMemberView(group: currentGroup) { newMember in
                addMemberToGroup(newMember)
            }
        }
        .onAppear {
            refreshGroup()
            viewModel.calculateBalances()
        }
        .onChange(of: repository.groups) {
                    // When groups change (e.g. new expense saved), refresh this group's data
                    refreshGroup()
                }
    }
    
    private func refreshGroup() {
        if let updatedGroup = repository.groups.first(where: { $0.id == currentGroup.id }) {
            currentGroup = updatedGroup
            viewModel.updateGroup(updatedGroup)
        }
    }
    
    private func addMemberToGroup(_ newMember: Member) {
        let dataManager = DataManager.shared
        let context = dataManager.context
        
        let fetchRequest = CDGroup.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == %@", currentGroup.id as CVarArg)
        
        if let cdGroup = try? context.fetch(fetchRequest).first {
            let cdMember = CDMember(context: context)
            cdMember.id = newMember.id
            cdMember.name = newMember.name
            cdMember.phoneNumber = newMember.phoneNumber
            cdMember.upiId = newMember.upiId
            cdMember.group = cdGroup
            
            dataManager.save()
            repository.fetchGroups()
            refreshGroup()
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct MemberBalanceRow: View {
    let member: Member
    let balance: Decimal
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(member.name)
                    .font(.body)
                
                if let upi = member.upiId {
                    Text(upi)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(balance.formattedAmount)")
                    .font(.headline)
                    .foregroundColor(balance >= 0 ? .green : .red)
                
                Text(balance >= 0 ? "gets back" : "owes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct ExpenseRowView: View {
    let expense: Expense
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Image(systemName: expense.category.icon)
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.title)
                    .font(.body)
                    .fontWeight(.medium)
                
                HStack(spacing: 4) {
                    Text("Paid by \(expense.paidBy.name)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text("₹\(expense.amount.formattedAmount)")
                .font(.headline)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}
