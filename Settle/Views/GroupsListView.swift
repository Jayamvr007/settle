//
//  GroupsListView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  GroupsListView.swift
//  Settle
//

import SwiftUI

struct GroupsListView: View {
    @EnvironmentObject var repository: GroupRepository
    @State private var showingAddGroup = false
    @State private var selectedGroup: Group?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if repository.groups.isEmpty {
                    EmptyGroupsView(showingAddGroup: $showingAddGroup)
                } else {
                    List {
                        ForEach(repository.groups) { group in
                            GroupRowView(group: group)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    HapticManager.selection()
                                    selectedGroup = group
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                        }
                        
                    }
                    .listStyle(.plain)
                    
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        HapticManager.light()
                        showingAddGroup = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.primaryGradient)
                    }
                }
            }
            .sheet(isPresented: $showingAddGroup) {
                AddGroupView()
            }
            .navigationDestination(item: $selectedGroup) { group in
                GroupDetailView(group: group)
            }
        }
    }
    
    private func deleteGroups(at offsets: IndexSet) {
        for index in offsets {
            repository.deleteGroup(repository.groups[index])
        }
    }
}

struct EmptyGroupsView: View {
    @Binding var showingAddGroup: Bool
    @State private var isAnimated = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Animated icon
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundStyle(AppTheme.primaryGradient)
                .scaleEffect(isAnimated ? 1.0 : 0.8)
                .opacity(isAnimated ? 1.0 : 0.5)
            
            Text("No Groups Yet")
                .font(.settleTitle)
            
            Text("Create a group to start splitting expenses with friends")
                .font(.settleBody)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: {
                HapticManager.light()
                showingAddGroup = true
            }) {
                Label("Create Group", systemImage: "plus.circle.fill")
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 48)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                isAnimated = true
            }
        }
    }
}

struct GroupRowView: View {
    let group: Group
    
    var totalExpenses: Decimal {
        group.expenses.reduce(0) { $0 + $1.amount }
    }
    
    /// Get initials from group name (up to 2 characters)
    private var initials: String {
        let words = group.name.split(separator: " ")
        if words.count >= 2 {
            return String(words[0].prefix(1) + words[1].prefix(1)).uppercased()
        }
        return String(group.name.prefix(2)).uppercased()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar with Gradient
            ZStack {
                Circle()
                    .fill(AppTheme.primaryGradient)
                    .frame(width: 54, height: 54)
                
                Text(initials)
                    .font(.settleHeadline)
                    .foregroundColor(.white)
            }
            .shadow(color: AppTheme.primary.opacity(0.3), radius: 6, y: 3)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(group.name)
                    .font(.settleHeadline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 8) {
                    Label("\(group.members.count)", systemImage: "person.2.fill")
                    Label("\(group.expenses.count)", systemImage: "receipt.fill")
                }
                .font(.settleCaption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(totalExpenses.formattedAmount)")
                    .font(.settleAmount)
                    .foregroundColor(AppTheme.primary)
                
                Text("total")
                    .font(.settleCaption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.cardCornerRadius)
        .shadow(color: AppTheme.cardShadow, radius: 8, y: 4)
    }
}
