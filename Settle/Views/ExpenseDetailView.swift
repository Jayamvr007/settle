//
//  ExpenseDetailView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  ExpenseDetailView.swift
//  Settle
//

import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    let group: Group
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: expense.category.icon)
                            .font(.title)
                            .foregroundColor(AppTheme.primary)
                            .frame(width: 50)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(expense.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text(expense.category.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Amount")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("₹\(expense.amount.formattedAmount)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                    
                    HStack {
                        Text("Date")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(expense.date.formatted(date: .long, time: .omitted))
                    }
                    
                    HStack {
                        Text("Paid by")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(UserHelper.displayName(for: expense.paidBy))
                            .fontWeight(.medium)
                            .foregroundColor(UserHelper.isCurrentUser(expense.paidBy) ? AppTheme.primary : .primary)
                    }
                }
                
                Section("Split Details") {
                    ForEach(expense.shares) { share in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(UserHelper.isCurrentUser(share.member) ? AppTheme.primary : AppTheme.primary)
                            
                            Text(UserHelper.displayName(for: share.member))
                                .foregroundColor(UserHelper.isCurrentUser(share.member) ? AppTheme.primary : .primary)
                            
                            Spacer()
                            Text("₹\(share.amount.formattedAmount)")
                                .fontWeight(.medium)
                        }
                    }
                }
                
                if let notes = expense.notes, !notes.isEmpty {
                    Section("Notes") {
                        Text(notes)
                    }
                }
            }
            .navigationTitle("Expense Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
