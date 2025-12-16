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
                                    selectedGroup = group
                                }
                        }
                        
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddGroup = true }) {
                        Image(systemName: "plus")
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
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("No Groups Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create a group to start splitting expenses with friends")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { showingAddGroup = true }) {
                Label("Create Group", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.blue)
                    .cornerRadius(12)
            }
        }
    }
}

struct GroupRowView: View {
    let group: Group
    
    var totalExpenses: Decimal {
        group.expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Group Icon
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "person.3.fill")
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                
                HStack(spacing: 4) {
                    Text("\(group.members.count) members")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text("\(group.expenses.count) expenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("₹\(totalExpenses.formattedAmount)")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("total")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
    }
}
