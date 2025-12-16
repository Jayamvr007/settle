//
//  DataManager.swift
//  Settle
//
//  Created by Jayam Verma on 13/12/25.
//

import Foundation
import CoreData

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    let container: NSPersistentContainer
    
    private init() {
        container = NSPersistentContainer(name: "Settle")
        
        // Enable CloudKit sync (we'll set this up in Week 5)
        // guard let description = container.persistentStoreDescriptions.first else {
        //     fatalError("Failed to retrieve persistent store description")
        // }
        // description.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(
        //     containerIdentifier: "iCloud.com.yourname.Settle"
        // )
        
        container.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Failed to load Core Data: \(error.localizedDescription)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    var context: NSManagedObjectContext {
        container.viewContext
    }
    
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
}

extension Decimal {
    var formattedAmount: String {
        let number = NSDecimalNumber(decimal: self)
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(from: number) ?? "\(self)"
    }
}