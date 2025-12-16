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
           let dataManager = DataManager.shared
           let context = dataManager.context
           
           let fetchRequest = CDMember.fetchRequest()
           fetchRequest.predicate = NSPredicate(format: "id == %@", member.id as CVarArg)
           
           if let cdMember = try? context.fetch(fetchRequest).first {
               cdMember.name = name.trimmingCharacters(in: .whitespaces)
               cdMember.phoneNumber = phoneNumber.isEmpty ? nil : phoneNumber
               cdMember.upiId = upiId.isEmpty ? nil : upiId
               dataManager.save()
           }
           
           // Refresh the repository to update the groups
           GroupRepository().fetchGroups()
           
           dismiss()
       }
}
