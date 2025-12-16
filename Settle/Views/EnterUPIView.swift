//
//  EnterUPIView.swift
//  Settle
//
//  Created by Jayam Verma on 16/12/25.
//


import SwiftUI

struct EnterUPIView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var upiId: String = ""
    var onSave: (String) -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Enter your UPI ID")) {
                    TextField("yourname@bank", text: $upiId)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .keyboardType(.emailAddress)
                }
            }
            .navigationTitle("Your UPI ID")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if !upiId.trimmingCharacters(in: .whitespaces).isEmpty {
                            onSave(upiId)
                            dismiss()
                        }
                    }
                    .disabled(upiId.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}