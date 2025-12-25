//
//  EditMemberView.swift
//  Settle
//
//  Created by Jayam Verma on 14/12/25.
//


//
//  EditMemberView.swift
//  Settle
//

import SwiftUI

struct EditMemberView: View {
    @Environment(\.dismiss) private var dismiss
    let group: Group
    @Binding var member: Member
    
    @State private var name: String
    @State private var phoneNumber: String
    @State private var upiId: String
    
    init(group: Group, member: Binding<Member>) {
        self.group = group
        self._member = member
        _name = State(initialValue: member.wrappedValue.name)
        _phoneNumber = State(initialValue: member.wrappedValue.phoneNumber ?? "")
        _upiId = State(initialValue: member.wrappedValue.upiId ?? "")
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
        
        // Update local binding
        member = updatedMember
        
        // Save to Firestore via repository
        GroupRepository.shared.updateMember(updatedMember, in: group)
        
        dismiss()
    }
}
