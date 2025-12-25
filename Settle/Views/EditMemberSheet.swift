//
//  EditMemberSheet.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  EditMemberSheet.swift
//  Settle
//

import SwiftUI

struct EditMemberSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var repository: GroupRepository
    let group: Group
    let member: Member
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var upiId: String
    
    init(group: Group, member: Member) {
        self.group = group
        self.member = member
        _name = State(initialValue: member.name)
        _phoneNumber = State(initialValue: member.phoneNumber ?? "")
        _upiId = State(initialValue: member.upiId ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Member Details") {
                    TextField("Name", text: $name)
                        .textContentType(.name)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    
                    TextField("UPI ID", text: $upiId)
                        .textContentType(.name)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                
                Section {
                    Text("UPI ID examples: name@paytm, 9876543210@ybl, name@oksbi")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Member")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveMember()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
    
    private func saveMember() {
        // Create updated member with new values
        let updatedMember = Member(
            id: member.id,
            name: name.trimmingCharacters(in: .whitespaces),
            phoneNumber: phoneNumber.isEmpty ? nil : phoneNumber,
            upiId: upiId.isEmpty ? nil : upiId
        )
        
        // Save to Firestore via repository
        repository.updateMember(updatedMember, in: group)
        
        dismiss()
    }
}
