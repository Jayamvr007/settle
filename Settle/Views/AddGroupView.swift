//
//  AddGroupView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  AddGroupView.swift
//  Settle
//

import SwiftUI
import Contacts

struct AddGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var repository: GroupRepository
    
    @State private var groupName = ""
    @State private var members: [Member] = []
    @State private var showingAddMember = false
    
    var isValid: Bool {
        !groupName.trimmingCharacters(in: .whitespaces).isEmpty && members.count >= 2
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Group Details") {
                    TextField("Group name (e.g., Goa Trip)", text: $groupName)
                        .autocorrectionDisabled()
                }
                
                Section {
                    ForEach(members) { member in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(AppTheme.primary)
                            VStack(alignment: .leading) {
                                Text(member.name)
                                    .font(.body)
                                if let phone = member.phoneNumber {
                                    Text(phone)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                        }
                    }
                    
                    Button(action: { showingAddMember = true }) {
                        Label("Add Member", systemImage: "person.badge.plus")
                    }
                } header: {
                    Text("Members (\(members.count))")
                } footer: {
                    if members.count < 2 {
                        Text("Add at least 2 members to create a group")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createGroup()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
            .sheet(isPresented: $showingAddMember) {
                AddMemberView(onAdd: { member in
                    members.append(member)
                })
            }
        }
    }
    
    private func createGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespaces)
        repository.createGroup(name: trimmedName, members: members)
        dismiss()
    }
}

struct AddMemberView: View {
    @Environment(\.dismiss) private var dismiss
    let group: Group?
    let onAdd: (Member) -> Void
    
    init(group: Group? = nil, onAdd: @escaping (Member) -> Void) {
        self.group = group
        self.onAdd = onAdd
    }
    
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var upiId = ""
    @State private var upiError: String?
    @State private var showingContactPicker = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Member Details") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Phone Number (Optional)", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    
                    TextField("UPI ID (Optional)", text: $upiId)
                        .textContentType(.name)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    if let upiError {
                        Text(upiError)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                                Button {
                                    showingContactPicker = true
                                }label: {
                                    Label("Import from Contacts", systemImage: "person.crop.circle.badge.plus")
                                }
                            }
                
                Section {
                    Text("UPI ID examples: name@paytm, 9876543210@ybl, name@oksbi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Add Member")
            .sheet(isPresented: $showingContactPicker) {
                        ContactPickerView { contact in
                            if name.isEmpty {
                                name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
                            }
                            if phoneNumber.isEmpty,
                               let phone = contact.phoneNumbers.first?.value.stringValue {
                                phoneNumber = phone
                            }
                            if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                                        addMember()
                                    }
                        }
                    }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addMember()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onChange(of: upiId) {
                validateUPI()
            }
        }
    }
    
    private func addMember() {
        let member = Member(
            name: name.trimmingCharacters(in: .whitespaces),
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            upiId: upiId.isEmpty ? nil : upiId
        )
        onAdd(member)
        dismiss()
    }
    
    private func validateUPI() {
        guard !upiId.isEmpty else {
            upiError = nil
            return
        }
        
        let trimmed = upiId.trimmingCharacters(in: .whitespaces)
        // Very simple UPI format check: must contain '@' and no spaces
        if trimmed.contains(" ") || !trimmed.contains("@") {
            upiError = "UPI ID looks invalid (e.g. name@bank or 9876543210@ybl)"
        } else {
            upiError = nil
        }
    }
}

