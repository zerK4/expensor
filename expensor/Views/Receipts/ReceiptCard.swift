//
//  ReceiptCard.swift
//  expensor
//
//  Created by Sebastian Pavel on 28.05.2025.
//
import SwiftUI

struct ReceiptCard: View {
    let receipt: ReceiptEntry
    let onTap: () -> Void
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: receipt.date)
    }
    
    private var formattedTotal: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "RON"
        return formatter.string(from: NSNumber(value: receipt.total)) ?? String(format: "%.2f RON", receipt.total)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerSection
            categoryAndPaymentSection
            itemsCountSection
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray5), lineWidth: 0.5)
        )
        .onTapGesture {
            onTap()
        }
    }
    
    private var headerSection: some View {
        HStack {
            companyInfo
            Spacer()
            totalAndDateInfo
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }
    
    private var companyInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(receipt.companies.name)
                .font(.headline)
                .fontWeight(.semibold)
                .lineLimit(1)
            
            if let cif = receipt.companies.cif {
                Text("CIF: \(cif)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var totalAndDateInfo: some View {
        VStack(alignment: .trailing, spacing: 4) {
            Text(formattedTotal)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var categoryAndPaymentSection: some View {
        HStack {
            categoryBadge
            Spacer()
            paymentMethodIndicators
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    @ViewBuilder
    private var categoryBadge: some View {
        if let category = receipt.categories {
            HStack(spacing: 6) {
                Text(category.icon)
                    .font(.system(size: 16))
                Text(category.name.capitalized)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var paymentMethodIndicators: some View {
        HStack(spacing: 8) {
            cardPaymentBadge
            cashPaymentBadge
        }
    }
    
    @ViewBuilder
    private var cardPaymentBadge: some View {
        if let paidCard = receipt.paidCard, paidCard > 0 {
            HStack(spacing: 4) {
                Image(systemName: "creditcard.fill")
                    .font(.caption)
                Text("Card")
                    .font(.caption)
            }
            .foregroundColor(.blue)
        }
    }
    
    @ViewBuilder
    private var cashPaymentBadge: some View {
        if let paidCash = receipt.paidCash, paidCash > 0 {
            HStack(spacing: 4) {
                Image(systemName: "banknote.fill")
                    .font(.caption)
                Text("Cash")
                    .font(.caption)
            }
            .foregroundColor(.green)
        }
    }
    
    @ViewBuilder
    private var itemsCountSection: some View {
        if !receipt.items.isEmpty {
            Divider()
            
            HStack {
                Image(systemName: "list.bullet")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("\(receipt.items.count) item\(receipt.items.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}
