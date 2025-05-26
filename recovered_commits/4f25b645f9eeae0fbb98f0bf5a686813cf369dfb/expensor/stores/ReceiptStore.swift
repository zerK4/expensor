//
//  ReceiptStore.swift
//  expensor
//
//  Created to manage storage and access of receipts
//

import Foundation
import Combine

@MainActor
class ReceiptStore: ObservableObject {
    @Published private(set) var receipts: [ReceiptEntry] = []
    private let saveKey = "SavedReceipts"
    
    init() {
        loadReceipts()
    }
    
    func addReceipt(_ receipt: ReceiptEntry) {
        receipts.append(receipt)
        saveReceipts()
    }
    
    func updateReceipt(_ receipt: ReceiptEntry) {
        if let index = receipts.firstIndex(where: { $0.identifier == receipt.identifier }) {
            receipts[index] = receipt
            saveReceipts()
        }
    }
    
    func deleteReceipt(_ receipt: ReceiptEntry) {
        receipts.removeAll { $0.identifier == receipt.identifier }
        saveReceipts()
    }
    
    private func loadReceipts() {
        if let data = UserDefaults.standard.data(forKey: saveKey) {
            do {
                let decoder = JSONDecoder()
                receipts = try decoder.decode([ReceiptEntry].self, from: data)
            } catch {
                print("Error loading receipts: \(error)")
                receipts = []
            }
        }
    }
    
    private func saveReceipts() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(receipts)
            UserDefaults.standard.set(data, forKey: saveKey)
        } catch {
            print("Error saving receipts: \(error)")
        }
    }
}