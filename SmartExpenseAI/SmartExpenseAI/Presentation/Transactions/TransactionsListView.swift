import SwiftUI
import SwiftData

struct TransactionsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var categories: [Category]
    
    @State private var searchText = ""
    @State private var showingAddTransaction = false
    
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
                                TransactionRow(transaction: transaction, categories: categories)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 100)
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            AddTransactionView()
        }
    }
    
    private var headerView: some View {
        HStack {
            Text("Transactions")
                .font(.largeTitle.bold())
                .foregroundColor(.white)
            Spacer()
            Button(action: { showingAddTransaction = true }) {
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
    let categories: [Category]
    
    private var categoryInfo: (name: String, icon: String) {
        if let cat = categories.first(where: { $0.id == transaction.categoryId }) {
            return (cat.name, cat.iconName)
        }
        return ("Unknown", transaction.type == .income ? "tray.and.arrow.down.fill" : "cart.fill")
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: categoryInfo.icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .glassCard(opacity: 0.1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.storeName ?? categoryInfo.name)
                    .font(.body.bold())
                    .foregroundColor(.white)
                Text(categoryInfo.name)
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
