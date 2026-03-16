import SwiftUI
import SwiftData

struct TransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @State private var searchText = ""
    
    var filteredTransactions: [Transaction] {
        if searchText.isEmpty {
            return transactions
        } else {
            return transactions.filter { ($0.storeName ?? "").localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        ZStack {
            Theme.primaryBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                headerView
                
                searchBar
                
                ScrollView {
                    VStack(spacing: 16) {
                        if filteredTransactions.isEmpty {
                            Text("No transactions found")
                                .foregroundColor(.white.opacity(0.4))
                                .padding(.top, 40)
                        } else {
                            ForEach(filteredTransactions) { transaction in
                                TransactionRow(transaction: transaction)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Transactions")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Spacer()
            Button(action: {}) {
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding(12)
                    .glassCard(opacity: 0.1)
            }
        }
        .padding()
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.white.opacity(0.4))
            TextField("Search transactions...", text: $searchText)
                .foregroundColor(.white)
        }
        .padding()
        .glassCard(opacity: 0.1)
        .padding(.horizontal)
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: transaction.type == TransactionType.income ? "tray.and.arrow.down.fill" : "cart.fill")
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .glassCard(opacity: 0.1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.storeName ?? "Unknown")
                    .font(.body.bold())
                    .foregroundColor(.white)
                Text("Category") // Placeholder until category join is ready
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text((transaction.type == TransactionType.income ? "+" : "-") + transaction.amountFormatted)
                    .font(.body.bold())
                    .foregroundColor(transaction.type == TransactionType.income ? Theme.successColor : .white)
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding()
        .glassCard(opacity: 0.1)
    }
}

struct TransactionsListView_Previews: PreviewProvider {
    static var previews: some View {
        TransactionsListView()
    }
}
