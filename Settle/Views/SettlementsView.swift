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
    let groupId: UUID  // Store ID instead of full group
    @EnvironmentObject private var repository: GroupRepository
    @StateObject private var viewModel: SettlementsViewModel
    @State private var selectedSettlement: SimplifiedSettlement?
    @State private var refreshID = UUID()
    @State private var isCalculating = false
    @State private var currentGroup: Group?
    
    init(group: Group) {
        self.groupId = group.id
        _viewModel = StateObject(wrappedValue: SettlementsViewModel())
        _currentGroup = State(initialValue: group)
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
            .id(refreshID)  // Force list refresh
            
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
            if let group = currentGroup {
                SettlePaymentView(settlement: settlement, group: group) {
                    // Refresh callback after payment
                    refreshData()
                }
            }
        }
        .onAppear {
            refreshData()
        }
        // Observe GroupRepository changes - triggers when expenses are added/deleted
        .onChange(of: repository.groups) {
            refreshData()
        }
    }
    
    private func refreshData() {
        isCalculating = true
        
        // Get fresh group from repository (same source as GroupDetailView)
        if let freshGroup = repository.groups.first(where: { $0.id == groupId }) {
            currentGroup = freshGroup
            viewModel.calculateSettlements(for: freshGroup)
        }
        
        refreshID = UUID()
        isCalculating = false
    }
    
    private func fetchLatestGroup() -> Group? {
        // Get group from Firestore via repository
        return repository.groups.first(where: { $0.id == groupId })
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
                Text(UserHelper.displayName(for: settlement.from))
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(UserHelper.isCurrentUser(settlement.from) ? AppTheme.primary : .primary)
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
                Text(UserHelper.displayName(for: settlement.to))
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .foregroundColor(UserHelper.isCurrentUser(settlement.to) ? AppTheme.primary : .primary)
                
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
        // Calculate fresh settlements from all expenses
        let allSettlements = simplifier.calculateOptimalSettlements(for: group)
        
        // For now, show all calculated settlements
        // The "completed" status should be tracked separately
        // and the settlement amounts should reflect the current balance
        settlements = allSettlements
    }
    
    // Note: Completed settlements are now tracked as payment expenses in Firestore
    // The settlement calculation uses current expense data, not stored settlement records
    
    func markAsSettled(_ settlement: SimplifiedSettlement) {
        if let index = settlements.firstIndex(where: { $0.id == settlement.id }) {
            settlements.remove(at: index)
        }
    }
}

