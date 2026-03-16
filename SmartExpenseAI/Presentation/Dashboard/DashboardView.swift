import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var budgets: [Budget]
    
    var totalBalance: Double {
        var balance: Double = 0
        for transaction in transactions {
            if transaction.type == TransactionType.income {
                balance += transaction.amount
            } else {
                balance -= transaction.amount
            }
        }
        return balance
    }
    
    var monthlyIncome: Double {
        transactions.filter({ $0.type == TransactionType.income }).map({ $0.amount }).reduce(0, +)
    }
    
    var monthlyExpenses: Double {
        transactions.filter({ $0.type == TransactionType.expense }).map({ $0.amount }).reduce(0, +)
    }

    var body: some View {
        NavigationView {
            ZStack {
                Theme.primaryBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 25) {
                        // Header
                        headerView
                        
                        // Main Balance card
                        balanceCard
                        
                        // Summary section
                        incomeExpenseSummary
                        
                        // Recent Transactions Preview
                        recentTransactionsSection
                        
                        // Budget Progress
                        budgetOverviewSection
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Welcome back,")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
                Text("Swift Architect")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            Spacer()
            Image(systemName: "bell.badge")
                .font(.title3)
                .foregroundColor(.white)
                .padding(12)
                .glassCard(opacity: 0.1)
        }
    }
    
    private var balanceCard: some View {
        VStack(spacing: 15) {
            Text("Total Balance")
                .font(.headline)
                .foregroundColor(.white.opacity(0.7))
            
            Text(Theme.formatCurrency(totalBalance))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            HStack(spacing: 8) {
                Image(systemName: "arrow.up.right")
                Text("+2.5% from last month")
            }
            .font(.caption.bold())
            .foregroundColor(Theme.accentColor)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Theme.accentColor.opacity(0.1))
            .cornerRadius(20)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
        .glassCard(opacity: 0.15)
    }
    
    private var incomeExpenseSummary: some View {
        HStack(spacing: 20) {
            summaryItem(title: "Income", amount: Theme.formatCurrency(monthlyIncome), icon: "arrow.down.left", color: Theme.successColor)
            summaryItem(title: "Expenses", amount: Theme.formatCurrency(monthlyExpenses), icon: "arrow.up.right", color: Theme.dangerColor)
        }
    }
    
    private func summaryItem(title: String, amount: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundColor(color)
                    .padding(8)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.6))
            }
            Text(amount)
                .font(.title3.bold())
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassCard(opacity: 0.1)
    }
    
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Button("See All") { }
                    .font(.subheadline)
                    .foregroundColor(Theme.accentColor)
            }
            
            VStack(spacing: 12) {
                if transactions.isEmpty {
                    Text("No recent transactions")
                        .foregroundColor(.white.opacity(0.4))
                        .padding()
                } else {
                    ForEach(transactions.prefix(5)) { transaction in
                        DashboardTransactionItem(
                            title: transaction.storeName ?? "Unknown",
                            category: "Category", // Need to join with category eventually
                            amount: (transaction.type == TransactionType.income ? "+" : "-") + Theme.formatCurrency(transaction.amount),
                            date: transaction.date.formatted(date: .abbreviated, time: .omitted),
                            icon: "cart.fill"
                        )
                    }
                }
            }
        }
    }
    
    private var budgetOverviewSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Budget Overview")
                .font(.headline)
                .foregroundColor(.white)
            
            VStack(spacing: 16) {
                if budgets.isEmpty {
                    Text("No budgets set")
                        .foregroundColor(.white.opacity(0.4))
                        .padding()
                } else {
                    ForEach(budgets.prefix(3)) { budget in
                        budgetProgressItem(title: "Budget", spent: budget.currentSpent, total: budget.limitAmount, color: .blue)
                    }
                }
            }
            .padding()
            .glassCard(opacity: 0.1)
        }
    }
    
    private func budgetProgressItem(title: String, spent: Double, total: Double, color: Color) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("\(Theme.formatCurrency(spent))/\(Theme.formatCurrency(total))")
                    .font(.caption.bold())
                    .foregroundColor(.white)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)
                    
                    RoundedRectangle(cornerRadius: 10)
                        .fill(color)
                        .frame(width: geo.size.width * CGFloat(spent/total), height: 8)
                }
            }
            .frame(height: 8)
        }
    }
}

struct DashboardTransactionItem: View {
    let title: String
    let category: String
    let amount: String
    let date: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 48, height: 48)
                .glassCard(opacity: 0.1)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.body.bold())
                    .foregroundColor(.white)
                Text(category)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(amount)
                    .font(.body.bold())
                    .foregroundColor(amount.contains("+") ? Theme.successColor : .white)
                Text(date)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding()
        .glassCard(opacity: 0.1)
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
