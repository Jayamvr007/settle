//
//  SettlementsView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  SettlementsView.swift
//  Settle
//

import SwiftUI

struct SettlementsView: View {
    let group: Group
    @StateObject private var viewModel: SettlementsViewModel
    @State private var selectedSettlement: SimplifiedSettlement?
    @State private var refreshID = UUID()
    @State private var isCalculating = false
    
    init(group: Group) {
        self.group = group
        _viewModel = StateObject(wrappedValue: SettlementsViewModel())
    }
    
    var body: some View {
        ZStack {
            List {
                if viewModel.settlements.isEmpty && !isCalculating {
                    ContentUnavailableView(
                        "All Settled!",
                        systemImage: "checkmark.circle.fill",
                        description: Text("No pending settlements in this group")
                    )
                } else {
                    Section {
                        Text("These are the minimum transactions needed to settle all debts")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .listRowBackground(Color.clear)
                    }
                    
                    Section("Pending Settlements") {
                        ForEach(viewModel.settlements) { settlement in
                            SettlementRowView(settlement: settlement)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedSettlement = settlement
                                }
                        }
                    }
                    
                    Section {
                        HStack {
                            Text("Total to settle")
                                .fontWeight(.semibold)
                            Spacer()
                            Text("₹\(viewModel.totalToSettle.formattedAmount)")

                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.primary)
                        }
                    }
                }
            }
            
            if isCalculating {
                VStack {
                    ProgressView("Calculating settlements…")
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
        .navigationTitle("Settlements")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSettlement) { settlement in
            SettlePaymentView(settlement: settlement, group: group) {
                // Refresh callback
                recalculateSettlements()
            }
        }
        .onAppear {
            recalculateSettlements()
        }
        .onChange(of: group) { newGroup in
             // React to updates from AddExpenseView
             recalculateSettlements()
        }
    }
    
    private func recalculateSettlements() {
        isCalculating = true
        // Calculation is quick and runs on main thread
        viewModel.calculateSettlements(for: group)
        refreshID = UUID()
        isCalculating = false
    }
}

struct SettlementRowView: View {
    let settlement: SimplifiedSettlement
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Left side: From person
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(AppTheme.dangerGradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                }
                Text(settlement.from.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 70)
            
            // Arrow with amount in center
            VStack(spacing: 4) {
                Image(systemName: "arrow.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(AppTheme.primary)
                
                Text("₹\(settlement.amount.formattedAmount)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(AppTheme.primary)
                
                Text(settlement.status.rawValue)
                    .font(.caption2)
                    .foregroundColor(settlement.status == .completed ? AppTheme.getsBack : .orange)
            }
            .frame(maxWidth: .infinity)
            
            // Right side: To person
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(AppTheme.successGradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .foregroundColor(.white)
                }
                Text(settlement.to.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                
                if let upi = settlement.to.upiId {
                    Text(upi)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(width: 70)
        }
        .padding(.vertical, 8)
    }
}

class SettlementsViewModel: ObservableObject {
    @Published var settlements: [SimplifiedSettlement] = []
    
    private let simplifier = DebtSimplifier()
    
    var totalToSettle: Decimal {
        settlements.reduce(0) { $0 + $1.amount }
    }
    
    func calculateSettlements(for group: Group) {
        // Filter out completed settlements
        let completedSettlements = fetchCompletedSettlements(for: group)
        let allSettlements = simplifier.calculateOptimalSettlements(for: group)
        
        // Remove settlements that are already completed
        settlements = allSettlements.filter { settlement in
            !completedSettlements.contains(where: { completed in
                completed.from.id == settlement.from.id &&
                completed.to.id == settlement.to.id
            })
        }
    }
    
    private func fetchCompletedSettlements(for group: Group) -> [SimplifiedSettlement] {
        let dataManager = DataManager.shared
        let context = dataManager.context
        
        let fetchRequest = CDSettlement.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "group.id == %@ AND status == %@",
                                            group.id as CVarArg,
                                            SettlementStatus.completed.rawValue)
        
        guard let cdSettlements = try? context.fetch(fetchRequest) else {
            return []
        }
        
        return cdSettlements.compactMap { cdSettlement in
            guard let fromMember = cdSettlement.from,
                  let toMember = cdSettlement.to,
                  let amount = cdSettlement.amount as? Decimal,
                  let id = cdSettlement.id else {
                return nil
            }
            
            let from = Member(id: fromMember.id ?? UUID(),
                            name: fromMember.name ?? "")
            let to = Member(id: toMember.id ?? UUID(),
                          name: toMember.name ?? "")
            
            return SimplifiedSettlement(id: id,
                                      from: from,
                                      to: to,
                                      amount: amount,
                                      status: .completed)
        }
    }
    
    func markAsSettled(_ settlement: SimplifiedSettlement) {
        if let index = settlements.firstIndex(where: { $0.id == settlement.id }) {
            settlements.remove(at: index)
        }
    }
}
