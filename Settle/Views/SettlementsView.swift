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
        _viewModel = StateObject(wrappedValue: SettlementsViewModel(group: group))
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
                                .foregroundColor(.blue)
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
    }
    
    private func recalculateSettlements() {
        isCalculating = true
        // Calculation is quick and runs on main thread
        viewModel.calculateSettlements()
        refreshID = UUID()
        isCalculating = false
    }
}

struct SettlementRowView: View {
    let settlement: SimplifiedSettlement
    
    var body: some View {
        HStack(spacing: 12) {
            // From avatar
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "person.fill")
                    .foregroundColor(.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(settlement.from.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                Text("pays")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Image(systemName: "arrow.right")
                .foregroundColor(.secondary)
            
            // To avatar
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "person.fill")
                    .foregroundColor(.green)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(settlement.to.name)
                    .font(.body)
                    .fontWeight(.medium)
                
                if let upi = settlement.to.upiId {
                    Text(upi)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(settlement.amount.formattedAmount)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(settlement.status.rawValue)
                    .font(.caption)
                    .foregroundColor(settlement.status == .completed ? .green : .orange)
            }
        }
        .padding(.vertical, 4)
    }
}

class SettlementsViewModel: ObservableObject {
    @Published var settlements: [SimplifiedSettlement] = []
    
    private let group: Group
    private let simplifier = DebtSimplifier()
    
    var totalToSettle: Decimal {
        settlements.reduce(0) { $0 + $1.amount }
    }
    
    init(group: Group) {
        self.group = group
        calculateSettlements()
    }
    
    func calculateSettlements() {  // ✅ Make it public
            // Filter out completed settlements
            let completedSettlements = fetchCompletedSettlements()
            let allSettlements = simplifier.calculateOptimalSettlements(for: group)
            
            // Remove settlements that are already completed
            settlements = allSettlements.filter { settlement in
                !completedSettlements.contains(where: { completed in
                    completed.from.id == settlement.from.id &&
                    completed.to.id == settlement.to.id
                })
            }
        }
    
    private func fetchCompletedSettlements() -> [SimplifiedSettlement] {
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
